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
            final activeOrders = provider.serviceOrders.where((o) => 
                o.estadoOrden == 'EN_DIAGNOSTICO' || o.estadoOrden == 'EN_REPARACION' || o.estadoOrden == 'LISTO_PARA_ENTREGA'
            ).toList();

            if (provider.isLoading && activeOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.green));
            }

            if (activeOrders.isEmpty) {
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
                itemCount: activeOrders.length,
                itemBuilder: (context, index) {
                  final order = activeOrders[index];
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
            const SizedBox(height: 12),
            _buildInfoRow(Icons.directions_car_rounded, 'Placa', order.placaVehiculo ?? 'ID: ${order.idVehiculo}'),
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
            if (hasReport) ...[
              Builder(
                builder: (context) {
                  final rawText = order.informeTrabajo!;
                  // Parse out images from [IMAGENES]...[/IMAGENES] markers
                  String displayText = rawText;
                  List<String> imageUrls = [];
                  
                  final imgRegex = RegExp(r'\[IMAGENES\](.*?)\[/IMAGENES\]');
                  final match = imgRegex.firstMatch(rawText);
                  if (match != null) {
                    final imagesCsv = match.group(1) ?? '';
                    imageUrls = imagesCsv.split(',').where((u) => u.trim().isNotEmpty).toList();
                    displayText = rawText.replaceAll(imgRegex, '').trim();
                  }
                  
                  // Build the base URL for images (strip /api/v1 from the API base)
                  const apiBase = 'http://192.168.1.7:8000';

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Informe del Mecánico', style: GoogleFonts.dmSans(color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () => _editReport(context, order, provider),
                              icon: const Icon(Icons.edit, size: 16, color: AppTheme.green),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(displayText, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14)),
                        if (imageUrls.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Fotos de repuestos:', style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 12)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: imageUrls.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final fullUrl = '$apiBase${imageUrls[i]}';
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(fullUrl, fit: BoxFit.contain),
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      fullUrl,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 90,
                                        height: 90,
                                        color: const Color(0xFF222222),
                                        child: const Icon(Icons.broken_image, color: Colors.white38),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
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
            ] else if (order.estadoOrden == 'LISTO_PARA_ENTREGA') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDelivery(context, order, provider),
                  icon: const Icon(Icons.handshake_rounded),
                  label: const Text('Confirmar Entrega Física'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: hasReport ? () => _finishOrder(context, order, provider) : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Finalizar Orden'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.black,
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

  Future<void> _finishOrder(BuildContext context, ServiceOrderModel order, AdminProvider provider) async {
    try {
      await provider.finishServiceOrder(order.idOrden);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden finalizada. Vehículo listo para entrega.'), backgroundColor: AppTheme.green),
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

  Future<void> _confirmDelivery(BuildContext context, ServiceOrderModel order, AdminProvider provider) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bg,
        title: const Text('Confirmar Entrega Física', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Está seguro de que el vehículo va a salir del taller? Esta acción cambiará el estado a ENTREGADO.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.amber, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              try {
                await provider.deliverServiceOrder(order.idOrden);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entrega física confirmada.'), backgroundColor: AppTheme.green),
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
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }


  Future<void> _editReport(BuildContext context, ServiceOrderModel order, AdminProvider provider) async {
    final rawText = order.informeTrabajo ?? '';
    
    // Extraer imágenes para no perderlas
    String textToEdit = rawText;
    String imagesBlock = '';
    
    final imgRegex = RegExp(r'(\[IMAGENES\].*?\[/IMAGENES\])');
    final match = imgRegex.firstMatch(rawText);
    if (match != null) {
      imagesBlock = match.group(1) ?? '';
      textToEdit = rawText.replaceAll(imgRegex, '').trim();
    }

    final controller = TextEditingController(text: textToEdit);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131A2A),
              title: const Text('Editar Informe Técnico', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 400,
                child: TextField(
                  controller: controller,
                  maxLines: 8,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Edite el informe del mecánico...',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setState(() => isSaving = true);
                    final newText = controller.text.trim();
                    final finalText = imagesBlock.isNotEmpty ? '$newText\n\n$imagesBlock' : newText;
                    
                    try {
                      await provider.updateOrderReport(order.idOrden, finalText);
                      if (context.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      setState(() => isSaving = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green, foregroundColor: Colors.black),
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Guardar'),
                ),
              ],
            );
          }
        );
      }
    );
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
