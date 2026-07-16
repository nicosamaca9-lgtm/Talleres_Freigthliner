import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_header.dart';
import '../admin/widgets/admin_orders_tab.dart';
import '../admin/widgets/admin_reports_tab.dart';
import '../admin/widgets/admin_receipts_tab.dart';

class SecretaryDashboardScreen extends StatefulWidget {
  const SecretaryDashboardScreen({super.key});

  @override
  State<SecretaryDashboardScreen> createState() => _SecretaryDashboardScreenState();
}

class _SecretaryDashboardScreenState extends State<SecretaryDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminOrdersTab(),
      const AdminReportsTab(),
      const AdminReceiptsTab(),
    ];

    final initials = context.watch<AuthProvider>().initials;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: SafeArea(
        child: Column(
          children: [
            DashboardHeader(
              role: 'Secretario',
              avatarText: initials,
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
      bottomNavigationBar: _SecretaryBottomNav(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _SecretaryBottomNav extends StatelessWidget {
  const _SecretaryBottomNav({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _SecretaryNavItem(
        label: 'Órdenes',
        icon: Icons.build_circle_rounded,
      ),
      const _SecretaryNavItem(
        label: 'Historial',
        icon: Icons.history_rounded,
      ),
      const _SecretaryNavItem(
        label: 'Recibos',
        icon: Icons.receipt_long_rounded,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppTheme.navBarColor(context),
          border: Border(
            top: BorderSide(color: AppTheme.borderColor(context), width: 1),
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
                        color: selected ? AppTheme.green : AppTheme.textMutedColor(context),
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
                                selected ? AppTheme.green : AppTheme.textMutedColor(context),
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

class _SecretaryNavItem {
  final String label;
  final IconData icon;

  const _SecretaryNavItem({
    required this.label,
    required this.icon,
  });
}
