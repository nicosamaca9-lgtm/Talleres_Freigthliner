import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/dashboard_header.dart';
import '../client/widgets/agendamiento_cliente.dart';
import '../client/widgets/comentarios_cliente.dart';
import '../client/widgets/vehiculo_cliente.dart';


class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AgendamientoCliente(),
      const VehiclesTab(),
      const CommentsTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050607),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(
              role: 'Cliente',
              avatarText: 'CM',
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: pages[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ClientBottomNav(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _ClientBottomNav extends StatelessWidget {
  const _ClientBottomNav({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _ClientNavItem(
        label: 'Agendamiento',
        icon: Icons.calendar_month_rounded,
      ),
      const _ClientNavItem(
        label: 'Vehiculos',
        icon: Icons.directions_car_filled_rounded,
      ),
      const _ClientNavItem(
        label: 'Comentarios',
        icon: Icons.star_rounded,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: Color(0xFF101010),
          border: Border(
            top: BorderSide(color: Color(0xFF242424), width: 1),
          ),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = currentIndex == index;
            final item = items[index];

            return Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.greenBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppTheme.borderGreen : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: selected ? AppTheme.green : AppTheme.textMuted,
                        size: 23,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: GoogleFonts.dmSans(
                            color:
                                selected ? AppTheme.green : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ClientNavItem {
  const _ClientNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
