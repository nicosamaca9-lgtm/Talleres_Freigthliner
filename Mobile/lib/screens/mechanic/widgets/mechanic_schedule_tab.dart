import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/mechanic_provider.dart';

class MechanicScheduleTab extends StatelessWidget {
  const MechanicScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppTheme.green, size: 21),
                  const SizedBox(width: 10),
                  Text(
                    'Mi Agenda',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Aquí usarías ListView.builder para mostrar la agenda.
              Consumer<MechanicProvider>(
                builder: (context, provider, child) {
                  final orders = provider.assignedOrders;
                  if (orders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text('No tienes órdenes agendadas.', style: TextStyle(color: Colors.white70)),
                    );
                  }

                  return Column(
                    children: orders.map((order) {
                      final dateParts = order.fechaIngreso.split('-');
                      String day = '00';
                      String monthStr = '00';
                      if (dateParts.length >= 3) {
                        day = dateParts[2];
                        monthStr = dateParts[1];
                      }

                      String month = '';
                      switch (monthStr) {
                        case '01': month = 'ENE'; break;
                        case '02': month = 'FEB'; break;
                        case '03': month = 'MAR'; break;
                        case '04': month = 'ABR'; break;
                        case '05': month = 'MAY'; break;
                        case '06': month = 'JUN'; break;
                        case '07': month = 'JUL'; break;
                        case '08': month = 'AGO'; break;
                        case '09': month = 'SEP'; break;
                        case '10': month = 'OCT'; break;
                        case '11': month = 'NOV'; break;
                        case '12': month = 'DIC'; break;
                        default: month = 'MES';
                      }

                      final time = order.horaIngreso.isNotEmpty ? order.horaIngreso : '--:--';
                      
                      return _ScheduleItemCard(
                        day: day,
                        month: month,
                        time: time,
                        service: order.trabajosARealizar,
                        vehicle: 'Placa: ${order.placaVehiculo ?? 'N/A'}',
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleItemCard extends StatelessWidget {
  const _ScheduleItemCard({
    required this.day,
    required this.month,
    required this.time,
    required this.service,
    required this.vehicle,
  });

  final String day;
  final String month;
  final String time;
  final String service;
  final String vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262626), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF262626)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.green,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  month,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$time - $service',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
