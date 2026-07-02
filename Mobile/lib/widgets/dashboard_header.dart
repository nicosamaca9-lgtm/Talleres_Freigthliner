import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.role,
    required this.avatarText,
  });

  final String role;
  final String avatarText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF101010),
        border: Border(bottom: BorderSide(color: Color(0xFF242424), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TF Centro Automotriz',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.green,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIT: 7184810 - Portal $role',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
              Positioned(
                right: -2,
                top: -6,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppTheme.green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '3',
                    style: GoogleFonts.dmSans(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          _HeaderAvatar(avatarText: avatarText),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.greenBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderGreen),
      ),
      child: Text(
        role,
        style: GoogleFonts.dmSans(
          color: AppTheme.green,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Icon(icon, color: AppTheme.textMuted, size: 22),
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.avatarText});
  final String avatarText;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF171717),
      icon: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.greenDim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          avatarText,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      onSelected: (value) async {
        if (value == 'logout') {
          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            context.go('/login');
          }
        } else if (value == 'profile') {
          context.push('/profile');
        } else if (value == 'privacy') {
          context.push('/privacy');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile', 
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, color: AppTheme.text, size: 20),
              const SizedBox(width: 10),
              const Text('Mi Cuenta'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'privacy', 
          child: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: AppTheme.text, size: 20),
              const SizedBox(width: 10),
              const Text('Privacidad'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout', 
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.red, size: 20),
              const SizedBox(width: 10),
              Text('Cerrar sesión', style: GoogleFonts.dmSans(color: AppTheme.red)),
            ],
          ),
        ),
      ],
    );
  }
}
