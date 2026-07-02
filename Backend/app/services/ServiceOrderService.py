from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.ServiceOrderEntity import ServiceOrder, ServiceOrderState
from app.models.VehicleEntity import Vehicle
from app.models.VehicleUserEntity import VehicleUser
from app.schemas.ServiceOrderSchema import ServiceOrderCreate, ServiceOrderUpdate
from datetime import datetime

class ServiceOrderService:
    
    @staticmethod
    def create_order(db: Session, order_data: ServiceOrderCreate):
        from app.models.BookingEntity import Booking, ConfirmationState
        # Verificar que el vehículo existe
        vehicle = db.query(Vehicle).filter(Vehicle.id_vehiculo == order_data.id_vehiculo).first()
        if not vehicle:
            raise HTTPException(status_code=404, detail="El vehículo especificado no existe en el sistema.")
        
        # Determinar el consecutivo (numero_orden)
        last_order = db.query(ServiceOrder).order_by(ServiceOrder.id_orden.desc()).first()
        next_id = 1 if not last_order else last_order.id_orden + 1
        numero_orden = f"ORD-{next_id:04d}"
        
        order_dict = order_data.model_dump()
        order_dict['numero_orden'] = numero_orden
            
        db_order = ServiceOrder(**order_dict)
        db.add(db_order)
        
        # Si tiene agendamiento vinculado, actualizar su estado a EN_TALLER
        if db_order.id_agendamiento:
            booking = db.query(Booking).filter(Booking.id_agendamiento == db_order.id_agendamiento).first()
            if booking:
                booking.estado_confirmacion = ConfirmationState.EN_TALLER
                
        db.commit()
        db.refresh(db_order)
        return db_order

    @staticmethod
    def get_order(db: Session, id_orden: int):
        order = db.query(ServiceOrder).filter(ServiceOrder.id_orden == id_orden).first()
        if not order:
            raise HTTPException(status_code=404, detail="Orden de servicio no encontrada.")
        return order

    @staticmethod
    def get_all_orders(db: Session, skip: int = 0, limit: int = 100):
        return db.query(ServiceOrder).offset(skip).limit(limit).all()

    @staticmethod
    def update_order(db: Session, id_orden: int, update_data: ServiceOrderUpdate):
        db_order = ServiceOrderService.get_order(db, id_orden)
        
        update_dict = update_data.model_dump(exclude_unset=True)
        
        # Validación de seguridad: No se puede finalizar sin reporte del mecánico
        nuevo_estado = update_dict.get("estado_orden")
        if nuevo_estado in [ServiceOrderState.LISTO_PARA_ENTREGA, ServiceOrderState.ENTREGADO]:
            informe = update_dict.get("informe_trabajo", db_order.informe_trabajo)
            if not informe or not informe.strip():
                raise HTTPException(
                    status_code=400, 
                    detail="No puedes entregar el vehículo hasta que el mecánico escriba el informe del trabajo realizado."
                )

        # Si cambia a ENTREGADO y no se proveyó fecha_salida, la llenamos automático
        if nuevo_estado == ServiceOrderState.ENTREGADO:
            if not db_order.fecha_salida and "fecha_salida" not in update_dict:
                update_dict["fecha_salida"] = datetime.now().date()
                update_dict["hora_salida"] = datetime.now().time()
                
        for key, value in update_dict.items():
            setattr(db_order, key, value)
            
        db.commit()
        db.refresh(db_order)
        return db_order

    @staticmethod
    def get_active_order_by_placa(db: Session, placa: str):
        """Retorna la última orden activa de un vehículo, buscando por su placa."""
        vehicle = db.query(Vehicle).filter(Vehicle.placa == placa).first()
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado.")
            
        # Buscar órdenes que NO estén en estado ENTREGADO para ese vehículo
        active_order = db.query(ServiceOrder).filter(
            ServiceOrder.id_vehiculo == vehicle.id_vehiculo,
            ServiceOrder.estado_orden != ServiceOrderState.ENTREGADO
        ).order_by(ServiceOrder.id_orden.desc()).first()
        
        if not active_order:
            raise HTTPException(status_code=404, detail="Este vehículo no tiene ninguna orden de servicio activa en el taller.")
            
        return active_order

    @staticmethod
    def get_active_orders_by_user(db: Session, id_usuario: int):
        """Retorna todas las órdenes de servicio activas de los vehículos asociados a un usuario."""
        # 1. Encontrar los IDs de los vehículos del usuario
        vehicle_ids = db.query(VehicleUser.id_vehiculo).filter(VehicleUser.id_usuario == id_usuario).all()
        vehicle_ids = [vid[0] for vid in vehicle_ids]
        
        if not vehicle_ids:
            return []
            
        # 2. Buscar las órdenes activas para esos vehículos
        active_orders = db.query(ServiceOrder).filter(
            ServiceOrder.id_vehiculo.in_(vehicle_ids),
            ServiceOrder.estado_orden != ServiceOrderState.ENTREGADO
        ).order_by(ServiceOrder.id_orden.desc()).all()
        
        return active_orders
