import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/service_order_model.dart';
import '../../../models/user_model.dart';
import 'service_order_form_dialog.dart';
import '../../../core/utils/pdf_generator.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchServiceOrders();
      context.read<AdminProvider>().fetchUsers(); // To load mechanics
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.green,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ServiceOrderFormDialog(),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Nueva Orden', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: () {
            if (provider.isLoading && provider.serviceOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.green));
            }

            if (provider.serviceOrders.isEmpty) {
              return const Center(
                child: Text('No hay órdenes de servicio activas.', style: TextStyle(color: Colors.white70)),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await provider.fetchServiceOrders();
                await provider.fetchUsers();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                itemCount: provider.serviceOrders.length,
                itemBuilder: (context, index) {
                  final order = provider.serviceOrders[index];
                  return _buildOrderCard(context, order, provider);
                },
              ),
            );
          }(),
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, ServiceOrderModel order, AdminProvider provider) {
    // Determine status color
    Color statusColor = AppTheme.green;
    if (order.estadoOrden == 'LISTO_PARA_ENTREGA') statusColor = AppTheme.amber;
    if (order.estadoOrden == 'ENTREGADO') statusColor = Colors.grey;

    final isAssigned = order.idMecanico != null;
    final assignedMechanic = isAssigned 
        ? provider.users.where((u) => u.idUsuario == order.idMecanico).firstOrNull 
        : null;

    final hasReport = order.informeTrabajo != null && order.informeTrabajo!.trim().isNotEmpty;
    final isDelivered = order.estadoOrden == 'ENTREGADO';

    return Card(
      color: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF242424)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.numeroOrden.isNotEmpty ? order.numeroOrden : 'ORD-${order.idOrden}',
                    style: GoogleFonts.rajdhani(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  '${order.fechaIngreso} ${order.horaIngreso}',
                  style: GoogleFonts.dmSans(color: AppTheme.textDim, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_rounded, 'Cliente', order.clienteNombre),
            _buildInfoRow(Icons.directions_car_rounded, 'Vehículo ID', order.idVehiculo.toString()),
            _buildInfoRow(Icons.build_rounded, 'Estado', order.estadoOrden),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.handyman_outlined, color: AppTheme.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mecánico Asignado', style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12)),
                        Text(
                          isAssigned 
                            ? (assignedMechanic != null ? '${assignedMechanic.nombre} ${assignedMechanic.apellido}' : 'Cargando...')
                            : 'Sin Asignar',
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAssigned && !isDelivered)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => _showAssignMechanicDialog(context, order, provider),
                      child: const Text('Asignar'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isDelivered) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadPDF(context, order, assignedMechanic),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Descargar Orden (PDF)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF444444)),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: hasReport ? () => _finishOrder(context, order, provider) : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Finalizar Orden'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF222222),
                    disabledForegroundColor: Colors.white54,
                  ),
                ),
              ),
              if (!hasReport)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: Text(
                      'Requiere informe del mecánico para finalizar',
                      style: GoogleFonts.dmSans(color: AppTheme.errorColor, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _finishOrder(BuildContext context, ServiceOrderModel order, AdminProvider provider) async {
    try {
      await provider.finishServiceOrder(order.idOrden);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden finalizada exitosamente.'), backgroundColor: AppTheme.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.red),
        );
      }
    }
  }

  void _downloadPDF(BuildContext context, ServiceOrderModel order, UserModel? mechanic) async {
    try {
      await PdfGenerator.generateServiceOrderPdf(order, mechanic);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: AppTheme.red),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignMechanicDialog(BuildContext context, ServiceOrderModel order, AdminProvider provider) {
    final mechanics = provider.users.where((u) => u.rol == 'MECANICO' || u.rol.toLowerCase() == 'tecnico').toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asignar Mecánico',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.green,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona el mecánico para la ${order.numeroOrden}',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 14),
              ),
              const Divider(color: Color(0xFF242424), height: 32),
              if (mechanics.isEmpty)
                const Center(child: Text('No hay mecánicos registrados.', style: TextStyle(color: Colors.white54)))
              else
                ...mechanics.map((m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.green,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  title: Text('${m.nombre} ${m.apellido}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(m.especialidad ?? 'Mecánico General', style: const TextStyle(color: Colors.white54)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await provider.assignMechanic(order.idOrden, m.idUsuario);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mecánico asignado exitosamente'), backgroundColor: AppTheme.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.red),
                        );
                      }
                    }
                  },
                )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
