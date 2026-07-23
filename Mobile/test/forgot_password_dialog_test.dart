import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/auth/widgets/forgot_password_dialog.dart';
import 'package:provider/provider.dart';

class FakeAuthProvider extends AuthProvider {
  String? _errorMessage;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<bool> forgotPassword(String correo) async {
    _errorMessage = 'El correo no existe';
    return false;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows missing email error inside the email field', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: FakeAuthProvider(),
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ForgotPasswordDialog())),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'rt@gmail.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar Código'));
    await tester.pump();

    expect(find.text('El correo no existe'), findsOneWidget);
  });
}
