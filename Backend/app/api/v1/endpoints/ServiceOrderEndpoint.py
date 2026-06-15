from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.schemas.ServiceOrderSchema import ServiceOrderCreate, ServiceOrderUpdate, ServiceOrderResponse
from app.services.ServiceOrderService import ServiceOrderService

router = APIRouter()

@router.post("/", response_model=ServiceOrderResponse, status_code=status.HTTP_201_CREATED)
def create_service_order(order: ServiceOrderCreate, db: Session = Depends(get_db)):
    """
    Crea una nueva Orden de Servicio en el taller.
    """
    return ServiceOrderService.create_order(db=db, order_data=order)

@router.get("/", response_model=List[ServiceOrderResponse])
def list_service_orders(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Lista todas las órdenes de servicio (para el Admin).
    """
    return ServiceOrderService.get_all_orders(db=db, skip=skip, limit=limit)

@router.get("/{id_orden}", response_model=ServiceOrderResponse)
def get_service_order(id_orden: int, db: Session = Depends(get_db)):
    """
    Obtiene una orden de servicio específica por su ID.
    """
    return ServiceOrderService.get_order(db=db, id_orden=id_orden)

@router.patch("/{id_orden}", response_model=ServiceOrderResponse)
def update_service_order(id_orden: int, order_update: ServiceOrderUpdate, db: Session = Depends(get_db)):
    """
    Actualiza una orden de servicio (Ej: Asignar mecánico, llenar diagnóstico, cambiar estado a Listo).
    """
    return ServiceOrderService.update_order(db=db, id_orden=id_orden, update_data=order_update)

@router.get("/vehicle/{placa}", response_model=ServiceOrderResponse)
def get_active_order_by_placa(placa: str, db: Session = Depends(get_db)):
    """
    Endpoint para el Dashboard del Cliente/Conductor.
    Retorna la orden de servicio que está actualmente activa en el taller para esa placa.
    """
    return ServiceOrderService.get_active_order_by_placa(db=db, placa=placa)
