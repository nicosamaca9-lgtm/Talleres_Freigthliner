from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.TechnicalReportEntity import TechnicalReport
from app.models.ServiceOrderEntity import ServiceOrder
from app.models.UserEntity import User
from app.schemas.TechnicalReportSchema import TechnicalReportRegister, TechnicalReportUpdate

class TechnicalReportService:
    
    @staticmethod
    def create_report(db: Session, report_data: TechnicalReportRegister, id_usuario: int):
        # Validate that the User exists
        user = db.query(User).filter(User.id_usuario == id_usuario).first()
        if not user:
            raise HTTPException(status_code=404, detail="El usuario (mecánico) especificado no existe.")
            
        # Validate that the ServiceOrder exists
        order = db.query(ServiceOrder).filter(ServiceOrder.id_orden == report_data.id_orden).first()
        if not order:
            raise HTTPException(status_code=404, detail="La orden de servicio especificada no existe.")
            
        # Create and save the TechnicalReport
        report_dict = report_data.model_dump()
        report_dict["id_usuario"] = id_usuario
        db_report = TechnicalReport(**report_dict)
        db.add(db_report)
        db.commit()
        db.refresh(db_report)
        return db_report

    @staticmethod
    def get_report(db: Session, id_informe_tecnico: int):
        report = db.query(TechnicalReport).filter(TechnicalReport.id_informe_tecnico == id_informe_tecnico).first()
        if not report:
            raise HTTPException(status_code=404, detail="Informe técnico no encontrado.")
        return report

    @staticmethod
    def get_all_reports(db: Session, skip: int = 0, limit: int = 100):
        return db.query(TechnicalReport).offset(skip).limit(limit).all()

    @staticmethod
    def update_report(db: Session, id_informe_tecnico: int, update_data: TechnicalReportUpdate):
        db_report = TechnicalReportService.get_report(db, id_informe_tecnico)
        
        update_dict = update_data.model_dump(exclude_unset=True)
        for key, value in update_dict.items():
            setattr(db_report, key, value)
            
        db.commit()
        db.refresh(db_report)
        return db_report

    @staticmethod
    def delete_report(db: Session, id_informe_tecnico: int):
        db_report = TechnicalReportService.get_report(db, id_informe_tecnico)
        
        db.delete(db_report)
        db.commit()
        return {"message": "Informe técnico eliminado exitosamente"}
