import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_logo.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@tfcentro.com');
  final _passwordController = TextEditingController();

  void _login() async {
    final provider = context.read<AuthProvider>();
    
    // Validar campos vacíos
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena ambos campos'), backgroundColor: Colors.red),
      );
      return;
    }

    final success = await provider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (!mounted) return;

    if (success) {
      // TODO: Redirigir al Dashboard correcto según el rol
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión exitoso'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Error desconocido'), backgroundColor: Colors.red),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo personalizado
                const CustomLogo(),
                const SizedBox(height: 8),
                Text(
                  'NIT: 7184810',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textDim,
                  ),
                ),
                const SizedBox(height: 32),

                // Formulario
                CustomTextField(
                  label: 'Correo electrónico',
                  hintText: 'usuario@tfcentro.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Contraseña',
                  hintText: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Iniciar Sesión',
                  icon: TablerIcons.login,
                  isLoading: context.watch<AuthProvider>().isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),

                // Ir a registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta? ',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.textDim,
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
