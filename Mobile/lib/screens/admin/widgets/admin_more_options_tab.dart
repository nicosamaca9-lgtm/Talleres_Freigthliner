import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'admin_overview_tab.dart';
import 'admin_bookings_tab.dart';
import 'admin_users_tab.dart';
import 'admin_receipts_tab.dart';
import 'admin_vehicles_tab.dart';

class AdminMoreOptionsTab extends StatefulWidget {
  const AdminMoreOptionsTab({super.key});

  @override
  State<AdminMoreOptionsTab> createState() => _AdminMoreOptionsTabState();
}

class _AdminMoreOptionsTabState extends State<AdminMoreOptionsTab> {
  int? _activeSubTabIndex;

  final List<Widget> _subTabs = [
    const AdminOverviewTab(),
    const AdminBookingsTab(),
    const AdminUsersTab(),
    const AdminReceiptsTab(),
    const AdminVehiclesTab(),
  ];

  final List<String> _subTabTitles = [
    'Resumen General',
    'Citas',
    'Usuarios y Mecánicos',
    'Recibos y Facturación',
    'Historial de Vehículos',
  ];

  @override
  Widget build(BuildContext context) {
    // If a sub-option is selected, show its content directly (no extra title bar)
    if (_activeSubTabIndex != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple back row – transparent bg, just text + arrow
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.green, size: 22),
                  onPressed: () => setState(() => _activeSubTabIndex = null),
                ),
                const SizedBox(width: 4),
                Text(
                  _subTabTitles[_activeSubTabIndex!],
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _subTabs[_activeSubTabIndex!]),
        ],
      );
    }

    // Grid menu
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, color: AppTheme.green, size: 21),
              const SizedBox(width: 10),
              Text(
                'Más Opciones',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            children: [
              _buildMenuCard(0, Icons.dashboard_rounded, 'Resumen General', AppTheme.blue),
              _buildMenuCard(1, Icons.calendar_month_rounded, 'Citas', AppTheme.amber),
              _buildMenuCard(4, Icons.directions_car_filled_rounded, 'Vehículos', AppTheme.green),
              _buildMenuCard(2, Icons.people_rounded, 'Usuarios', Colors.purple),
              _buildMenuCard(3, Icons.receipt_long_rounded, 'Recibos', const Color(0xFF06b6d4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(int index, IconData icon, String title, Color color) {
    return InkWell(
      onTap: () => setState(() => _activeSubTabIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
