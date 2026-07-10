import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _correoError;
  String? _cedulaError;
  String? _telefonoError;
  String? _passwordError;

  void _register() async {
    setState(() {
      _correoError = null;
      _cedulaError = null;
      _telefonoError = null;
      _passwordError = null;
    });

    final provider = context.read<AuthProvider>();

    if (_nombreController.text.isEmpty ||
        _apellidoController.text.isEmpty ||
        _correoController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, llena los campos obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_correoController.text.contains('@') || !_correoController.text.contains('.')) {
      setState(() {
        _correoError = 'Ingresa un correo válido (ejemplo@correo.com)';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'La contraseña debe tener al menos 6 caracteres';
      });
      return;
    }

    final cedula = _cedulaController.text.trim();
    if (cedula.isEmpty) {
      setState(() {
        _cedulaError = 'Por favor, ingresa una cédula válida';
      });
      return;
    }

    final telefono = _telefonoController.text.trim();
    if (telefono.length != 10) {
      setState(() {
        _telefonoError = 'El teléfono debe tener 10 dígitos';
      });
      return;
    }

    final success = await provider.register(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      correo: _correoController.text.trim(),
      password: _passwordController.text,
      telefono: telefono,
      cedula: cedula,
    );

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 28),
              const SizedBox(width: 10),
              Text(
                '¡Cuenta Creada!',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Tu cuenta ha sido creada con éxito. Ahora puedes iniciar sesión con tus credenciales.',
            style: GoogleFonts.dmSans(
              color: AppTheme.textMutedColor(context),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/login');
              },
              child: Text(
                'Ir a Iniciar Sesión',
                style: GoogleFonts.dmSans(color: AppTheme.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      if (provider.errorMessage != null) {
        final message = provider.errorMessage!;
        final error = message.toLowerCase();
        setState(() {
          if (error.contains('correo') || error.contains('email')) {
            _correoError = message;
          } else if (error.contains('teléfono') || error.contains('telefono')) {
            _telefonoError = message;
          } else if (error.contains('cédula') || error.contains('cedula')) {
            _cedulaError = message;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        });
      }
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor(context), width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Crear Cuenta',
                  style: GoogleFonts.rajdhani(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.green,
                  ),
                ),
                Text(
                  'Regístrate como cliente en TF Centro Automotriz',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textMutedColor(context),
                  ),
                ),
                const SizedBox(height: 32),

                // Formulario
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Nombre',
                        hintText: 'Ej. Juan',
                        controller: _nombreController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Apellido',
                        hintText: 'Ej. Pérez',
                        controller: _apellidoController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'NIT / Cédula',
                  hintText: 'Ej. 123456789',
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: _cedulaError,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Teléfono',
                  hintText: 'Ej. 3000000000',
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: _telefonoError,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Correo electrónico',
                  hintText: 'usuario@correo.com',
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _correoError,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Contraseña',
                  hintText: 'Mínimo 6 caracteres',
                  controller: _passwordController,
                  obscureText: true,
                  errorText: _passwordError,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Crear Cuenta',
                  icon: TablerIcons.user_plus,
                  isLoading: context.watch<AuthProvider>().isLoading,
                  onPressed: _register,
                ),
                const SizedBox(height: 16),

                // Ir a login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.textMutedColor(context),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Iniciar Sesión',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
