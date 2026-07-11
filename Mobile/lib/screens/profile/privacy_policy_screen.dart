import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Políticas y Privacidad',
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
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.privacy_tip_outlined,
                  color: AppTheme.green,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'TF Centro Automotriz',
              style: GoogleFonts.rajdhani(
                color: AppTheme.textColor(context),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A continuación, presentamos los términos, condiciones y políticas de uso de nuestra plataforma y servicios en el taller.',
              style: GoogleFonts.dmSans(
                color: AppTheme.textMutedColor(context),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildPolicySection(context,
              title: '1. Uso de Información Personal',
              icon: Icons.contact_page_outlined,
              content:
                  'Los datos proporcionados (nombre, teléfono, placa, modelo del vehículo) serán utilizados de forma exclusiva para la gestión de citas, el historial de mantenimientos y la facturación. No compartiremos su información con terceros sin su consentimiento explícito.',
            ),
            _buildPolicySection(context,
              title: '2. Condiciones de Agendamiento',
              icon: Icons.calendar_month_outlined,
              content:
                  'Las citas programadas deben ser respetadas en horario. Si requiere reprogramar o cancelar una cita, deberá hacerlo con un mínimo de 3 horas de anticipación. Pasado este tiempo, el sistema bloqueará la opción para garantizar la eficiencia de nuestro taller.',
            ),
            _buildPolicySection(context,
              title: '3. Responsabilidad sobre Objetos',
              icon: Icons.no_luggage_outlined,
              content:
                  'Solicitamos amablemente retirar objetos de valor del vehículo al ingresarlo al taller. TF Centro Automotriz no se hace responsable por la pérdida de artículos personales no declarados durante el inventario de recepción.',
            ),
            _buildPolicySection(context,
              title: '4. Garantía de Servicio',
              icon: Icons.verified_outlined,
              content:
                  'Todo servicio de mano de obra cuenta con un periodo de garantía estipulado en su recibo final. Dicha garantía se invalida de forma inmediata si el vehículo es manipulado por talleres externos tras nuestra intervención.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Última actualización: Julio 2026',
                style: GoogleFonts.dmSans(
                  color: AppTheme.textMutedColor(context),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(BuildContext context, {
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.textColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.dmSans(
                color: AppTheme.textMutedColor(context),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
