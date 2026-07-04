import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_header.dart';
import '../mechanic/widgets/assigned_orders_tab.dart';
import '../mechanic/widgets/completed_history_tab.dart';
import '../mechanic/widgets/mechanic_schedule_tab.dart';

import 'package:screen_protector/screen_protector.dart';

class MechanicDashboardScreen extends StatefulWidget {
  const MechanicDashboardScreen({super.key});

  @override
  State<MechanicDashboardScreen> createState() => _MechanicDashboardScreenState();
}
class _MechanicDashboardScreenState extends State<MechanicDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _blockScreenshots();
  }

  Future<void> _blockScreenshots() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      debugPrint('No se pudo bloquear capturas: $e');
    }
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AssignedOrdersTab(),
      const CompletedHistoryTab(),
      const MechanicScheduleTab(),
    ];
    
    final initials = context.watch<AuthProvider>().initials;

    return Scaffold(
      backgroundColor: const Color(0xFF050607),
      body: SafeArea(
        child: Column(
          children: [
            DashboardHeader(
              role: 'Técnico',
              avatarText: initials,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: pages[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _MechanicBottomNav(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat de soporte próximamente...')),
          );
        },
        backgroundColor: AppTheme.green,
        child: const Icon(Icons.chat_rounded, color: Colors.black),
      ),
    );
  }
}

class _MechanicBottomNav extends StatelessWidget {
  const _MechanicBottomNav({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _MechanicNavItem(
        label: 'Órdenes',
        icon: Icons.build_circle_rounded,
      ),
      const _MechanicNavItem(
        label: 'Historial',
        icon: Icons.history_rounded,
      ),
      const _MechanicNavItem(
        label: 'Agenda',
        icon: Icons.calendar_month_rounded,
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
            final activeColor = AppTheme.green;
            final activeBgColor = AppTheme.green.withValues(alpha: 0.12);
            final activeBorderColor = AppTheme.green.withValues(alpha: 0.3);

            return Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? activeBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? activeBorderColor : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: selected ? activeColor : AppTheme.textMuted,
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
                                selected ? activeColor : AppTheme.textMuted,
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

class _MechanicNavItem {
  const _MechanicNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
