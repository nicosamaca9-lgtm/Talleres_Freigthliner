# app/Api/v1/endpoints/AdminEndpoint.py

from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.UserSchema import MechanicRegister
from app.schemas.UserSchema import UserResponse
from app.services.UserService import register_mechanic as register_mechanic_service
from app.core.Enum import UserRole
from app.api.deps import require_roles


from app.core.Exceptions import UserAlreadyExistsError, InvalidCredentialsError


router = APIRouter()


@router.post(
    "/mechanic/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_mechanic(
    data: MechanicRegister, 
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    try:
        return register_mechanic_service(db, data)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except UserAlreadyExistsError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

from app.services.AdminService import AdminService
from app.schemas.BookingSchema import BookingResponse, BookingReject
from app.schemas.TechnicalReportSchema import TechnicalReportReview, TechnicalReportResponse
from app.schemas.ReceiptSchema import ReceiptCreate, ReceiptResponse
from typing import List

@router.get("/stats")
def get_admin_stats(
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    return AdminService.get_dashboard_stats(db)

@router.get("/bookings", response_model=List[BookingResponse])
def get_all_bookings(
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    return AdminService.get_all_bookings(db)

@router.get("/reports/pending", response_model=List[TechnicalReportResponse])
def get_pending_reports(
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    return AdminService.get_pending_reports(db)

@router.patch("/bookings/{id_agendamiento}/confirm", response_model=BookingResponse)
def confirm_booking(
    id_agendamiento: int,
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    try:
        return AdminService.confirm_booking(db, id_agendamiento)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.patch("/bookings/{id_agendamiento}/reject", response_model=BookingResponse)
def reject_booking(
    id_agendamiento: int,
    reject_data: BookingReject,
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    try:
        return AdminService.reject_booking(db, id_agendamiento, reject_data.motivo_rechazo)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.patch("/reports/{id_report}/review", response_model=TechnicalReportResponse)
def review_report(
    id_report: int,
    data: TechnicalReportReview,
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    try:
        return AdminService.review_technical_report(db, id_report, data.estado_revision, data.observaciones_admin)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/receipts", response_model=ReceiptResponse, status_code=status.HTTP_201_CREATED)
def create_receipt(
    data: ReceiptCreate,
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    try:
        return AdminService.create_receipt(db, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

from app.schemas.ServiceOrderSchema import ServiceOrderResponse
from pydantic import BaseModel

class AssignMechanicRequest(BaseModel):
    id_mecanico: int

@router.patch("/service-orders/{id_orden}/assign", response_model=ServiceOrderResponse)
def assign_mechanic(
    id_orden: int,
    data: AssignMechanicRequest,
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    try:
        return AdminService.assign_mechanic_to_order(db, id_orden, data.id_mecanico)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/users", response_model=List[UserResponse])
def get_all_users(
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    return AdminService.get_all_users(db)

@router.delete("/users/{id_usuario}")
def delete_user(
    id_usuario: int,
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    try:
        AdminService.delete_user(db, id_usuario)
        return {"mensaje": "Usuario eliminado correctamente"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/vehicles/{placa}/history")
def get_vehicle_history(
    placa: str,
    db: Session = Depends(get_db),
    current_user = Depends(require_roles(UserRole.admin.value))
):
    try:
        return AdminService.get_vehicle_history(db, placa)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
