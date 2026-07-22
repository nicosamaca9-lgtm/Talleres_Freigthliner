from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException
from app.models.BookingEntity import Booking, ConfirmationState
from app.models.ServiceOrderEntity import ServiceOrder, ServiceOrderState
from app.models.VehicleEntity import Vehicle
from app.models.TechnicalReportEntity import TechnicalReport
from app.models.ReceiptEntity import Receipt, ReceiptItem
from app.models.UserEntity import User
from app.services.NotificationService import NotificationService, NotificationType

class AdminService:
    @staticmethod
    def get_dashboard_stats(db: Session):
        pending_bookings = db.query(func.count(Booking.id_agendamiento)).filter(
            Booking.estado_confirmacion == ConfirmationState.PENDIENTE
        ).scalar()
        
        active_orders = db.query(func.count(ServiceOrder.id_orden)).filter(
            ServiceOrder.estado_orden.in_([ServiceOrderState.EN_DIAGNOSTICO, ServiceOrderState.EN_REPARACION, ServiceOrderState.LISTO_PARA_ENTREGA])
        ).scalar()
        
        pending_reports = db.query(func.count(TechnicalReport.id_informe_tecnico)).filter(
            TechnicalReport.estado_revision == "PENDIENTE"
        ).scalar()
        
        return {
            "citas_pendientes": pending_bookings or 0,
            "vehiculos_en_taller": active_orders or 0,
            "informes_pendientes": pending_reports or 0
        }

    @staticmethod
    def get_all_bookings(db: Session):
        from app.models.BookingEntity import Booking, ConfirmationState
        from datetime import datetime
        
        # We return all bookings so the admin can see pending, confirmed and rejected
        bookings = db.query(Booking).order_by(Booking.fecha_cita.desc(), Booking.hora_cita.desc()).all()
        
        now = datetime.now()
        for b in bookings:
            if b.estado_confirmacion in [ConfirmationState.PENDIENTE, ConfirmationState.CONFIRMADO]:
                # Si la cita fue ayer o antes, o es de hoy y ya pasó de las 18:00
                is_past_date = b.fecha_cita < now.date()
                is_past_time_today = b.fecha_cita == now.date() and now.hour >= 18
                if is_past_date or is_past_time_today:
                    b.estado_confirmacion = ConfirmationState.CANCELADO_POR_SISTEMA
                    b.motivo_rechazo = "Cancelada automáticamente por el sistema al no registrar ingreso al taller."
                    db.commit()
                    
        # Eliminar de la base de datos citas canceladas/rechazadas si son de días anteriores o después de las 20:00
        filtered_bookings = []
        from datetime import time
        deleted_any = False
        for b in bookings:
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
    def get_pending_reports(db: Session):
        return db.query(TechnicalReport).filter(TechnicalReport.estado_revision == "PENDIENTE").all()

    @staticmethod
    def confirm_booking(db: Session, id_agendamiento: int, background_tasks=None):
        booking = db.query(Booking).filter(Booking.id_agendamiento == id_agendamiento).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Cita no encontrada")
        previous_state = booking.estado_confirmacion
        booking.estado_confirmacion = ConfirmationState.CONFIRMADO
        db.commit()
        db.refresh(booking)
        if previous_state != ConfirmationState.CONFIRMADO:
            AdminService._notify_booking_status_change(
                booking,
                notification_type=NotificationType.booking_confirmed,
                title="Cita confirmada",
                body=AdminService._booking_status_body(
                    booking,
                    "Tu cita fue confirmada",
                ),
                background_tasks=background_tasks,
            )
        return booking

    @staticmethod
    def reject_booking(db: Session, id_agendamiento: int, motivo_rechazo: str, background_tasks=None):
        booking = db.query(Booking).filter(Booking.id_agendamiento == id_agendamiento).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Cita no encontrada")
        previous_state = booking.estado_confirmacion
        booking.estado_confirmacion = ConfirmationState.RECHAZADO
        booking.motivo_rechazo = motivo_rechazo
        db.commit()
        db.refresh(booking)
        if previous_state != ConfirmationState.RECHAZADO:
            AdminService._notify_booking_status_change(
                booking,
                notification_type=NotificationType.booking_rejected,
                title="Cita rechazada",
                body=AdminService._booking_status_body(
                    booking,
                    "Tu cita fue rechazada",
                ),
                background_tasks=background_tasks,
            )
        return booking

    @staticmethod
    def _booking_status_body(booking: Booking, prefix: str) -> str:
        booking_date = booking.fecha_cita.isoformat()
        booking_time = booking.hora_cita.strftime("%H:%M")
        return f"{prefix} para {booking_date} a las {booking_time}."

    @staticmethod
    def _notify_booking_status_change(
        booking: Booking,
        *,
        notification_type: NotificationType,
        title: str,
        body: str,
        background_tasks=None,
    ):
        NotificationService.notify(
            user_ids=[booking.id_usuario],
            type=notification_type,
            title=title,
            body=body,
            data={
                "type": notification_type.value,
                "booking_id": str(booking.id_agendamiento),
            },
            background_tasks=background_tasks,
        )

    @staticmethod
    def review_technical_report(db: Session, id_report: int, estado_revision: str, observaciones: str = None):
        report = db.query(TechnicalReport).filter(TechnicalReport.id_informe_tecnico == id_report).first()
        if not report:
            raise ValueError("Informe no encontrado")
        
        report.estado_revision = estado_revision
        if observaciones is not None:
            report.observaciones_admin = observaciones
            
        db.commit()
        db.refresh(report)
        return report

    @staticmethod
    def create_receipt(db: Session, receipt_data):
        from app.schemas.ReceiptSchema import ReceiptCreate
        import random
        import string
        data: ReceiptCreate = receipt_data
        
        # Ensure order exists if provided
        if data.id_orden is not None:
            order = db.query(ServiceOrder).filter(ServiceOrder.id_orden == data.id_orden).first()
            if not order:
                raise ValueError("Orden de servicio no encontrada")
                
            # Check if receipt already exists for this order
            existing = db.query(Receipt).filter(Receipt.id_orden == data.id_orden).first()
            if existing:
                raise ValueError("Ya existe un recibo para esta orden")
        
        # Generate receipt number
        prefix = "COT" if data.tipo_documento == "COTIZACION" else "REC"
        random_suffix = ''.join(random.choices(string.digits, k=6))
        numero_recibo = f"{prefix}-{random_suffix}"
            
        receipt = Receipt(
            numero_recibo=numero_recibo,
            id_orden=data.id_orden,
            tipo_documento=data.tipo_documento,
            cliente_nombre=data.cliente_nombre,
            cliente_nit=data.cliente_nit,
            cliente_telefono=data.cliente_telefono,
            cliente_direccion=data.cliente_direccion,
            cliente_ciudad=data.cliente_ciudad,
            cliente_correo=data.cliente_correo,
            vendedor=data.vendedor,
            placa=data.placa.upper() if data.placa else data.placa,
            forma_pago=data.forma_pago,
            concepto=data.concepto,
            nota_pie=data.nota_pie,
            estado="BORRADOR"
        )
        
        subtotal = 0.0
        iva_total = 0.0
        
        # Prepare items
        for item_in in data.items:
            item_total = item_in.cantidad * item_in.valor_unitario
            iva = item_total * (item_in.porcentaje_iva / 100)
            
            subtotal += item_total
            iva_total += iva
            
            item = ReceiptItem(
                descripcion=item_in.descripcion,
                cantidad=item_in.cantidad,
                valor_unitario=item_in.valor_unitario,
                porcentaje_iva=item_in.porcentaje_iva,
                total=item_total
            )
            receipt.items.append(item)
            
        receipt.subtotal = subtotal
        receipt.iva_total = iva_total
        receipt.total = subtotal + iva_total
        
        db.add(receipt)
        db.commit()
        db.refresh(receipt)
        return receipt

    @staticmethod
    def get_all_receipts(db: Session):
        return db.query(Receipt).order_by(Receipt.fecha_emision.desc()).all()

    @staticmethod
    def update_receipt(db: Session, id_recibo: int, update_data):
        from app.schemas.ReceiptSchema import ReceiptUpdate
        data: ReceiptUpdate = update_data
        
        receipt = db.query(Receipt).filter(Receipt.id_recibo == id_recibo).first()
        if not receipt:
            raise ValueError("Recibo no encontrado")
            
        if receipt.estado == "FINALIZADO":
            raise ValueError("No se puede editar un recibo o cotización finalizada")
            
        update_dict = data.model_dump(exclude_unset=True)
        items_data = update_dict.pop("items", None)
        
        # Normalizar placa a mayúsculas si se actualiza
        if "placa" in update_dict and update_dict["placa"]:
            update_dict["placa"] = update_dict["placa"].upper()
        
        for key, value in update_dict.items():
            setattr(receipt, key, value)
            
        if items_data is not None:
            # Delete old items
            db.query(ReceiptItem).filter(ReceiptItem.id_recibo == id_recibo).delete()
            
            subtotal = 0.0
            iva_total = 0.0
            
            for item_in in items_data:
                item_total = item_in["cantidad"] * item_in["valor_unitario"]
                iva = item_total * (item_in["porcentaje_iva"] / 100)
                
                subtotal += item_total
                iva_total += iva
                
                item = ReceiptItem(
                    id_recibo=id_recibo,
                    descripcion=item_in["descripcion"],
                    cantidad=item_in["cantidad"],
                    valor_unitario=item_in["valor_unitario"],
                    porcentaje_iva=item_in["porcentaje_iva"],
                    total=item_total
                )
                db.add(item)
                
            receipt.subtotal = subtotal
            receipt.iva_total = iva_total
            receipt.total = subtotal + iva_total
            
        db.commit()
        db.refresh(receipt)
        return receipt

    @staticmethod
    def delete_receipt(db: Session, id_recibo: int):
        receipt = db.query(Receipt).filter(Receipt.id_recibo == id_recibo).first()
        if not receipt:
            raise ValueError("Recibo no encontrado")
            
        if receipt.estado == "FINALIZADO":
            raise ValueError("No se puede eliminar un recibo finalizado")
            
        db.delete(receipt)
        db.commit()
        return True

    @staticmethod
    def finalize_receipt(db: Session, id_recibo: int):
        receipt = db.query(Receipt).filter(Receipt.id_recibo == id_recibo).first()
        if not receipt:
            raise ValueError("Recibo no encontrado")
            
        if receipt.estado == "FINALIZADO":
            raise ValueError("El recibo ya está finalizado")
            
        receipt.estado = "FINALIZADO"
        db.commit()
        db.refresh(receipt)
        return receipt

    @staticmethod
    def get_receipts_by_placa(db: Session, placa: str):
        return db.query(Receipt).filter(Receipt.placa == placa).order_by(Receipt.fecha_emision.desc()).all()

    @staticmethod
    def assign_mechanic_to_order(
        db: Session,
        id_orden: int,
        id_mecanico: int,
        background_tasks=None,
    ):
        order = db.query(ServiceOrder).filter(ServiceOrder.id_orden == id_orden).first()
        if not order:
            raise ValueError("Orden de servicio no encontrada")
            
        mechanic = db.query(User).filter(User.id_usuario == id_mecanico, User.rol == "Tecnico").first()
        if not mechanic:
            raise ValueError("El usuario no es un mecánico válido")
            
        previous_mechanic_id = order.id_mecanico
        order.id_mecanico = id_mecanico
        db.commit()
        db.refresh(order)

        if previous_mechanic_id != id_mecanico:
            NotificationService.notify(
                user_ids=[id_mecanico],
                type=NotificationType.order_assigned,
                title="Orden asignada",
                body="Se te asigno una orden de servicio",
                data={
                    "type": NotificationType.order_assigned.value,
                    "order_id": str(order.id_orden),
                },
                background_tasks=background_tasks,
            )

        return order
        
    @staticmethod
    def get_all_users(db: Session):
        return db.query(User).all()

    @staticmethod
    def delete_user(db: Session, id_usuario: int):
        from app.core.Enum import UserRole
        from app.models.BookingEntity import Booking
        
        user = db.query(User).filter(User.id_usuario == id_usuario).first()
        if not user:
            raise ValueError("Usuario no encontrado")
            
        # Lógica de eliminación según el rol
        if user.rol == UserRole.mechanic:
            # Reasignar reportes técnicos a un admin para no perder historial
            from app.models.TechnicalReportEntity import TechnicalReport
            admin = db.query(User).filter(User.rol == UserRole.admin).first()
            if admin:
                reports = db.query(TechnicalReport).filter(TechnicalReport.id_usuario == user.id_usuario).all()
                for report in reports:
                    report.id_usuario = admin.id_usuario

            orders = db.query(ServiceOrder).filter(ServiceOrder.id_mecanico == user.id_usuario).all()
            for order in orders:
                order.id_mecanico = None
                if order.estado_orden != ServiceOrderState.ENTREGADO and order.estado_orden != ServiceOrderState.LISTO_PARA_ENTREGA:
                    order.estado_orden = ServiceOrderState.EN_DIAGNOSTICO
            db.commit()
            
        elif user.rol == UserRole.client:
            # Eliminar agendamientos para evitar errores de Foreign Key
            bookings = db.query(Booking).filter(Booking.id_usuario == user.id_usuario).all()
            for booking in bookings:
                db.delete(booking)
            # Vehiculos y VehicleUser (owner link) se manejan por cascade_delete en la BD
            
        # Limpiar chats y comentarios para evitar IntegrityError
        from app.models.MessageEntity import Message
        from app.models.CommentEntity import Comment
        
        db.query(Message).filter((Message.sender_id == user.id_usuario) | (Message.receiver_id == user.id_usuario)).delete(synchronize_session=False)
        db.query(Comment).filter(Comment.id_usuario == user.id_usuario).delete(synchronize_session=False)
        db.commit()

        db.delete(user)
        db.commit()
        return True

    @staticmethod
    def update_user(db: Session, id_usuario: int, data: dict):
        user = db.query(User).filter(User.id_usuario == id_usuario).first()
        if not user:
            raise ValueError("Usuario no encontrado")
            
        for key, value in data.items():
            if hasattr(user, key) and value is not None:
                setattr(user, key, value)
                
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def get_vehicle_history(db: Session, placa: str):
        placa = placa.upper()
        vehicle = db.query(Vehicle).filter(Vehicle.placa == placa).first()
        if not vehicle:
            raise ValueError("Vehículo no encontrado")
            
        orders = db.query(ServiceOrder).filter(ServiceOrder.id_vehiculo == vehicle.id_vehiculo).all()
        from sqlalchemy import func as sqlfunc
        receipts = db.query(Receipt).filter(sqlfunc.upper(Receipt.placa) == placa.upper()).all()
        
        return {
            "vehiculo": vehicle,
            "ordenes": orders,
            "recibos": receipts
        }
