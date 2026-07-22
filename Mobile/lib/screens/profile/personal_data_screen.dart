import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:flutter/services.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late TextEditingController _cedulaController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AuthProvider>();
    _nombreController = TextEditingController(text: provider.userName ?? '');
    _apellidoController = TextEditingController(text: provider.userLastName ?? '');
    _correoController = TextEditingController(text: provider.correo ?? '');
    _telefonoController = TextEditingController(text: provider.telefono ?? '');
    _cedulaController = TextEditingController(text: provider.cedula ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
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

  void _actualizarDatos() async {
    final provider = context.read<AuthProvider>();
    
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final telefono = _telefonoController.text.trim();
    final cedula = _cedulaController.text.trim();
    
    if (nombre.isEmpty || apellido.isEmpty || telefono.isEmpty || cedula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos permitidos'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    
    if (telefono.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El teléfono debe tener 10 dígitos'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    final success = await provider.updateProfile(
      nombre: nombre,
      apellido: apellido,
      telefono: telefono,
      cedula: cedula,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos actualizados correctamente'),
          backgroundColor: AppTheme.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al actualizar perfil'),
          backgroundColor: AppTheme.errorColor,
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
              readOnly: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Teléfono',
              controller: _telefonoController,
              hintText: 'Tu número de teléfono',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Cédula / NIT',
              controller: _cedulaController,
              hintText: 'Tu documento de identidad',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, provider, child) {
                return provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : CustomButton(
                        text: 'Actualizar Información',
                        icon: Icons.save_rounded,
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
