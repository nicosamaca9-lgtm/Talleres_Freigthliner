from datetime import datetime, timedelta
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.BookingEntity import Booking, ConfirmationState
from app.models.ServiceOrderEntity import ServiceOrder, ServiceOrderState
from app.schemas.BookingSchema import BookingCreate, BookingUpdate

class BookingService:

    @staticmethod
    def create_booking(db: Session, booking_data: BookingCreate):
        """Crea un nuevo agendamiento en la base de datos aplicando reglas de negocio"""
        # Validar max 10 agendamientos por día
        daily_bookings_count = db.query(Booking).filter(Booking.fecha_cita == booking_data.fecha_cita).count()
        if daily_bookings_count >= 10:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No se pueden agendar más citas para esta fecha. Límite diario alcanzado."
            )


        # Validar que un mismo vehículo no tenga más de una cita activa el mismo día
        existing_vehicle_booking = db.query(Booking).filter(
            Booking.id_vehiculo == booking_data.id_vehiculo,
            Booking.fecha_cita == booking_data.fecha_cita,
            Booking.estado_confirmacion.in_([ConfirmationState.PENDIENTE, ConfirmationState.CONFIRMADO])
        ).first()

        if existing_vehicle_booking:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Este vehículo ya tiene una cita agendada para ese día."
            )

        db_booking = Booking(**booking_data.model_dump())
        db.add(db_booking)
        db.commit()
        db.refresh(db_booking)
        return db_booking

    @staticmethod
    def get_all_bookings(db: Session, skip: int = 0, limit: int = 100):
        """Lista todos los agendamientos registrados"""
        from sqlalchemy.orm import joinedload
        return db.query(Booking).options(joinedload(Booking.user), joinedload(Booking.vehicle)).offset(skip).limit(limit).all()

    @staticmethod
    def get_bookings_by_vehicle(db: Session, id_vehiculo: int):
        """Busca agendamientos asociados a un vehículo específico"""
        return db.query(Booking).filter(Booking.id_vehiculo == id_vehiculo).all()

    @staticmethod
    def get_bookings_by_user(db: Session, id_usuario: int):
        """Busca todos los agendamientos activos de un usuario y cancela los vencidos"""
        from sqlalchemy.orm import joinedload
        bookings = db.query(Booking).options(joinedload(Booking.vehicle), joinedload(Booking.user)).filter(Booking.id_usuario == id_usuario).order_by(Booking.fecha_cita.desc(), Booking.hora_cita.desc()).all()
        now = datetime.now()
        
        filtered_bookings = []
        from datetime import time
        deleted_any = False
        
        for b in bookings:
            if b.estado_confirmacion in [ConfirmationState.PENDIENTE, ConfirmationState.CONFIRMADO]:
                is_past_date = b.fecha_cita < now.date()
                is_past_time_today = b.fecha_cita == now.date() and now.hour >= 18
                if is_past_date or is_past_time_today:
                    b.estado_confirmacion = ConfirmationState.CANCELADO_POR_SISTEMA
                    b.motivo_rechazo = "Cancelada automáticamente por el sistema al no registrar ingreso al taller."
                    db.commit()
            
            # Borrado real de la base de datos a las 20:00 o días posteriores
            if b.estado_confirmacion in [ConfirmationState.CANCELADO, ConfirmationState.CANCELADO_POR_SISTEMA, ConfirmationState.RECHAZADO]:
                if b.fecha_cita < now.date() or (b.fecha_cita == now.date() and now.time() >= time(20, 0)):
                    db.delete(b)
                    deleted_any = True
                    continue
            
            filtered_bookings.append(b)

        if deleted_any:
            db.commit()
            
        return filtered_bookings

    @staticmethod
    def update_booking(db: Session, id_agendamiento: int, booking_data: BookingUpdate):
        """Actualiza la fecha/hora de una cita validando la regla de las 3 horas"""
        db_booking = db.query(Booking).filter(Booking.id_agendamiento == id_agendamiento).first()
        if not db_booking:
            raise HTTPException(status_code=404, detail="Cita no encontrada")

        # Regla de las 3 horas
        fecha_hora_cita = datetime.combine(db_booking.fecha_cita, db_booking.hora_cita)
        if datetime.now() > fecha_hora_cita - timedelta(hours=3):
            raise HTTPException(
                status_code=403, 
                detail="Lo sentimos, ya contamos con usted para este espacio. No es posible reprogramar ni cancelar con menos de 3 horas de anticipación."
            )

        db_booking.fecha_cita = booking_data.fecha_cita
        db_booking.hora_cita = booking_data.hora_cita
        db_booking.observaciones = booking_data.observaciones
        db.commit()
        db.refresh(db_booking)
        return db_booking

    @staticmethod
    def cancel_booking(db: Session, id_agendamiento: int):
        """Cancela una cita validando la regla de las 3 horas"""
        db_booking = db.query(Booking).filter(Booking.id_agendamiento == id_agendamiento).first()
        if not db_booking:
            raise HTTPException(status_code=404, detail="Cita no encontrada")

        # Regla de las 3 horas
        fecha_hora_cita = datetime.combine(db_booking.fecha_cita, db_booking.hora_cita)
        if datetime.now() > fecha_hora_cita - timedelta(hours=3):
            raise HTTPException(
                status_code=403, 
                detail="Lo sentimos, ya contamos con usted para este espacio. No es posible reprogramar ni cancelar con menos de 3 horas de anticipación."
            )

        db_booking.estado_confirmacion = ConfirmationState.CANCELADO
        db.commit()
        return {"detail": "Cita cancelada con éxito"}