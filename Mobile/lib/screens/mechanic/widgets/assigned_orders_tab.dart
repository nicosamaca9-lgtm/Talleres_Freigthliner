import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';
import '../../../providers/mechanic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/service_order_model.dart';
import 'technical_report_dialog.dart';

class AssignedOrdersTab extends StatefulWidget {
  const AssignedOrdersTab({super.key});

  @override
  State<AssignedOrdersTab> createState() => _AssignedOrdersTabState();
}

class _AssignedOrdersTabState extends State<AssignedOrdersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mechanicId = context.read<AuthProvider>().userId;
      if (mechanicId != null) {
        context.read<MechanicProvider>().loadAssignedOrders(mechanicId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MechanicProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.assignedOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }

        return RefreshIndicator(
          onRefresh: () async {
            final mechanicId = context.read<AuthProvider>().userId;
            if (mechanicId != null) {
              await provider.loadAssignedOrders(mechanicId);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                        const Icon(Icons.build_circle_rounded, color: AppTheme.green, size: 21),
                        const SizedBox(width: 10),
                        Text(
                          'Órdenes Asignadas',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.textColor(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (provider.assignedOrders.isEmpty)
                      Text('No tienes órdenes asignadas actualmente.', style: TextStyle(color: AppTheme.textMutedColor(context)))
                    else
                      ...provider.assignedOrders.map((order) => _AssignedOrderCard(order: order)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AssignedOrderCard extends StatelessWidget {
  const _AssignedOrderCard({required this.order});

  final ServiceOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: AppTheme.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Placa: ${order.placaVehiculo ?? 'Sin Placa'}',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.textColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                text: order.estadoOrden,
                color: AppTheme.green,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnóstico o Trabajos a Realizar:',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textMutedColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  order.trabajosARealizar,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textColor(context),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          InfoLine(label: 'Ingreso:', value: '${order.fechaIngreso} ${order.horaIngreso}'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: 'Redactar Informe',
              icon: Icons.note_add_rounded,
              isPrimary: true,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => TechnicalReportDialog(
                    idOrden: order.idOrden,
                    title: order.numeroOrden.isNotEmpty ? order.numeroOrden : 'ORD-${order.idOrden}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
