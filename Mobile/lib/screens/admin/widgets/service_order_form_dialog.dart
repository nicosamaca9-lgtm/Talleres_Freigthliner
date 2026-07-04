import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/booking_model.dart';
import '../../../providers/admin_provider.dart';

class ServiceOrderFormDialog extends StatefulWidget {
  final BookingModel? booking;

  const ServiceOrderFormDialog({super.key, this.booking});

  @override
  State<ServiceOrderFormDialog> createState() => _ServiceOrderFormDialogState();
}

class _ServiceOrderFormDialogState extends State<ServiceOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();

  bool _hasBooking = false;
  BookingModel? _selectedBooking;
  List<BookingModel> _confirmedBookings = [];

  final _placaController = TextEditingController();
  int? _foundVehicleId;
  bool _vehicleNotFound = false;

  final _clienteNombreController = TextEditingController();
  final _clienteDocController = TextEditingController();
  final _clienteTelController = TextEditingController();
  
  final _conductorNombreController = TextEditingController();
  final _conductorTelController = TextEditingController();

  final _kilometrajeController = TextEditingController();
  final _combustibleController = TextEditingController(text: '1/2');
  final _trabajosController = TextEditingController();

  bool _isSubmitting = false;
  bool _isSearchingVehicle = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _hasBooking = true;
      _selectedBooking = widget.booking;
      _fillFromBooking(_selectedBooking!);
    } else {
      _hasBooking = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allBookings = context.read<AdminProvider>().allBookings;
      setState(() {
        _confirmedBookings = allBookings.where((b) => b.estadoConfirmacion == 'CONFIRMADO').toList();
        if (_hasBooking && _selectedBooking != null && !_confirmedBookings.any((b) => b.idAgendamiento == _selectedBooking!.idAgendamiento)) {
          _confirmedBookings.add(_selectedBooking!);
        }
      });
    });
  }

  void _fillFromBooking(BookingModel booking) {
    _foundVehicleId = booking.idVehiculo;
    _trabajosController.text = booking.observaciones ?? 'Revisión General';
    if (booking.placaVehiculo != null) {
      _placaController.text = booking.placaVehiculo!;
      _vehicleNotFound = false; // Asumimos que si viene de cita ya está registrado (o se registró)
    }
    if (booking.clienteNombre != null) {
      _clienteNombreController.text = booking.clienteNombre!;
    }
    if (booking.clienteTelefono != null) {
      _clienteTelController.text = booking.clienteTelefono!;
    }
    if (booking.clienteCedula != null) {
      _clienteDocController.text = booking.clienteCedula!;
    }
  }

  @override
  void dispose() {
    _placaController.dispose();
    _clienteNombreController.dispose();
    _clienteDocController.dispose();
    _clienteTelController.dispose();
    _conductorNombreController.dispose();
    _conductorTelController.dispose();
    _kilometrajeController.dispose();
    _combustibleController.dispose();
    _trabajosController.dispose();
    super.dispose();
  }

  Future<void> _searchVehicle() async {
    final placa = _placaController.text.trim().toUpperCase();
    if (placa.isEmpty) return;

    setState(() {
      _isSearchingVehicle = true;
      _foundVehicleId = null;
      _vehicleNotFound = false;
    });

    try {
      final vehicleData = await context.read<AdminProvider>().findVehicleByPlate(placa);
      setState(() {
        _foundVehicleId = vehicleData['id_vehiculo'];
        _vehicleNotFound = false;
        if (vehicleData['propietario_nombre'] != null) {
          _clienteNombreController.text = vehicleData['propietario_nombre'].toString();
        }
        if (vehicleData['propietario_cedula'] != null) {
          _clienteDocController.text = vehicleData['propietario_cedula'].toString();
        }
        if (vehicleData['propietario_telefono'] != null) {
          _clienteTelController.text = vehicleData['propietario_telefono'].toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo y propietario encontrados.'), backgroundColor: AppTheme.green),
        );
      });
    } catch (e) {
      // Vehículo no registrado — permitir continuar con datos manuales
      setState(() {
        _foundVehicleId = null;
        _vehicleNotFound = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo no registrado en el sistema. Ingresa los datos del cliente manualmente.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingVehicle = false;
        });
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final placa = _placaController.text.trim().toUpperCase();
    if (placa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes ingresar la placa del vehículo')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final data = {
        // Si el vehículo fue encontrado, enviamos el id; si no, enviamos la placa para que el backend lo cree
        if (_foundVehicleId != null) 'id_vehiculo': _foundVehicleId
        else 'placa_vehiculo_nuevo': placa,
        'id_agendamiento': _hasBooking && _selectedBooking != null ? _selectedBooking!.idAgendamiento : null,
        'fecha_ingreso': DateFormat('yyyy-MM-dd').format(now),
        'hora_ingreso': DateFormat('HH:mm:ss').format(now),
        'cliente_nombre': _clienteNombreController.text,
        'cliente_identificacion': _clienteDocController.text,
        'cliente_telefono': _clienteTelController.text,
        'conductor_nombre': _conductorNombreController.text.isNotEmpty ? _conductorNombreController.text : null,
        'conductor_telefono': _conductorTelController.text.isNotEmpty ? _conductorTelController.text : null,
        'kilometraje_ingreso': int.tryParse(_kilometrajeController.text) ?? 0,
        'nivel_combustible': _combustibleController.text,
        'trabajos_a_realizar': _trabajosController.text,
        'estado_orden': 'EN_DIAGNOSTICO',
      };

      await context.read<AdminProvider>().createServiceOrder(data);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden de Servicio generada y vehículo ingresado a taller.'),
            backgroundColor: AppTheme.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF101010),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generar Orden de Servicio', style: GoogleFonts.rajdhani(color: AppTheme.green, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF242424)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Buscador de Placa SIEMPRE visible
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _placaController,
                              label: 'Placa del Vehículo',
                              icon: Icons.numbers,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _isSearchingVehicle ? null : _searchVehicle,
                            child: _isSearchingVehicle
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.search, color: Colors.white),
                          ),
                        ],
                      ),
                      if (_foundVehicleId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                          child: Text('✅ Vehículo registrado. Datos del propietario cargados.', style: const TextStyle(color: AppTheme.green, fontSize: 12)),
                        ),
                      if (_vehicleNotFound)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                          child: Text('⚠️ Vehículo no registrado. Completa los datos del cliente manualmente.', style: TextStyle(color: Colors.orange.shade300, fontSize: 12)),
                        ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text('¿Vincular con cita agendada?', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
                        value: _hasBooking,
                        activeColor: AppTheme.green,
                        onChanged: widget.booking != null ? null : (val) {
                          setState(() {
                            _hasBooking = val;
                          });
                        },
                      ),
                      if (_hasBooking) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<BookingModel>(
                          value: _selectedBooking,
                          dropdownColor: const Color(0xFF151515),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Cita Confirmada',
                            border: OutlineInputBorder(),
                          ),
                          items: _confirmedBookings.map((b) {
                            final primerNombre = (b.clienteNombre ?? 'ID ' + b.idUsuario.toString()).split(' ').first;
                            final placa = b.placaVehiculo ?? b.idVehiculo.toString();
                            return DropdownMenuItem(
                              value: b,
                              child: Text('${DateFormat('dd/MM').format(b.fechaCita)} - $primerNombre - $placa'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedBooking = val;
                                _fillFromBooking(val);
                              });
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF242424), height: 32),
                
                Text('Datos del Cliente', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTextField(controller: _clienteNombreController, label: 'Nombre Cliente', icon: Icons.person, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _clienteDocController, label: 'Cédula/NIT', icon: Icons.badge)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _clienteTelController, label: 'Teléfono (10 dígitos)', icon: Icons.phone, keyboardType: TextInputType.phone, validator: (v) {
                      if (v == null || v.isEmpty) return null; // opcional
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length != 10) return '10 dígitos requeridos';
                      return null;
                    })),
                  ],
                ),
                
                const Divider(color: Color(0xFF242424), height: 32),
                
                Text('Datos del Ingreso', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _kilometrajeController, label: 'Kilometraje', icon: Icons.speed_rounded, keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _combustibleController, label: 'Combustible', icon: Icons.local_gas_station_rounded, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(controller: _trabajosController, label: 'Diagnóstico o Trabajos a Realizar', icon: Icons.build_rounded, maxLines: 3, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                const Divider(color: Color(0xFF242424), height: 32),

                Text('Conductor (Opcional)', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTextField(controller: _conductorNombreController, label: 'Nombre del Conductor', icon: Icons.person_outline),
                const SizedBox(height: 12),
                _buildTextField(controller: _conductorTelController, label: 'Teléfono del Conductor', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF333333)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Crear Orden', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon, color: AppTheme.textDim, size: 20) : null,
        alignLabelWithHint: maxLines > 1,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
