import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/vehicle_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/ui_components.dart'; // ActionButton, CustomTextField si existen

class VehicleRegistrationDialog extends StatefulWidget {
  const VehicleRegistrationDialog({super.key});

  @override
  State<VehicleRegistrationDialog> createState() => _VehicleRegistrationDialogState();
}

class _VehicleRegistrationDialogState extends State<VehicleRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  String? _selectedTipoVehiculo;

  final List<String> _tipos = [
    'Camion',
    'Volqueta',
    'Patineta',
    'Mula',
    'Bus',
    'Otro'
  ];

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedTipoVehiculo != null) {
      final provider = Provider.of<VehicleProvider>(context, listen: false);
      final data = {
        'placa': _placaController.text.trim(),
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'tipo_vehiculo': _selectedTipoVehiculo,
      };

      try {
        await provider.registerVehicle(data);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.red,
            ),
          );
        }
      }
    } else if (_selectedTipoVehiculo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un tipo de vehiculo'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<VehicleProvider>().isLoading;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registrar Vehiculo',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.text,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _placaController,
                style: GoogleFonts.dmSans(color: AppTheme.text),
                decoration: _inputDecoration('Placa'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marcaController,
                style: GoogleFonts.dmSans(color: AppTheme.text),
                decoration: _inputDecoration('Marca'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modeloController,
                style: GoogleFonts.dmSans(color: AppTheme.text),
                decoration: _inputDecoration('Modelo (Año)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTipoVehiculo,
                style: GoogleFonts.dmSans(color: AppTheme.text),
                dropdownColor: const Color(0xFF242424),
                decoration: _inputDecoration('Tipo de Vehiculo'),
                items: _tipos.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTipoVehiculo = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.green))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.dmSans(color: AppTheme.textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.green,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Guardar',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(color: AppTheme.textMuted),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF333333)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppTheme.green),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: const Color(0xFF242424),
    );
  }
}
