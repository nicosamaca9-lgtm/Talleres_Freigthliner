import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/models/booking_model.dart';
import 'package:mobile/providers/admin_provider.dart';
import 'package:mobile/screens/admin/widgets/admin_bookings_tab.dart';
import 'package:provider/provider.dart';

class FakeAdminProvider extends AdminProvider {
  FakeAdminProvider(this._bookings);

  final List<BookingModel> _bookings;

  @override
  bool get isLoading => false;

  @override
  List<BookingModel> get allBookings => _bookings;

  @override
  Future<void> fetchAllBookings() async {}

  @override
  Future<void> rejectBooking(int id, String motivoRechazo) async {}
}

BookingModel buildPendingBooking() {
  return BookingModel(
    idAgendamiento: 1,
    idUsuario: 2,
    idVehiculo: 10,
    fechaSolicitud: '2026-07-20',
    fechaCita: DateTime.now().add(const Duration(days: 7)),
    horaCita: '09:00:00',
    observaciones: 'Revision inicial',
    estadoConfirmacion: 'PENDIENTE',
    clienteNombre: 'Cliente prueba',
    placaVehiculo: 'ABC123',
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('reject reason field enforces a 30 character limit', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AdminProvider>.value(
        value: FakeAdminProvider([buildPendingBooking()]),
        child: const MaterialApp(home: Scaffold(body: AdminBookingsTab())),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rechazar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Motivo demasiado largo para rechazar esta cita',
    );
    await tester.pump();

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.controller.text.length, 30);
    expect(editableText.controller.text, 'Motivo demasiado largo para re');
  });
}
