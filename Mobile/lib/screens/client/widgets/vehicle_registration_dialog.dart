import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/vehicle_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
        'placa': _placaController.text.trim().toUpperCase(),
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'tipo_vehiculo': _selectedTipoVehiculo,
      };

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          title: Text('Confirmar', style: GoogleFonts.rajdhani(color: AppTheme.textColor(context), fontWeight: FontWeight.bold, fontSize: 20)),
          content: Text('¿Estás seguro de registrar el vehículo con la placa ${data['placa']}?', style: GoogleFonts.dmSans(color: AppTheme.textMutedColor(context), fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: GoogleFonts.dmSans(color: AppTheme.textMutedColor(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Confirmar', style: GoogleFonts.dmSans(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await provider.registerVehicle(data);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          var errorMsg = e.toString();
          // Limpiar todo tipo de prefijo técnico del error
          errorMsg = errorMsg.replaceAll(RegExp(r'Exception:\s*'), '');
          errorMsg = errorMsg.replaceAll(RegExp(r'DioException.*detail:\s*'), '');
          errorMsg = errorMsg.trim();
          if (errorMsg.isEmpty) errorMsg = 'Este vehículo ya se encuentra registrado en otra cuenta.';
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.cardColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.amber, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vehículo ya registrado',
                      style: GoogleFonts.rajdhani(color: AppTheme.textColor(context), fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ],
              ),
              content: Text(
                errorMsg,
                style: GoogleFonts.dmSans(color: AppTheme.textMutedColor(context), fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Entendido', style: GoogleFonts.dmSans(color: AppTheme.green, fontWeight: FontWeight.bold)),
                ),
              ],
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
      backgroundColor: AppTheme.cardColor(context),
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
                  color: AppTheme.textColor(context),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _placaController,
                style: GoogleFonts.dmSans(color: AppTheme.textColor(context)),
                decoration: _inputDecoration('Placa'),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) => newValue.copyWith(
                      text: newValue.text.toUpperCase(),
                    ),
                  ),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (!RegExp(r'^[A-Z]{3}\d{3}$').hasMatch(value)) {
                    return 'Formato inválido (Ej: ABC123)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marcaController,
                style: GoogleFonts.dmSans(color: AppTheme.textColor(context)),
                decoration: _inputDecoration('Marca'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modeloController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.dmSans(color: AppTheme.textColor(context)),
                decoration: _inputDecoration('Modelo (Año)'),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  final year = int.tryParse(value);
                  if (year == null) return 'Año inválido';
                  final currentYear = DateTime.now().year;
                  if (year < 1970 || year > (currentYear + 2)) {
                    return 'Año debe ser entre 1970 y ${currentYear + 2}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedTipoVehiculo,
                style: GoogleFonts.dmSans(color: AppTheme.textColor(context)),
                dropdownColor: AppTheme.inputColor(context),
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
                            style: GoogleFonts.dmSans(color: AppTheme.textMutedColor(context)),
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
      labelStyle: GoogleFonts.dmSans(color: AppTheme.textMutedColor(context)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppTheme.green),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: AppTheme.inputColor(context),
    );
  }
}
