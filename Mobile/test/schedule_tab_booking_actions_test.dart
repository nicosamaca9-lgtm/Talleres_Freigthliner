import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/models/booking_model.dart';
import 'package:mobile/models/service_order_model.dart';
import 'package:mobile/models/vehicle_model.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/booking_provider.dart';
import 'package:mobile/providers/vehicle_provider.dart';
import 'package:mobile/screens/client/widgets/agendamiento_cliente.dart';
import 'package:provider/provider.dart';

class FakeAuthProvider extends AuthProvider {
  @override
  int? get userId => 1;
}

class FakeBookingProvider extends BookingProvider {
  FakeBookingProvider(this._bookings);

  final List<BookingModel> _bookings;

  @override
  bool get isLoading => false;

  @override
  List<BookingModel> get myBookings => _bookings;

  @override
  List<ServiceOrderModel> get myActiveOrders => [];

  @override
  Future<void> loadDashboardData(int idUsuario) async {}
}

class FakeVehicleProvider extends VehicleProvider {
  FakeVehicleProvider(this._vehicles);

  final List<VehicleModel> _vehicles;

  @override
  List<VehicleModel> get vehicles => _vehicles;

  @override
  Future<void> loadMyVehicles(int userId) async {}
}

BookingModel buildBooking({required String estado}) {
  return BookingModel(
    idAgendamiento: 1,
    idUsuario: 1,
    idVehiculo: 10,
    fechaSolicitud: '2026-07-20',
    fechaCita: DateTime.now().add(const Duration(days: 7)),
    horaCita: '09:00:00',
    observaciones: 'Nada',
    estadoConfirmacion: estado,
    motivoRechazo: estado == 'RECHAZADO' ? 'Sin cupo disponible' : null,
  );
}

VehicleModel buildVehicle() {
  return VehicleModel(
    idVehiculo: 10,
    placa: 'CBA321',
    marca: 'Mercedes-Benz',
    modelo: '2026',
    tipoVehiculo: 'Camion',
    rolVehiculo: 'Propietario',
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('rejected bookings render reprogram action disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
          ChangeNotifierProvider<BookingProvider>.value(
            value: FakeBookingProvider([buildBooking(estado: 'RECHAZADO')]),
          ),
          ChangeNotifierProvider<VehicleProvider>.value(
            value: FakeVehicleProvider([buildVehicle()]),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ScheduleTab())),
      ),
    );
    await tester.pump();

    final reprogramButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Reprogramar'),
    );

    expect(find.text('RECHAZADO'), findsOneWidget);
    expect(reprogramButton.onPressed, isNull);
  });
}
