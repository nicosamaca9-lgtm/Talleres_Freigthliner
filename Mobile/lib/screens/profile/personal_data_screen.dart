import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _correoController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AuthProvider>();
    _nombreController = TextEditingController(text: provider.userName ?? '');
    _apellidoController = TextEditingController(text: provider.userLastName ?? '');
    _correoController = TextEditingController(text: ''); // Not in token by default
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Actualizar Información',
          style: GoogleFonts.rajdhani(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas actualizar tus datos personales?',
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
              _actualizarDatos();
            },
            child: Text(
              'Sí, Actualizar',
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

  void _actualizarDatos() {
    // Simular la actualización de datos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos actualizados correctamente'),
        backgroundColor: AppTheme.green,
      ),
    );
    context.pop();
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
          'Datos Personales',
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
              label: 'Nombre',
              controller: _nombreController,
              hintText: 'Tu nombre',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Apellido',
              controller: _apellidoController,
              hintText: 'Tu apellido',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Correo Electrónico',
              controller: _correoController,
              hintText: 'ejemplo@correo.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Actualizar Información',
              icon: Icons.save_rounded,
              onPressed: _showConfirmationDialog,
            ),
          ],
        ),
      ),
    );
  }
}
