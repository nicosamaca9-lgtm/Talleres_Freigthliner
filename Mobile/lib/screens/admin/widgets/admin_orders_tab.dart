import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/service_order_model.dart';
import '../../../models/user_model.dart';
import '../../../models/user_role.dart';
import 'service_order_form_dialog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../../core/utils/report_assets.dart';

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServiceOrderFormDialog(),
                ),
              ).then((result) {
                if (result == true) {
                  provider.fetchServiceOrders();
                }
              });
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nueva Orden',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: () {
            final activeOrders = provider.serviceOrders
                .where(
                  (o) =>
                      o.estadoOrden == 'EN_DIAGNOSTICO' ||
                      o.estadoOrden == 'EN_REPARACION' ||
                      o.estadoOrden == 'LISTO_PARA_ENTREGA',
                )
                .toList();

            if (provider.isLoading && activeOrders.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.green),
              );
            }

            if (activeOrders.isEmpty) {
              return Center(
                child: Text(
                  'No hay órdenes de servicio activas.',
                  style: TextStyle(color: AppTheme.textMutedColor(context)),
                ),
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

  Widget _buildOrderCard(
    BuildContext context,
    ServiceOrderModel order,
    AdminProvider provider,
  ) {
    // Determine status color
    Color statusColor = AppTheme.green;
    if (order.estadoOrden == 'LISTO_PARA_ENTREGA') statusColor = AppTheme.amber;
    if (order.estadoOrden == 'ENTREGADO') statusColor = Colors.grey;

    final isAssigned = order.idMecanico != null;
    final assignedMechanic = isAssigned
        ? provider.users
              .where((u) => u.idUsuario == order.idMecanico)
              .firstOrNull
        : null;

    final hasReport =
        order.informeTrabajo != null && order.informeTrabajo!.trim().isNotEmpty;
    final isDelivered = order.estadoOrden == 'ENTREGADO';

    return Card(
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor(context)),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.numeroOrden.isNotEmpty
                        ? order.numeroOrden
                        : 'ORD-${order.idOrden}',
                    style: GoogleFonts.rajdhani(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  '${order.fechaIngreso} ${order.horaIngreso}',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textMutedColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_rounded, 'Cliente', order.clienteNombre),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.directions_car_rounded,
              'Placa',
              order.placaVehiculo ?? 'ID: ${order.idVehiculo}',
            ),
            _buildInfoRow(Icons.build_rounded, 'Estado', order.estadoOrden),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.inputColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.handyman_outlined,
                    color: AppTheme.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mecánico Asignado',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textMutedColor(context),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          isAssigned
                              ? (assignedMechanic != null
                                    ? '${assignedMechanic.nombre} ${assignedMechanic.apellido}'
                                    : 'Cargando...')
                              : 'Sin Asignar',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.textColor(context),
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
                      onPressed: () =>
                          _showAssignMechanicDialog(context, order, provider),
                      child: const Text('Asignar'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (hasReport) ...[
              Builder(
                builder: (context) {
                  final report = ReportAssetParser.parse(order.informeTrabajo);

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.inputColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Informe del Mecánico',
                              style: GoogleFonts.dmSans(
                                color: AppTheme.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _editReport(context, order, provider),
                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color: AppTheme.green,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.text.isEmpty
                              ? 'Sin informe registrado.'
                              : report.text,
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textColor(context),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildReportImagePreview(context, report.imageUrls),
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
                  onPressed: () =>
                      _downloadPDF(context, order, assignedMechanic),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Descargar Orden (PDF)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textColor(context),
                    side: BorderSide(color: AppTheme.borderColor(context)),
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
                  onPressed: hasReport
                      ? () => _finishOrder(context, order, provider)
                      : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Finalizar Orden'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppTheme.inputColor(context),
                    disabledForegroundColor: AppTheme.textMutedColor(context),
                  ),
                ),
              ),
              if (!hasReport)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: Text(
                      'Requiere informe del mecánico para finalizar',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportImagePreview(
    BuildContext context,
    List<String> imageUrls, {
    double size = 74,
  }) {
    if (imageUrls.isEmpty) {
      return _buildImageStateChip(
        context,
        icon: Icons.hide_image_outlined,
        label: 'Sin imagenes',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidencia:',
          style: GoogleFonts.dmSans(
            color: AppTheme.textMutedColor(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: size,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final imageUrl = _resolveReportImageUrl(imageUrls[index]);
              return GestureDetector(
                key: Key('admin_report_image_preview_$index'),
                onTap: () => _showReportImage(context, imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: size,
                      height: size,
                      color: AppTheme.cardColor(context),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppTheme.textMutedColor(context),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageStateChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMutedColor(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppTheme.textMutedColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableReportImages(
    BuildContext context,
    List<String> imageUrls,
    StateSetter setDialogState,
  ) {
    if (imageUrls.isEmpty) {
      return _buildImageStateChip(
        context,
        icon: Icons.hide_image_outlined,
        label: 'Sin imagenes',
      );
    }

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final imageUrl = _resolveReportImageUrl(imageUrls[index]);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _showReportImage(context, imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 74,
                      height: 74,
                      color: AppTheme.cardColor(context),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppTheme.textMutedColor(context),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: IconButton(
                  key: Key('admin_report_image_delete_$index'),
                  onPressed: () {
                    setDialogState(() {
                      imageUrls.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.close, size: 14),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(28, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              padding: const EdgeInsets.all(24),
              color: AppTheme.cardColor(context),
              child: Text(
                'No se pudo cargar la imagen.',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _resolveReportImageUrl(String imageUrl) {
    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return trimmedUrl;
    }

    final apiRoot = ApiClient.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    if (trimmedUrl.startsWith('/')) {
      return '$apiRoot$trimmedUrl';
    }
    return '$apiRoot/$trimmedUrl';
  }

  Future<void> _finishOrder(
    BuildContext context,
    ServiceOrderModel order,
    AdminProvider provider,
  ) async {
    try {
      await provider.finishServiceOrder(order.idOrden);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden finalizada. Vehículo listo para entrega.'),
            backgroundColor: AppTheme.green,
          ),
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

  Future<void> _confirmDelivery(
    BuildContext context,
    ServiceOrderModel order,
    AdminProvider provider,
  ) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bgColor(context),
        title: Text(
          'Confirmar Entrega Física',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          '¿Está seguro de que el vehículo va a salir del taller? Esta acción cambiará el estado a ENTREGADO.',
          style: TextStyle(color: AppTheme.textMutedColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textMutedColor(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              try {
                await provider.deliverServiceOrder(order.idOrden);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Entrega física confirmada.'),
                      backgroundColor: AppTheme.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppTheme.red,
                    ),
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

  Future<void> _editReport(
    BuildContext context,
    ServiceOrderModel order,
    AdminProvider provider,
  ) async {
    final report = ReportAssetParser.parse(order.informeTrabajo);
    final imageUrls = List<String>.from(report.imageUrls);

    // Extraer imágenes para no perderlas
    var reportText = report.text;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor(context),
              title: Text(
                'Editar Informe Técnico',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: reportText,
                        onChanged: (value) => reportText = value,
                        maxLines: 8,
                        style: TextStyle(color: AppTheme.textColor(context)),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Edite el informe del mecánico...',
                          hintStyle: TextStyle(
                            color: AppTheme.textMutedColor(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Imagenes adjuntas',
                        style: GoogleFonts.dmSans(
                          color: AppTheme.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEditableReportImages(context, imageUrls, setState),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: AppTheme.textMutedColor(context)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          final finalText = ReportAssetParser.serialize(
                            text: reportText,
                            imageUrls: imageUrls,
                          );
                          final navigator = Navigator.of(ctx);
                          final scaffoldMessenger = ScaffoldMessenger.of(ctx);

                          try {
                            await provider.updateOrderReport(
                              order.idOrden,
                              finalText,
                            );
                            navigator.pop();
                          } catch (e) {
                            setState(() => isSaving = false);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.black,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _downloadPDF(
    BuildContext context,
    ServiceOrderModel order,
    UserModel? mechanic,
  ) async {
    try {
      await PdfGenerator.generateServiceOrderPdf(order, mechanic);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppTheme.red,
          ),
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

  void _showAssignMechanicDialog(
    BuildContext context,
    ServiceOrderModel order,
    AdminProvider provider,
  ) {
    final mechanics = provider.users
        .where((u) => u.userRole == UserRole.mechanic)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                style: GoogleFonts.dmSans(
                  color: AppTheme.textMutedColor(context),
                  fontSize: 14,
                ),
              ),
              Divider(color: AppTheme.borderColor(context), height: 32),
              if (mechanics.isEmpty)
                Center(
                  child: Text(
                    'No hay mecánicos registrados.',
                    style: TextStyle(color: AppTheme.textMutedColor(context)),
                  ),
                )
              else
                ...mechanics.map(
                  (m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.green,
                      child: Icon(Icons.person, color: Colors.black),
                    ),
                    title: Text(
                      '${m.nombre} ${m.apellido}',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      m.especialidad ?? 'Mecánico General',
                      style: TextStyle(color: AppTheme.textMutedColor(context)),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppTheme.textMutedColor(context),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await provider.assignMechanic(
                          order.idOrden,
                          m.idUsuario,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mecánico asignado exitosamente'),
                              backgroundColor: AppTheme.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppTheme.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
