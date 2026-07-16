import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/ui_components.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Centro de Ayuda',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preguntas Frecuentes',
              style: GoogleFonts.rajdhani(
                color: AppTheme.textColor(context),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _FaqItem(
              question: '¿Cómo puedo agendar una cita?',
              answer: 'Puedes agendar una cita desde la sección "Mis Citas" o en el panel de control seleccionando "Nueva Cita". Recuerda que debes tener un vehículo registrado previamente.',
            ),
            const SizedBox(height: 12),
            _FaqItem(
              question: '¿Puedo cancelar o reprogramar una cita?',
              answer: 'Sí, puedes cancelar o reprogramar tu cita siempre y cuando falten más de 3 horas para la misma. Si falta menos tiempo, deberás contactarnos directamente.',
            ),
            const SizedBox(height: 12),
            _FaqItem(
              question: '¿Cuáles son los horarios de atención?',
              answer: 'Atendemos de lunes a viernes, de 08:00 a 12:00 y de 14:00 a 18:00.',
            ),
            const SizedBox(height: 40),
            Text(
              'Contacto',
              style: GoogleFonts.rajdhani(
                color: AppTheme.textColor(context),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DashboardCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ContactItem(
                    icon: Icons.phone_rounded,
                    title: 'Teléfono',
                    subtitle: '+57 3204472578',
                  ),
                  const Divider(height: 32),
                  _ContactItem(
                    icon: Icons.email_rounded,
                    title: 'Correo Electrónico',
                    subtitle: 'tfcentroautomotriz@gmail.com',
                  ),
                  const Divider(height: 32),
                  _ContactItem(
                    icon: Icons.location_on_rounded,
                    title: 'Ubicación',
                    subtitle: ' TF Centro Automotriz Autopista Higueras , Duitama Boyacá',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.dmSans(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        collapsedBackgroundColor: AppTheme.cardColor(context),
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        iconColor: AppTheme.green,
        collapsedIconColor: AppTheme.textMutedColor(context),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: GoogleFonts.dmSans(
              color: AppTheme.textMutedColor(context),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.green, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  color: AppTheme.textMutedColor(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
