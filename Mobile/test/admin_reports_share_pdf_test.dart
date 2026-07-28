import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/models/service_order_model.dart';
import 'package:mobile/providers/admin_provider.dart';
import 'package:mobile/screens/admin/widgets/admin_reports_tab.dart';
import 'package:provider/provider.dart';

class FakeAdminReportsProvider extends AdminProvider {
  FakeAdminReportsProvider();

  String? fetchedPlate;

  final Map<String, dynamic> _vehicle = {
    'placa': 'ABC123',
    'marca': 'Volvo',
    'modelo': '2027',
    'tipo_vehiculo': 'Otro',
  };

  @override
  bool get isLoading => false;

  @override
  List<dynamic> get allVehicles => [_vehicle];

  @override
  Map<String, dynamic>? get vehicleHistory => {
    'vehiculo': _vehicle,
    'ordenes': [
      {
        'id_orden': 1,
        'numero_orden': 'ORD-0001',
        'id_vehiculo': 10,
        'fecha_ingreso': '2026-07-26',
        'hora_ingreso': '20:08:51',
        'fecha_salida': '2026-07-27',
        'cliente_nombre': 'Luis',
        'cliente_identificacion': '111111111',
        'cliente_telefono': '3336669998',
        'kilometraje_ingreso': 20000,
        'nivel_combustible': '1/2',
        'trabajos_a_realizar': 'Muchas cosas',
        'informe_trabajo': 'Diagnostico: nada\nRecomendaciones: ninguna',
        'estado_orden': 'ENTREGADO',
        'placa_vehiculo': 'ABC123',
        'marca_vehiculo': 'Volvo',
      },
    ],
    'recibos': [
      {
        'id_recibo': 9,
        'tipo_documento': 'RECIBO',
        'numero_recibo': 'REC-0009',
        'cliente_nombre': 'Luis',
        'placa': 'ABC123',
        'total': 119000,
        'estado': 'FINALIZADO',
      },
    ],
  };

  @override
  Future<void> fetchAllVehicles() async {}

  @override
  Future<void> fetchReceipts() async {}

  @override
  Future<void> fetchVehicleHistory(String placa) async {
    fetchedPlate = placa;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'vehicle history exposes share pdf action without layout errors',
    (tester) async {
      final provider = FakeAdminReportsProvider();
      ServiceOrderModel? sharedOrder;
      Map<String, dynamic>? sharedReceipt;

      await tester.pumpWidget(
        ChangeNotifierProvider<AdminProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: AdminReportsTab(
                shareServiceOrderPdf: (order) async {
                  sharedOrder = order;
                  return true;
                },
                shareReceiptPdf: (receipt) async {
                  sharedReceipt = receipt;
                  return true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('ABC123'));
      await tester.pumpAndSettle();

      expect(provider.fetchedPlate, 'ABC123');
      expect(find.text('Descargar Orden (PDF)'), findsOneWidget);
      expect(find.text('Compartir PDF'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('share_service_order_pdf_1')));
      await tester.pump();

      expect(sharedOrder?.idOrden, 1);
      expect(sharedOrder?.numeroOrden, 'ORD-0001');

      await tester.tap(find.text('Recibos'));
      await tester.pumpAndSettle();

      expect(find.text('Descargar Recibo (PDF)'), findsNothing);
      expect(find.byKey(const Key('download_receipt_pdf_9')), findsOneWidget);
      expect(find.byKey(const Key('share_receipt_pdf_9')), findsOneWidget);
      expect(
        tester.getCenter(find.byKey(const Key('download_receipt_pdf_9'))).dy,
        moreOrLessEquals(
          tester.getCenter(find.text('RECIBO REC-0009')).dy,
          epsilon: 24,
        ),
      );
      expect(
        tester.getCenter(find.byKey(const Key('share_receipt_pdf_9'))).dy,
        moreOrLessEquals(
          tester.getCenter(find.text('RECIBO REC-0009')).dy,
          epsilon: 24,
        ),
      );

      await tester.tap(find.byKey(const Key('share_receipt_pdf_9')));
      await tester.pump();

      expect(sharedReceipt?['id_recibo'], 9);
      expect(sharedReceipt?['numero_recibo'], 'REC-0009');
    },
  );
}
