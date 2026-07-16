import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/booking_model.dart';

class AdminBookingsTab extends StatefulWidget {
  const AdminBookingsTab({super.key});

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.allBookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final pending = provider.allBookings.where((b) => b.estadoConfirmacion == 'PENDIENTE').toList();
        final confirmed = provider.allBookings.where((b) => b.estadoConfirmacion == 'CONFIRMADO').toList();
        final rejected = provider.allBookings.where((b) => b.estadoConfirmacion == 'RECHAZADO' || b.estadoConfirmacion == 'CANCELADO').toList();

        return RefreshIndicator(
          onRefresh: provider.fetchAllBookings,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Citas Pendientes', Icons.access_time, Colors.orange),
              if (pending.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No hay citas pendientes', style: TextStyle(color: AppTheme.textMutedColor(context))),
                )
              else
                ...pending.map((b) => _buildBookingCard(context, b, true)),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Citas Confirmadas', Icons.check_circle, Colors.green),
              if (confirmed.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No hay citas confirmadas', style: TextStyle(color: AppTheme.textMutedColor(context))),
                )
              else
                ...confirmed.map((b) => _buildBookingCard(context, b, false)),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Citas Rechazadas / Canceladas', Icons.cancel, AppTheme.errorColor),
              if (rejected.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No hay citas rechazadas', style: TextStyle(color: AppTheme.textMutedColor(context))),
                )
              else
                ...rejected.map((b) => _buildBookingCard(context, b, false)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking, bool isPending) {
    Color statusColor = Colors.grey;
    if (booking.estadoConfirmacion == 'PENDIENTE') statusColor = AppTheme.amber;
    if (booking.estadoConfirmacion == 'CONFIRMADO') statusColor = AppTheme.green;
    if (booking.estadoConfirmacion == 'RECHAZADO' || booking.estadoConfirmacion == 'CANCELADO') statusColor = AppTheme.red;

    return Card(
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cita #${booking.idAgendamiento}',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    booking.estadoConfirmacion,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (booking.clienteNombre != null)
              _buildInfoRow(Icons.person, 'Cliente', booking.clienteNombre!),
            if (booking.placaVehiculo != null)
              _buildInfoRow(Icons.directions_car, 'Placa', booking.placaVehiculo!),
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha',
              DateFormat('dd/MM/yyyy').format(booking.fechaCita),
            ),
            _buildInfoRow(
              Icons.access_time,
              'Hora',
              booking.horaCita,
            ),
            _buildInfoRow(
              Icons.build,
              'Tipo de Servicio',
              booking.tipoServicio,
            ),
            if (booking.notasAdicionales != null && booking.notasAdicionales!.isNotEmpty)
              _buildInfoRow(
                Icons.note,
                'Notas del Cliente',
                booking.notasAdicionales!,
              ),
            if (booking.motivoRechazo != null && booking.motivoRechazo!.isNotEmpty) ...[
              Divider(color: AppTheme.borderColor(context), height: 24),
              const Text(
                'Motivo de Rechazo:',
                style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(booking.motivoRechazo!, style: TextStyle(color: AppTheme.textColor(context))),
            ],
            Divider(color: AppTheme.borderColor(context)),
            const SizedBox(height: 8),
            if (booking.estadoConfirmacion == 'PENDIENTE') ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 140,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                      onPressed: () => _showRejectDialog(context, booking.idAgendamiento),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _confirmBooking(context, booking.idAgendamiento),
                    ),
                  ),
                ],
              ),
            ],
            if (booking.estadoConfirmacion == 'CONFIRMADO') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Cita Confirmada'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.green,
                    side: const BorderSide(color: AppTheme.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: null, // Disabled, just a visual indicator
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMutedColor(context)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: AppTheme.textMutedColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBooking(BuildContext context, int id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AdminProvider>().confirmBooking(id);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Cita confirmada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showRejectDialog(BuildContext context, int id) async {
    final TextEditingController reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Rechazar Cita', style: TextStyle(color: AppTheme.textColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Por qué vas a rechazar esta cita? Este motivo será visible para el cliente.',
              style: TextStyle(color: AppTheme.textMutedColor(context)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStyle(color: AppTheme.textColor(context)),
              decoration: const InputDecoration(
                labelText: 'Motivo de rechazo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancelar', style: TextStyle(color: AppTheme.textMutedColor(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              final val = reasonController.text.trim();
              if (val.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debes proporcionar un motivo')),
                );
                return;
              }
              Navigator.pop(dialogContext, val);
            },
            child: const Text('Rechazar Cita'),
          ),
        ],
      ),
    );

    if (reason != null && context.mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        await context.read<AdminProvider>().rejectBooking(id, reason);
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Cita rechazada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}
