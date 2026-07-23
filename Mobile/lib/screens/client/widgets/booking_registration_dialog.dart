import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../providers/booking_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/vehicle_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/booking/booking_time_validator.dart';
import '../../../../models/vehicle_model.dart';

class BookingRegistrationDialog extends StatefulWidget {
  const BookingRegistrationDialog({super.key});

  @override
  State<BookingRegistrationDialog> createState() =>
      _BookingRegistrationDialogState();
}

class _BookingRegistrationDialogState extends State<BookingRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  VehicleModel? _selectedVehicle;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<VehicleProvider>().loadMyVehicles(userId);
      }
    });
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
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.green,
              onPrimary: AppTheme.bg,
              surface: AppTheme.cardColor(context),
              onSurface: AppTheme.textColor(context),
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
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.green,
              onPrimary: AppTheme.bg,
              surface: AppTheme.cardColor(context),
              onSurface: AppTheme.textColor(context),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicle == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un vehículo'),
          backgroundColor: AppTheme.red,
        ),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona fecha y hora'),
          backgroundColor: AppTheme.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final bookingTimeError = BookingTimeValidator.validate(
      date: _selectedDate!,
      time: _selectedTime!,
      now: now,
    );
    if (bookingTimeError != null) {
      if (bookingTimeError == BookingTimeValidator.businessHoursMessage) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Horario no válido',
              style: GoogleFonts.rajdhani(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              bookingTimeError,
              style: GoogleFonts.dmSans(
                color: AppTheme.textMutedColor(context),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Entendido',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(bookingTimeError),
            backgroundColor: AppTheme.red,
          ),
        );
      }
      return;
    }

    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final dateSolStr = DateFormat('yyyy-MM-dd').format(now);

    // Formato de hora HH:mm:ss
    final hourStr = _selectedTime!.hour.toString().padLeft(2, '0');
    final minute = _selectedTime!.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minute:00';

    final success = await context.read<BookingProvider>().createBooking(
      idUsuario: userId,
      idVehiculo: _selectedVehicle!.idVehiculo,
      fechaSolicitud: dateSolStr,
      fechaCita: dateStr,
      horaCita: timeStr,
      observaciones: _observacionesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita agendada con éxito'),
          backgroundColor: AppTheme.green,
        ),
      );
    } else {
      final error =
          context.read<BookingProvider>().error ??
          'Ocurrió un error inesperado';

      // Mostrar pantallazo amigable en lugar de un simple error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppTheme.amber,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Aviso Importante',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            error.contains('capacidad máxima') ||
                    error.contains('Límite diario')
                ? 'El taller está bastante concurrido en este momento y hemos alcanzado la capacidad máxima de vehículos. Por favor, intenta agendar tu cita para el próximo día.\n\n¡Agradecemos mucho tu comprensión!'
                : error,
            style: GoogleFonts.dmSans(
              color: AppTheme.textMutedColor(context),
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
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
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Dialog(
            backgroundColor: AppTheme.cardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.borderColor(context)),
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
                            'Agendar Cita',
                            style: GoogleFonts.dmSans(
                              color: AppTheme.textColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: AppTheme.textMutedColor(context),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Selector de vehículo
                      Consumer<VehicleProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.green,
                              ),
                            );
                          }
                          if (provider.vehicles.isEmpty) {
                            return Text(
                              'No tienes vehículos registrados. Agrega uno primero.',
                              style: GoogleFonts.dmSans(color: AppTheme.red),
                            );
                          }
                          return DropdownButtonFormField<VehicleModel>(
                            value: _selectedVehicle,
                            style: GoogleFonts.dmSans(
                              color: AppTheme.textColor(context),
                            ),
                            dropdownColor: AppTheme.inputColor(context),
                            decoration: InputDecoration(
                              labelText: 'Vehículo',
                              labelStyle: GoogleFonts.dmSans(
                                color: AppTheme.textMutedColor(context),
                              ),
                              filled: true,
                              fillColor: AppTheme.inputColor(context),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor(context),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.green,
                                ),
                              ),
                            ),
                            items: provider.vehicles.map((v) {
                              return DropdownMenuItem(
                                value: v,
                                child: Text(
                                  '${v.placa} - ${v.marca} ${v.modelo}',
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedVehicle = val;
                              });
                            },
                            validator: (val) =>
                                val == null ? 'Selecciona un vehículo' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Fila con fecha y hora
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(
                                Icons.calendar_today,
                                color: AppTheme.textMutedColor(context),
                                size: 18,
                              ),
                              label: Text(
                                _selectedDate == null
                                    ? 'Fecha'
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_selectedDate!),
                                style: GoogleFonts.dmSans(
                                  color: AppTheme.textColor(context),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: AppTheme.borderColor(context),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: AppTheme.inputColor(context),
                              ),
                              onPressed: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(
                                Icons.access_time,
                                color: AppTheme.textMutedColor(context),
                                size: 18,
                              ),
                              label: Text(
                                _selectedTime == null
                                    ? 'Hora'
                                    : _selectedTime!.format(context),
                                style: GoogleFonts.dmSans(
                                  color: AppTheme.textColor(context),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: AppTheme.borderColor(context),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: AppTheme.inputColor(context),
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
                            style: GoogleFonts.dmSans(
                              color: AppTheme.red,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Observaciones
                      TextFormField(
                        controller: _observacionesController,
                        style: GoogleFonts.dmSans(
                          color: AppTheme.textColor(context),
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Observaciones / Falla del vehículo',
                          alignLabelWithHint: true,
                          labelStyle: GoogleFonts.dmSans(
                            color: AppTheme.textMutedColor(context),
                          ),
                          filled: true,
                          fillColor: AppTheme.inputColor(context),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.borderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.green),
                          ),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Requerido' : null,
                      ),

                      const SizedBox(height: 16),

                      // Advertencia de las 3 horas
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.amber.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Nota: No podrás reprogramar ni cancelar tu cita si faltan menos de 3 horas para la misma.',
                                style: GoogleFonts.dmSans(
                                  color: AppTheme.amber,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botón Enviar
                      SizedBox(
                        width: double.infinity,
                        child: Consumer<BookingProvider>(
                          builder: (context, provider, child) {
                            if (provider.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.green,
                                ),
                              );
                            }
                            return ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.green,
                                foregroundColor: AppTheme.bg,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Agendar Cita',
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
          ),
        ),
      ),
    );
  }
}
