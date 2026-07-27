import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/models/service_order_model.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/providers/admin_provider.dart';
import 'package:mobile/screens/admin/widgets/admin_orders_tab.dart';
import 'package:provider/provider.dart';

class FakeAdminOrdersProvider extends AdminProvider {
  FakeAdminOrdersProvider({
    required List<ServiceOrderModel> orders,
    required List<UserModel> users,
  }) : _orders = orders,
       _users = users;

  final List<ServiceOrderModel> _orders;
  final List<UserModel> _users;

  int? updatedOrderId;
  String? updatedReport;

  @override
  bool get isLoading => false;

  @override
  List<ServiceOrderModel> get serviceOrders => _orders;

  @override
  List<UserModel> get users => _users;

  @override
  Future<void> fetchServiceOrders() async {}

  @override
  Future<void> fetchUsers() async {}

  @override
  Future<void> updateOrderReport(int idOrden, String informeTrabajo) async {
    updatedOrderId = idOrden;
    updatedReport = informeTrabajo;
  }
}

ServiceOrderModel buildOrderWithReportImages() {
  return ServiceOrderModel(
    idOrden: 1,
    numeroOrden: 'ORD-0001',
    idVehiculo: 10,
    idMecanico: 7,
    fechaIngreso: '2026-07-26',
    horaIngreso: '20:08:51',
    clienteNombre: 'Luis',
    clienteIdentificacion: '123',
    clienteTelefono: '3000000000',
    kilometrajeIngreso: 1200,
    nivelCombustible: '1/2',
    trabajosARealizar: 'Revision',
    informeTrabajo:
        'Diagnostico: nada\n'
        'Recomendaciones: ninguna\n'
        '[IMAGENES]https://cdn.test/a.jpg,https://cdn.test/b.jpg[/IMAGENES]',
    estadoOrden: 'EN_DIAGNOSTICO',
    placaVehiculo: 'ABC123',
  );
}

UserModel buildMechanic() {
  return UserModel(
    idUsuario: 7,
    nombre: 'Mecanico',
    apellido: 'Prueba',
    correo: 'mecanico@example.com',
    rol: 'Mecanico',
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('admin can preview and remove report images before saving', (
    tester,
  ) async {
    final provider = FakeAdminOrdersProvider(
      orders: [buildOrderWithReportImages()],
      users: [buildMechanic()],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AdminProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: AdminOrdersTab())),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('admin_report_image_preview_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('admin_report_image_preview_1')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('admin_report_image_delete_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('admin_report_image_delete_1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('admin_report_image_delete_0')));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(provider.updatedOrderId, 1);
    expect(provider.updatedReport, contains('Diagnostico: nada'));
    expect(provider.updatedReport, isNot(contains('https://cdn.test/a.jpg')));
    expect(provider.updatedReport, contains('https://cdn.test/b.jpg'));
    expect(
      provider.updatedReport,
      contains('[IMAGENES]https://cdn.test/b.jpg[/IMAGENES]'),
    );
  });
}
