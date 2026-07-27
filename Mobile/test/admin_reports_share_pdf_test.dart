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
    'recibos': [],
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
    },
  );
}
