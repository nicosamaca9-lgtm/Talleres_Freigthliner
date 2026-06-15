from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.ServiceOrderEntity import ServiceOrder, ServiceOrderState
from app.models.VehicleEntity import Vehicle
from app.schemas.ServiceOrderSchema import ServiceOrderCreate, ServiceOrderUpdate
from datetime import datetime

class ServiceOrderService:
    
    @staticmethod
    def create_order(db: Session, order_data: ServiceOrderCreate):
        # Verificar que el vehículo existe
        vehicle = db.query(Vehicle).filter(Vehicle.id_vehiculo == order_data.id_vehiculo).first()
        if not vehicle:
            raise HTTPException(status_code=404, detail="El vehículo especificado no existe en el sistema.")
            
        db_order = ServiceOrder(**order_data.model_dump())
        db.add(db_order)
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
