import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';

class ResetPasswordDialog extends StatefulWidget {
  final String email;
  const ResetPasswordDialog({super.key, required this.email});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final code = _codeController.text.trim();
    final newPassword = _passwordController.text;
    final provider = context.read<AuthProvider>();
    
    final success = await provider.resetPassword(
      correo: widget.email,
      codigo: code,
      nuevaPassword: newPassword,
    );
    
    if (!mounted) return;
    
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña restablecida correctamente. Ya puedes iniciar sesión.'),
          backgroundColor: AppTheme.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al restablecer contraseña'),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresa tu Código',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.textColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enviamos un código de 6 dígitos a ${widget.email}. Úsalo para crear tu nueva contraseña.',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textMutedColor(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Código de Verificación',
                  controller: _codeController,
                  hintText: 'Ej: 123456',
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.length != 6 ? 'El código debe tener 6 dígitos' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nueva Contraseña',
                  controller: _passwordController,
                  hintText: 'Mínimo 6 caracteres',
                  obscureText: true,
                  validator: (val) => val == null || val.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirmar Contraseña',
                  controller: _confirmPasswordController,
                  hintText: 'Vuelve a escribir la contraseña',
                  obscureText: true,
                  validator: (val) => val != _passwordController.text ? 'Las contraseñas no coinciden' : null,
                ),
                const SizedBox(height: 24),
                isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : CustomButton(
                        text: 'Restablecer',
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
      ),
    );
  }
}
