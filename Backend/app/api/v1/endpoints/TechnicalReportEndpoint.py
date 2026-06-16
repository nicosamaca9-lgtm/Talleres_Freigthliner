from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.api.deps import get_current_user
from app.models.UserEntity import User

from app.db.session import get_db
from app.schemas.TechnicalReportSchema import (
    TechnicalReportRegister,
    TechnicalReportUpdate,
    TechnicalReportResponse,
)
from app.services.TechnicalReportService import TechnicalReportService

router = APIRouter()

@router.post("/", response_model=TechnicalReportResponse, status_code=status.HTTP_201_CREATED)
def create_technical_report(
    report: TechnicalReportRegister, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Crea un nuevo Informe Técnico asociado a una orden y al usuario autenticado (mecánico).
    """
    return TechnicalReportService.create_report(db=db, report_data=report, id_usuario=current_user.id_usuario)

@router.get("/", response_model=List[TechnicalReportResponse])
def get_all_technical_reports(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Obtiene todos los informes técnicos paginados.
    """
    return TechnicalReportService.get_all_reports(db=db, skip=skip, limit=limit)

@router.get("/{id_informe_tecnico}", response_model=TechnicalReportResponse)
def get_technical_report(id_informe_tecnico: int, db: Session = Depends(get_db)):
    """
    Obtiene un informe técnico específico por su ID.
    """
    return TechnicalReportService.get_report(db=db, id_informe_tecnico=id_informe_tecnico)

@router.patch("/{id_informe_tecnico}", response_model=TechnicalReportResponse)
def update_technical_report(id_informe_tecnico: int, report_update: TechnicalReportUpdate, db: Session = Depends(get_db)):
    """
    Actualiza parcialmente un informe técnico (por ejemplo, actualizando repuestos usados).
    """
    return TechnicalReportService.update_report(db=db, id_informe_tecnico=id_informe_tecnico, update_data=report_update)

@router.delete("/{id_informe_tecnico}", status_code=status.HTTP_200_OK)
def delete_technical_report(id_informe_tecnico: int, db: Session = Depends(get_db)):
    """
    Elimina un informe técnico de la base de datos.
    """
    return TechnicalReportService.delete_report(db=db, id_informe_tecnico=id_informe_tecnico)
