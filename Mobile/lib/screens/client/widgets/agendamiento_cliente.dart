import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';

class ScheduleTab extends StatelessWidget {
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
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.event_available_rounded,
            title: 'Proxima cita',
          ),
          const SizedBox(height: 18),
          const InfoLine(label: 'Fecha', value: 'Viernes 14 Jun - 9:30 AM'),
          const SizedBox(height: 12),
          const InfoLine(label: 'Vehiculo', value: 'Toyota Corolla 2020'),
          const SizedBox(height: 12),
          const InfoLine(label: 'Servicio', value: 'Revision preventiva'),
          const SizedBox(height: 18),
          const StatusChip(text: 'Confirmada', color: AppTheme.green),
        ],
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
