from datetime import datetime, timedelta
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.core.Enum import UserRole
from app.models.BookingEntity import Booking, ConfirmationState
from app.models.ServiceOrderEntity import ServiceOrder, ServiceOrderState
from app.models.UserEntity import User
from app.schemas.BookingSchema import BookingCreate, BookingUpdate
from app.services.NotificationService import NotificationService, NotificationType

class BookingService:

    @staticmethod
    def create_booking(db: Session, booking_data: BookingCreate, background_tasks=None):
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
        BookingService._notify_admins_about_new_booking(
            db,
            db_booking,
            background_tasks=background_tasks,
        )
        return db_booking

    @staticmethod
    def _notify_admins_about_new_booking(db: Session, booking: Booking, background_tasks=None):
        admin_user_ids = [
            row[0]
            for row in db.query(User.id_usuario)
            .filter(User.rol == UserRole.admin)
            .order_by(User.id_usuario)
            .all()
        ]
        if not admin_user_ids:
            return

        booking_date = booking.fecha_cita.isoformat()
        booking_time = booking.hora_cita.strftime("%H:%M")
        client_name = booking.cliente_nombre
        vehicle_plate = booking.placa_vehiculo

        NotificationService.notify(
            user_ids=admin_user_ids,
            type=NotificationType.booking_created,
            title="Nueva cita agendada",
            body=(
                f"{client_name} agendo una cita para {booking_date} "
                f"a las {booking_time}. Vehiculo: {vehicle_plate}"
            ),
            data={
                "type": NotificationType.booking_created.value,
                "booking_id": str(booking.id_agendamiento),
                "booking_date": booking_date,
            },
            background_tasks=background_tasks,
        )

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
    def update_booking(
        db: Session,
        id_agendamiento: int,
        booking_data: BookingUpdate,
        current_user=None,
    ):
        """Actualiza la fecha/hora de una cita validando la regla de las 3 horas"""
        db_booking = db.query(Booking).filter(Booking.id_agendamiento == id_agendamiento).first()
        if not db_booking:
            raise HTTPException(status_code=404, detail="Cita no encontrada")

        if current_user is not None:
            can_manage_any_booking = current_user.rol in {
                UserRole.admin,
                UserRole.secretary,
            }
            if not can_manage_any_booking and db_booking.id_usuario != current_user.id_usuario:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="No puedes reprogramar una cita de otro usuario.",
                )

        # Regla de las 3 horas
        fecha_hora_cita = datetime.combine(db_booking.fecha_cita, db_booking.hora_cita)
        if datetime.now() > fecha_hora_cita - timedelta(hours=3):
            raise HTTPException(
                status_code=403, 
                detail="Lo sentimos, ya contamos con usted para este espacio. No es posible reprogramar ni cancelar con menos de 3 horas de anticipación."
            )

        schedule_changed = (
            db_booking.fecha_cita != booking_data.fecha_cita
            or db_booking.hora_cita != booking_data.hora_cita
        )
        if schedule_changed and db_booking.estado_confirmacion == ConfirmationState.CONFIRMADO:
            db_booking.estado_confirmacion = ConfirmationState.PENDIENTE
            db_booking.motivo_rechazo = None

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
