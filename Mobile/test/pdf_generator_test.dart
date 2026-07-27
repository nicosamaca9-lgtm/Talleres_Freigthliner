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
}
