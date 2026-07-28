import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/pdf_generator.dart';
import 'package:mobile/models/service_order_model.dart';

ServiceOrderModel buildPdfOrder({String numeroOrden = 'ORD-0001'}) {
  return ServiceOrderModel(
    idOrden: 1,
    numeroOrden: numeroOrden,
    idVehiculo: 10,
    fechaIngreso: '2026-07-26',
    horaIngreso: '20:08:51',
    clienteNombre: 'Luis',
    clienteIdentificacion: '111111111',
    clienteTelefono: '3336669998',
    kilometrajeIngreso: 20000,
    nivelCombustible: '1/2',
    trabajosARealizar: 'Muchas cosas',
    informeTrabajo: 'Diagnostico: nada\nRecomendaciones: ninguna',
    estadoOrden: 'ENTREGADO',
    placaVehiculo: 'ABC123',
    marcaVehiculo: 'Volvo',
  );
}

Map<String, dynamic> buildPdfReceipt({
  String tipoDocumento = 'RECIBO',
  String numeroRecibo = 'REC-0001',
}) {
  return {
    'tipo_documento': tipoDocumento,
    'numero_recibo': numeroRecibo,
    'cliente_nombre': 'Luis',
    'cliente_nit': '111111111',
    'cliente_direccion': 'Calle 1',
    'cliente_ciudad': 'Bogota',
    'cliente_telefono': '3336669998',
    'cliente_correo': 'luis@example.com',
    'concepto': 'servicio',
    'fecha_emision': '2026-07-27T10:00:00',
    'placa': 'ABC123',
    'vendedor': 'Administrador',
    'subtotal': 100000,
    'iva_total': 19000,
    'total': 119000,
    'nota_pie': 'Gracias por su compra',
    'items': [
      {
        'descripcion': 'Cambio de aceite',
        'cantidad': 1,
        'valor_unitario': 100000,
        'porcentaje_iva': 19,
        'total': 100000,
      },
    ],
  };
}

void main() {
  test('buildServiceOrderPdfBytes creates a valid pdf document', () async {
    final bytes = await PdfGenerator.buildServiceOrderPdfBytes(
      buildPdfOrder(),
      null,
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('serviceOrderPdfFileName sanitizes unsafe order identifiers', () {
    final fileName = PdfGenerator.serviceOrderPdfFileName(
      buildPdfOrder(numeroOrden: 'ORD 1/2'),
    );

    expect(fileName, 'Orden_Servicio_ORD_1_2.pdf');
  });

  test('buildReceiptPdfBytes creates a valid pdf document', () async {
    final bytes = await PdfGenerator.buildReceiptPdfBytes(buildPdfReceipt());

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('receiptPdfFileName sanitizes unsafe receipt identifiers', () {
    final fileName = PdfGenerator.receiptPdfFileName(
      buildPdfReceipt(tipoDocumento: 'RECIBO FINAL', numeroRecibo: 'R/1'),
    );

    expect(fileName, 'RECIBO_FINAL_R_1.pdf');
  });
}
