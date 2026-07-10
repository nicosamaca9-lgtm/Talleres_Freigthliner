import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_logo.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _loginError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loginError = null;
    });

    final provider = context.read<AuthProvider>();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, llena ambos campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
      setState(() {
        _loginError = 'Por favor, ingresa un correo electrónico válido';
      });
      return;
    }

    final success = await provider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      if (provider.isAdmin) {
        context.go('/admin/dashboard');
      } else if (provider.isClient) {
        context.go('/client/dashboard');
      } else if (provider.isMechanic) {
        context.go('/mechanic/dashboard');
      } else {
        final currentRole = provider.role;
        context.read<ChatProvider>().disconnect();
        await provider.logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Portal inválido. Tu rol es: "$currentRole". Solo para clientes, mecánicos y administradores.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      final errorMessage = provider.errorMessage ?? 'Correo o contraseña incorrectos';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error al Iniciar Sesión',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.textColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: GoogleFonts.dmSans(
              color: AppTheme.textMutedColor(context),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Intentar de nuevo',
                style: GoogleFonts.dmSans(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
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
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor(context), width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomLogo(),
                const SizedBox(height: 8),
                Text(
                  'NIT: 7184810',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textMutedColor(context),
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Correo electronico',
                  hintText: 'usuario@tfcentro.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _loginError,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Contrasena',
                  hintText: '********',
                  controller: _passwordController,
                  obscureText: true,
                ),

                const SizedBox(height: 24),
                CustomButton(
                  text: 'Iniciar Sesion',
                  icon: TablerIcons.login,
                  isLoading: context.watch<AuthProvider>().isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No tienes cuenta? ',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.textMutedColor(context),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Registrarse',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
