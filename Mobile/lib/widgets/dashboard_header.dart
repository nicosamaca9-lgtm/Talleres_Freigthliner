import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({
    super.key,
    required this.role,
    required this.avatarText,
  });

  final String role;
  final String avatarText;

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppTheme.appBarColor(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor(context), width: 1),
        ),
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
                  'NIT: 7184810 - Portal ${widget.role}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textMutedColor(context),
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
              Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.unreadCount == 0) return const SizedBox();
                  return Positioned(
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
                        '${chatProvider.unreadCount}',
                        style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 10),
          _HeaderAvatar(avatarText: widget.avatarText),
        ],
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
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Icon(icon, color: AppTheme.textMutedColor(context), size: 22),
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
      color: AppTheme.cardColor(context),
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
          context.read<ChatProvider>().disconnect();
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
              Icon(
                Icons.person_outline_rounded,
                color: AppTheme.textColor(context),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Mi Cuenta',
                style: GoogleFonts.dmSans(color: AppTheme.textColor(context)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'privacy',
          child: Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: AppTheme.textColor(context),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Privacidad',
                style: GoogleFonts.dmSans(color: AppTheme.textColor(context)),
              ),
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
              Text(
                'Cerrar sesión',
                style: GoogleFonts.dmSans(color: AppTheme.red),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
