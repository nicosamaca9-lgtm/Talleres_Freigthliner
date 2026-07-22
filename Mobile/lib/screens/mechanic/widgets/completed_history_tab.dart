import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';
import 'package:provider/provider.dart';
import '../../../providers/mechanic_provider.dart';
import '../../../models/service_order_model.dart';

class CompletedHistoryTab extends StatelessWidget {
  const CompletedHistoryTab({super.key});

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
                  const Icon(Icons.history_rounded, color: AppTheme.green, size: 21),
                  const SizedBox(width: 10),
                  Text(
                    'Historial de Trabajos',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.textColor(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Consumer<MechanicProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.completedOrders.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.green));
                  }
                  
                  if (provider.completedOrders.isEmpty) {
                    return Text('No tienes trabajos completados.', style: TextStyle(color: AppTheme.textMutedColor(context)));
                  }

                  return Column(
                    children: provider.completedOrders.asMap().entries.map((entry) {
                      final index = entry.key;
                      final order = entry.value;
                      return _CompletedHistoryCard(
                        vehicle: 'Orden ${index + 1}',
                        plate: order.placaVehiculo ?? 'N/A',
                        date: '${order.fechaIngreso} ${order.horaIngreso}',
                        order: order,
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

class _CompletedHistoryCard extends StatelessWidget {
  const _CompletedHistoryCard({
    required this.vehicle,
    required this.plate,
    required this.date,
    required this.order,
  });

  final String vehicle;
  final String plate;
  final String date;
  final ServiceOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  Icons.check_circle_outline_rounded,
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
                      vehicle,
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.textColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Placa: $plate',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textMutedColor(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const StatusChip(
                text: 'COMPLETADO',
                color: AppTheme.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          InfoLine(label: 'Trabajos:', value: order.trabajosARealizar),
          const SizedBox(height: 8),
          InfoLine(label: 'Ingreso:', value: date),
          if (order.fechaSalida != null) ...[
            const SizedBox(height: 8),
            InfoLine(label: 'Salida:', value: '${order.fechaSalida} ${order.horaSalida ?? ""}'),
          ],
          if (order.informeTrabajo != null && order.informeTrabajo!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final rawText = order.informeTrabajo!;
                String displayText = rawText;
                List<String> imageUrls = [];
                
                final imgRegex = RegExp(r'\[IMAGENES\](.*?)\[/IMAGENES\]');
                final match = imgRegex.firstMatch(rawText);
                if (match != null) {
                  final imagesCsv = match.group(1) ?? '';
                  imageUrls = imagesCsv.split(',').where((u) => u.trim().isNotEmpty).toList();
                  displayText = rawText.replaceAll(imgRegex, '').trim();
                }
                
                const apiBase = 'http://192.168.1.7:8000';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mi Informe Técnico', style: GoogleFonts.dmSans(color: AppTheme.green, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(displayText, style: GoogleFonts.dmSans(color: AppTheme.textColor(context), fontSize: 13)),
                      if (imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Evidencia:', style: GoogleFonts.dmSans(color: AppTheme.textMutedColor(context), fontSize: 12)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 70,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: imageUrls.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final img = imageUrls[i];
                              final fullUrl = img.startsWith('http') ? img : '$apiBase$img';
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
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 70,
                                      height: 70,
                                      color: AppTheme.inputColor(context),
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
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
        ],
      ),
    );
  }
}
