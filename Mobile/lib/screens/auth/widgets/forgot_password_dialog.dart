import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import 'reset_password_dialog.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final provider = context.read<AuthProvider>();
    
    final success = await provider.forgotPassword(email);
    
    if (!mounted) return;
    
    if (success) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => ResetPasswordDialog(email: email),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al solicitar recuperación'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    
    return Dialog(
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recuperar Contraseña',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ingresa tu correo electrónico y te enviaremos un código de 6 dígitos para restablecer tu contraseña.',
                style: GoogleFonts.dmSans(
                  color: AppTheme.textMutedColor(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Correo Electrónico',
                controller: _emailController,
                hintText: 'ejemplo@correo.com',
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'El correo es requerido';
                  if (!val.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : CustomButton(
                      text: 'Enviar Código',
                      onPressed: _submit,
                    ),
              const SizedBox(height: 10),
              if (!isLoading)
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar', style: GoogleFonts.dmSans(color: AppTheme.textMutedColor(context))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
