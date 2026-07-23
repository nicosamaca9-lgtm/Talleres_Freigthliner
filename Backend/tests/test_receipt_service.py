import pytest

from app.models.ReceiptEntity import Receipt, ReceiptItem
from app.schemas.ReceiptSchema import ReceiptCreate, ReceiptItemCreate, ReceiptUpdate
from app.services.AdminService import AdminService


def receipt_payload(
    *,
    placa: str = "abc123",
    tipo_documento: str = "RECIBO",
    items: list[ReceiptItemCreate] | None = None,
) -> ReceiptCreate:
    return ReceiptCreate(
        tipo_documento=tipo_documento,
        cliente_nombre="Cliente Recibo",
        cliente_nit="900123456",
        cliente_telefono="3001234567",
        cliente_direccion="Calle 1",
        cliente_correo="cliente@example.com",
        vendedor="Administrador",
        placa=placa,
        forma_pago="Contado",
        concepto="TRABAJO REALIZADO",
        items=items
        or [
            ReceiptItemCreate(
                descripcion="Cambio de aceite",
                cantidad=2,
                valor_unitario=100_000,
                porcentaje_iva=19,
            )
        ],
    )


def test_create_receipt_normalizes_plate_and_calculates_totals(db):
    receipt = AdminService.create_receipt(db, receipt_payload())

    assert receipt.placa == "ABC123"
    assert receipt.estado == "BORRADOR"
    assert receipt.numero_recibo.startswith("REC-")
    assert receipt.subtotal == 200_000
    assert receipt.iva_total == 38_000
    assert receipt.total == 238_000
    assert len(receipt.items) == 1
    assert receipt.items[0].total == 200_000


def test_update_receipt_updates_plate_items_and_totals(db):
    receipt = AdminService.create_receipt(db, receipt_payload())

    updated = AdminService.update_receipt(
        db,
        receipt.id_recibo,
        ReceiptUpdate(
            placa="def456",
            concepto="DIAGNOSTICO",
            items=[
                ReceiptItemCreate(
                    descripcion="Diagnostico tecnico",
                    cantidad=3,
                    valor_unitario=50_000,
                    porcentaje_iva=0,
                )
            ],
        ),
    )

    assert updated.placa == "DEF456"
    assert updated.concepto == "DIAGNOSTICO"
    assert updated.subtotal == 150_000
    assert updated.iva_total == 0
    assert updated.total == 150_000
    assert db.query(ReceiptItem).filter(ReceiptItem.id_recibo == receipt.id_recibo).count() == 1


def test_delete_draft_receipt_removes_receipt_and_items(db):
    receipt = AdminService.create_receipt(db, receipt_payload())
    receipt_id = receipt.id_recibo

    assert AdminService.delete_receipt(db, receipt_id) is True

    assert db.get(Receipt, receipt_id) is None
    assert db.query(ReceiptItem).filter(ReceiptItem.id_recibo == receipt_id).count() == 0


def test_finalized_receipt_cannot_be_updated_or_deleted(db):
    receipt = AdminService.create_receipt(db, receipt_payload())

    finalized = AdminService.finalize_receipt(db, receipt.id_recibo)

    assert finalized.estado == "FINALIZADO"
    with pytest.raises(ValueError, match="No se puede editar"):
        AdminService.update_receipt(
            db,
            receipt.id_recibo,
            ReceiptUpdate(concepto="NO DEBE CAMBIAR"),
        )
    with pytest.raises(ValueError, match="No se puede eliminar"):
        AdminService.delete_receipt(db, receipt.id_recibo)
    assert db.get(Receipt, receipt.id_recibo) is not None
