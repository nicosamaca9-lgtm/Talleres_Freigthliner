import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../models/booking_model.dart';
import '../../../repositories/booking_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';

class AgendamientoCliente extends StatelessWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      key: ValueKey('schedule'),
      title: 'Agendamiento',
      icon: Icons.calendar_month_rounded,
      children: [
        _ScheduleHeroCard(),
        ResponsiveCards(
          left: _AppointmentCard(),
          right: _ServicePickerCard(),
        ),
      ],
    );
  }
}

class _ScheduleHeroCard extends StatelessWidget {
  const _ScheduleHeroCard();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.greenBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderGreen),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.green,
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agenda tu proximo servicio',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecciona fecha, vehiculo y tipo de mantenimiento.',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const ActionButton(
            label: 'Nueva cita',
            icon: Icons.add_rounded,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard();

  @override
  Widget build(BuildContext context) {
    final bookingRepo = BookingRepository();

    return DashboardCard(
      child: FutureBuilder<BookingModel?>(
        future: bookingRepo.getLatestBooking(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppTheme.green),
              ),
            );
          }

          final booking = snapshot.data;

          if (booking == null) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitle(
                  icon: Icons.event_available_rounded,
                  title: 'Proxima cita',
                ),
                SizedBox(height: 18),
                Text('No tienes citas agendadas.', style: TextStyle(color: Colors.white70)),
              ],
            );
          }

          // Mapeo dinámico de colores de estado según tu backend
          Color statusColor = AppTheme.amber;
          if (booking.estadoConfirmacion == 'CONFIRMADO') statusColor = AppTheme.green;
          if (booking.estadoConfirmacion == 'CANCELADO') statusColor = Colors.redAccent;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                icon: Icons.event_available_rounded,
                title: 'Proxima cita',
              ),
              const SizedBox(height: 18),
              InfoLine(label: 'Fecha', value: '${booking.fechaCita} - ${booking.horaCita}'),
              const SizedBox(height: 12),
              InfoLine(label: 'Vehiculo ID', value: 'ID: ${booking.idVehiculo}'), 
              const SizedBox(height: 12),
              InfoLine(label: 'Detalles', value: booking.observaciones ?? 'Sin observaciones'),
              const SizedBox(height: 18),
              StatusChip(text: booking.estadoConfirmacion, color: statusColor),
            ],
          );
        },
      ),
    );
  }
}

class _ServicePickerCard extends StatelessWidget {
  const _ServicePickerCard();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.build_circle_outlined,
            title: 'Servicios frecuentes',
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusChip(text: 'Cambio de aceite', color: AppTheme.green),
              StatusChip(text: 'Frenos', color: AppTheme.amber),
              StatusChip(text: 'Suspension', color: AppTheme.blue),
              StatusChip(text: 'Diagnostico', color: AppTheme.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
