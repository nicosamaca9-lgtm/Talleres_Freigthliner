import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/booking_model.dart';
import '../../../models/service_order_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';
import 'booking_registration_dialog.dart';
import 'booking_reschedule_dialog.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<BookingProvider>().loadDashboardData(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Center(
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
                    'Agendamiento',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _ScheduleHeroCard(),
              const SizedBox(height: 20),
              const _MyBookingsList(),
              const SizedBox(height: 20),
              const _ActiveOrdersList(),
              const SizedBox(height: 20),
              const _ServicePickerCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HERO CARD ────────────────────────────────────────────────────────────────

class _ScheduleHeroCard extends StatelessWidget {
  const _ScheduleHeroCard();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.greenBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGreen),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.green,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
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
                      'Selecciona fecha, vehiculo y observaciones.',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: 'Nueva cita',
              icon: Icons.add_rounded,
              isPrimary: true,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const BookingRegistrationDialog(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MIS CITAS PROGRAMADAS ───────────────────────────────────────────────────

class _MyBookingsList extends StatelessWidget {
  const _MyBookingsList();

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const DashboardCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppTheme.green),
              ),
            ),
          );
        }

        final allBookings = provider.myBookings;
        final now = DateTime.now();
        final bookings = allBookings.where((b) {
          if (b.estadoConfirmacion == 'EN_TALLER' || b.estadoConfirmacion == 'CANCELADO_POR_SISTEMA') return false;
          // Filtrar citas vencidas (hace más de 6 horas)
          if (b.fechaHoraCita.isBefore(now.subtract(const Duration(hours: 6)))) return false;
          return true;
        }).toList();

        if (bookings.isEmpty) {
          return DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle(
                  icon: Icons.event_available_rounded,
                  title: 'Mis Citas Programadas',
                ),
                const SizedBox(height: 18),
                Text(
                  'No tienes citas agendadas.',
                  style: GoogleFonts.dmSans(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                icon: Icons.event_available_rounded,
                title: 'Mis Citas Programadas',
              ),
              const SizedBox(height: 18),
              ...bookings.map((booking) => _BookingTile(booking: booking)),
            ],
          ),
        );
      },
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingModel booking;
  const _BookingTile({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMADO':
        return AppTheme.green;
      case 'CANCELADO':
      case 'RECHAZADO':
        return Colors.redAccent;
      default:
        return AppTheme.amber;
    }
  }

  void _showFriendlyError(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.amber, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aviso Importante',
                style: GoogleFonts.rajdhani(color: AppTheme.text, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          error.contains('3 horas') || error.contains('anticipación') || error.contains('anticipacion') || error.contains('contamos con usted')
              ? 'Lo sentimos, ya contamos contigo para este espacio y no es posible reprogramar o cancelar con menos de 3 horas de anticipación.\n\n¡Agradecemos mucho tu comprensión!'
              : error,
          style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 15),
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

  Future<void> _confirmCancel(BuildContext context) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    // Capturar referencias ANTES de cualquier await para evitar context desmontado
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final bookingProvider = context.read<BookingProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Cancelar esta cita?',
          style: GoogleFonts.rajdhani(color: AppTheme.text, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Esta acción no se puede deshacer. La cita del ${booking.fechaCita} a las ${booking.horaCita} será cancelada.',
          style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('No, volver', style: GoogleFonts.dmSans(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sí, cancelar', style: GoogleFonts.dmSans(color: AppTheme.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await bookingProvider.cancelBooking(
      booking.idAgendamiento,
      userId,
    );

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Cita cancelada con éxito'), backgroundColor: AppTheme.green),
      );
    } else {
      final error = bookingProvider.error ?? 'Error inesperado';
      // Mostrar diálogo amigable usando el navigator capturado
      navigator.push(
        DialogRoute(
          context: navigator.context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF171717),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.amber, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aviso Importante',
                    style: GoogleFonts.rajdhani(color: AppTheme.text, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              error.contains('3 horas') || error.contains('anticipación') || error.contains('anticipacion') || error.contains('contamos con usted')
                  ? 'Lo sentimos, ya contamos contigo para este espacio y no es posible cancelar con menos de 3 horas de anticipación.\n\n¡Agradecemos mucho tu comprensión!'
                  : error,
              style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Entendido', style: GoogleFonts.dmSans(color: AppTheme.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_filled_rounded, color: AppTheme.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Consumer<VehicleProvider>(
                  builder: (context, vehicleProvider, _) {
                    final vehiculo = vehicleProvider.vehicles.firstWhere(
                      (v) => v.idVehiculo == booking.idVehiculo,
                      orElse: () => VehicleModel(idVehiculo: booking.idVehiculo, placa: 'ID: ${booking.idVehiculo}', marca: '', modelo: '', tipoVehiculo: ''),
                    );
                    return Text(
                      'Vehículo: ${vehiculo.placa}',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              StatusChip(text: booking.estadoConfirmacion, color: _statusColor(booking.estadoConfirmacion)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.textDim, size: 16),
              const SizedBox(width: 6),
              Text(
                '${booking.fechaCita.toIso8601String().split('T').first}  •  ${booking.horaCita}',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
          if (booking.observaciones != null && booking.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note_alt_outlined, color: AppTheme.textDim, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.observaciones!,
                    style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (booking.motivoRechazo != null && booking.motivoRechazo!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motivo de rechazo:',
                          style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.motivoRechazo!,
                          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ActionButton(
                label: 'Reprogramar',
                icon: Icons.edit_calendar_rounded,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BookingRescheduleDialog(booking: booking),
                  );
                },
              ),
              const SizedBox(width: 10),
              ActionButton(
                label: 'Cancelar',
                icon: Icons.cancel_outlined,
                isDanger: true,
                onPressed: () => _confirmCancel(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── VEHÍCULOS EN TALLER ─────────────────────────────────────────────────────

class _ActiveOrdersList extends StatelessWidget {
  const _ActiveOrdersList();

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'EN_DIAGNOSTICO':
        return AppTheme.amber;
      case 'EN_REPARACION':
        return AppTheme.blue;
      case 'LISTO_PARA_ENTREGA':
        return AppTheme.green;
      default:
        return AppTheme.textMuted;
    }
  }

  String _orderStatusLabel(String status) {
    switch (status) {
      case 'EN_DIAGNOSTICO':
        return 'En Diagnóstico';
      case 'EN_REPARACION':
        return 'En Reparación';
      case 'LISTO_PARA_ENTREGA':
        return 'Listo para Entrega';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        final orders = provider.myActiveOrders;

        if (orders.isEmpty) {
          return DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle(
                  icon: Icons.build_circle_rounded,
                  title: 'Vehículos en Taller',
                ),
                const SizedBox(height: 18),
                Text(
                  'Ninguno de tus vehículos se encuentra actualmente en el taller.',
                  style: GoogleFonts.dmSans(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                icon: Icons.build_circle_rounded,
                title: 'Vehículos en Taller',
              ),
              const SizedBox(height: 18),
              ...orders.map((order) => _ActiveOrderTile(
                order: order,
                statusColor: _orderStatusColor(order.estadoOrden),
                statusLabel: _orderStatusLabel(order.estadoOrden),
              )),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveOrderTile extends StatelessWidget {
  final ServiceOrderModel order;
  final Color statusColor;
  final String statusLabel;

  const _ActiveOrderTile({
    required this.order,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Consumer<VehicleProvider>(
                  builder: (context, vehicleProvider, _) {
                    final vehiculo = vehicleProvider.vehicles.firstWhere(
                      (v) => v.idVehiculo == order.idVehiculo,
                      orElse: () => VehicleModel(idVehiculo: order.idVehiculo, placa: 'ID: ${order.idVehiculo}', marca: '', modelo: '', tipoVehiculo: ''),
                    );
                    return Text(
                      'Vehículo: ${vehiculo.placa}',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              StatusChip(text: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.textDim, size: 16),
              const SizedBox(width: 6),
              Text(
                'Ingreso: ${order.fechaIngreso}  •  ${order.horaIngreso}',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.handyman_rounded, color: AppTheme.textDim, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.trabajosARealizar,
                  style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── SERVICIOS FRECUENTES ────────────────────────────────────────────────────

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
              StatusChip(text: 'Escaneada y diagnostico', color: AppTheme.blue),
              StatusChip(text: 'Cambio de empaques multiple', color: AppTheme.amber),
              StatusChip(text: 'Reparacion de motor', color: AppTheme.red),
              StatusChip(text: 'Cambio bomba de agua', color: AppTheme.textMuted),
              StatusChip(text: 'Cambio empaques enfriador de aceite', color: AppTheme.amber),
              StatusChip(text: 'Electricidad general del vehiculo', color: AppTheme.blue),
              StatusChip(text: 'Parcial motor', color: AppTheme.red),
              StatusChip(text: 'Arreglo modulos', color: AppTheme.blue),
              StatusChip(text: 'Reprogramacion de modulos', color: AppTheme.amber),
              StatusChip(text: 'Eliminacion de urea', color: AppTheme.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
