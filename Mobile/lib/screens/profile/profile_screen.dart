import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/ui_components.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    const color = AppTheme.green;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textColor(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mi Cuenta',
          style: GoogleFonts.rajdhani(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    provider.initials,
                    style: GoogleFonts.rajdhani(
                      color: color,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${provider.userName ?? ''} ${provider.userLastName ?? ''}'.trim(),
              style: GoogleFonts.rajdhani(
                color: AppTheme.textColor(context),
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            StatusChip(
              text: provider.role?.toUpperCase() ?? 'USUARIO',
              color: color,
            ),
            const SizedBox(height: 40),
            DashboardCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ProfileSetting(
                    icon: Icons.person_outline_rounded,
                    title: 'Datos Personales',
                    color: color,
                    onTap: () => context.push('/profile/personal-data'),
                  ),
                  const Divider(height: 32),
                  _ProfileSetting(
                    icon: Icons.security_rounded,
                    title: 'Seguridad y Contraseña',
                    color: color,
                    onTap: () => context.push('/profile/security'),
                  ),
                  const Divider(height: 32),
                  _ProfileSetting(
                    icon: Icons.help_outline_rounded,
                    title: 'Centro de Ayuda',
                    color: color,
                    onTap: () => context.push('/profile/help'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            DashboardCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apariencia',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textColor(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          themeProvider.isDarkMode ? 'Modo Oscuro' : 'Modo Claro',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textMutedColor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: themeProvider.isDarkMode,
                    activeColor: AppTheme.green,
                    onChanged: (val) {
                      context.read<ThemeProvider>().toggleTheme(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ActionButton(
                label: 'Cerrar Sesión',
                icon: Icons.logout_rounded,
                isDanger: true,
                onPressed: () async {
                  context.read<ChatProvider>().disconnect();
                  await provider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ActionButton(
                label: 'Eliminar Cuenta',
                icon: Icons.person_remove_rounded,
                isDanger: true,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.cardColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Eliminar Cuenta',
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.textColor(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        '¿Estás seguro de que deseas eliminar tu cuenta?\n\nEsta acción es irreversible y perderás todo tu historial de servicios.',
                        style: GoogleFonts.dmSans(
                          color: AppTheme.textMutedColor(context),
                          fontSize: 14,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.dmSans(color: AppTheme.textMutedColor(context)),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            // Aquí se llamaría al AuthProvider para eliminar la cuenta en el backend.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cuenta eliminada exitosamente'),
                                backgroundColor: AppTheme.green,
                              ),
                            );
                            context.read<ChatProvider>().disconnect();
                            await provider.logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          child: Text(
                            'Sí, Eliminar',
                            style: GoogleFonts.dmSans(
                              color: AppTheme.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileSetting extends StatelessWidget {
  const _ProfileSetting({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.dmSans(
              color: AppTheme.textColor(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textMutedColor(context),
        ),
        ],
      ),
      ),
    );
  }
}
