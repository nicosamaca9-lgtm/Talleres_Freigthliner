import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';

class VehiclesTab extends StatelessWidget {
  const VehiclesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      key: ValueKey('vehicles'),
      title: 'Mis vehiculos',
      icon: Icons.directions_car_filled_rounded,
      children: [
        _VehicleSummaryCard(),
        ResponsiveCards(
          left: _WorkStatusCard(),
          right: _QuoteCard(),
        ),
      ],
    );
  }
}

class _VehicleSummaryCard extends StatelessWidget {
  const _VehicleSummaryCard();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: AppTheme.green,
              size: 34,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toyota Corolla 2020',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Placa: ACA-456 - KM: 48.250 - VIN: JT2BF22K1W0123456',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                const StatusChip(text: 'En reparacion', color: AppTheme.blue),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Avance',
                style: GoogleFonts.dmSans(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                '72%',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.green,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkStatusCard extends StatelessWidget {
  const _WorkStatusCard();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.sync_rounded,
            title: 'Estado actual - OS-2026-087',
          ),
          const SizedBox(height: 18),
          Text(
            'Cambio de correa de distribucion + aceite',
            style: GoogleFonts.dmSans(
              color: AppTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.72,
              minHeight: 10,
              backgroundColor: Color(0xFF242424),
              valueColor: AlwaysStoppedAnimation(AppTheme.green),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '72% completado',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted),
              ),
              const Spacer(),
              Text(
                'Entrega est.: 7 Jun',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ActionButton(
                label: 'Descargar OS',
                icon: Icons.download_rounded,
                isPrimary: true,
              ),
              ActionButton(
                label: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.receipt_long_rounded,
            title: 'Cotizacion pendiente',
          ),
          const SizedBox(height: 16),
          Text(
            'Se requiere su aprobacion',
            style: GoogleFonts.dmSans(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),
          const PriceRow(label: 'Filtro de aire', value: r'$45.000'),
          const SizedBox(height: 8),
          const PriceRow(label: 'Pastillas de freno', value: r'$120.000'),
          const Divider(height: 28, color: Color(0xFF242424)),
          const PriceRow(
            label: 'Total',
            value: r'$165.000',
            isTotal: true,
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ActionButton(
                label: 'Aprobar',
                icon: Icons.check_rounded,
                isPrimary: true,
              ),
              ActionButton(
                label: 'Rechazar',
                icon: Icons.close_rounded,
                isDanger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
