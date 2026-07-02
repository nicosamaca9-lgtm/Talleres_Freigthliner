import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../providers/booking_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/booking_model.dart';
import '../../../../models/vehicle_model.dart';
import '../../../../providers/vehicle_provider.dart';

class BookingRescheduleDialog extends StatefulWidget {
  final BookingModel booking;
  const BookingRescheduleDialog({super.key, required this.booking});

  @override
  State<BookingRescheduleDialog> createState() => _BookingRescheduleDialogState();
}

class _BookingRescheduleDialogState extends State<BookingRescheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late TextEditingController _observacionesController;
  
  @override
  void initState() {
    super.initState();
    try {
      _selectedDate = widget.booking.fechaCita;
      final parts = widget.booking.horaCita.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      // Ignorar si hay error de formato inicial
    }
    _observacionesController = TextEditingController(text: widget.booking.observaciones ?? '');
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.green,
              onPrimary: AppTheme.bg,
              surface: Color(0xFF171717),
              onSurface: AppTheme.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.green,
              onPrimary: AppTheme.bg,
              surface: Color(0xFF171717),
              onSurface: AppTheme.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar fecha y hora.')),
      );
      return;
    }

    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final hour = _selectedTime!.hour.toString().padLeft(2, '0');
    final minute = _selectedTime!.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute:00';

    final success = await context.read<BookingProvider>().updateBooking(
      idUsuario: userId,
      idAgendamiento: widget.booking.idAgendamiento,
      fechaCita: dateStr,
      horaCita: timeStr,
      observaciones: _observacionesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita reprogramada con éxito'),
          backgroundColor: AppTheme.green,
        ),
      );
    } else {
      final error = context.read<BookingProvider>().error ?? 'Ocurrió un error inesperado';
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.amber, size: 28),
              const SizedBox(width: 10),
              Text(
                'No se pudo reprogramar',
                style: GoogleFonts.rajdhani(color: AppTheme.text, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Text(
            error,
            style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido', style: GoogleFonts.dmSans(color: AppTheme.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF171717),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reprogramar Cita',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Consumer<VehicleProvider>(
                  builder: (context, vehicleProvider, _) {
                    final vehiculo = vehicleProvider.vehicles.firstWhere(
                      (v) => v.idVehiculo == widget.booking.idVehiculo,
                      orElse: () => VehicleModel(idVehiculo: widget.booking.idVehiculo, placa: 'ID: ${widget.booking.idVehiculo}', marca: '', modelo: '', tipoVehiculo: ''),
                    );
                    return Text(
                      'Vehículo: ${vehiculo.placa}',
                      style: GoogleFonts.dmSans(color: AppTheme.textDim, fontSize: 14),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 18),
                        label: Text(
                          _selectedDate == null 
                            ? 'Fecha' 
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: GoogleFonts.dmSans(color: AppTheme.text),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF2A2A2A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: const Color(0xFF0A0A0A),
                        ),
                        onPressed: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, color: AppTheme.textMuted, size: 18),
                        label: Text(
                          _selectedTime == null 
                            ? 'Hora' 
                            : _selectedTime!.format(context),
                          style: GoogleFonts.dmSans(color: AppTheme.text),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF2A2A2A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: const Color(0xFF0A0A0A),
                        ),
                        onPressed: _pickTime,
                      ),
                    ),
                  ],
                ),
                if (_selectedDate == null || _selectedTime == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Requeridos',
                      style: GoogleFonts.dmSans(color: AppTheme.red, fontSize: 12),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _observacionesController,
                  style: GoogleFonts.dmSans(color: AppTheme.text),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observaciones / Falla del vehículo',
                    alignLabelWithHint: true,
                    labelStyle: GoogleFonts.dmSans(color: AppTheme.textDim),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0A),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.green),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: Consumer<BookingProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppTheme.green),
                        );
                      }
                      return ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          foregroundColor: AppTheme.bg,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Guardar Cambios',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
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
