import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SecurityPasswordScreen extends StatefulWidget {
  const SecurityPasswordScreen({super.key});

  @override
  State<SecurityPasswordScreen> createState() => _SecurityPasswordScreenState();
}

class _SecurityPasswordScreenState extends State<SecurityPasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showConfirmationDialog() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas nuevas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Actualizar Contraseña',
          style: GoogleFonts.rajdhani(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas cambiar tu contraseña?',
          style: GoogleFonts.dmSans(
            color: AppTheme.textMutedColor(context),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.dmSans(color: AppTheme.textMutedColor(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _actualizarPassword();
            },
            child: Text(
              'Sí, Cambiar',
              style: GoogleFonts.dmSans(
                color: AppTheme.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarPassword() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente'),
          backgroundColor: AppTheme.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al actualizar contraseña'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textColor(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Seguridad y Contraseña',
          style: GoogleFonts.rajdhani(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Contraseña Actual',
              controller: _oldPasswordController,
              hintText: 'Ingresa tu contraseña actual',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Nueva Contraseña',
              controller: _newPasswordController,
              hintText: 'Mínimo 6 caracteres',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Confirmar Nueva Contraseña',
              controller: _confirmPasswordController,
              hintText: 'Repite la nueva contraseña',
              obscureText: true,
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, provider, child) {
                return CustomButton(
                  text: 'Actualizar Contraseña',
                  icon: Icons.lock_reset_rounded,
                  isLoading: provider.isLoading,
                  onPressed: _showConfirmationDialog,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
