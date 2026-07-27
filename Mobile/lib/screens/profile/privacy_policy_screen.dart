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
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.garage_outlined,
                      color: AppTheme.green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TF CENTRO AUTOMOTRIZ',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.textColor(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Más de 14 años de experiencia en el sector automotriz',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: AppTheme.textMutedColor(context),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quiénes somos
            _buildSection(context,
              title: '¿Quiénes Somos?',
              icon: Icons.business_outlined,
              content:
                'TF Centro Automotriz es un centro de servicio automotriz que presta servicios de mantenimiento preventivo, correctivo, eléctrico y electrónico, con una experiencia de más de 14 años en el sector automotriz.\n\n'
                'Ofrecemos a nuestros clientes información en tiempo real de los procesos realizados a su flota de vehículos, siendo una herramienta de gestión que facilita la comunicación entre el taller y el cliente, generando confianza, transparencia comercial y seguridad a nuestros usuarios.',
            ),

            // Misión
            _buildSection(context,
              title: 'Misión',
              icon: Icons.flag_outlined,
              content:
                'Para TF Centro Automotriz es importante el cumplimiento, el trabajo con excelencia, mano de obra calificada y certificada, lograr posicionamiento en nuevos mercados y seguir garantizando la calidad de nuestros servicios y la satisfacción de nuestros clientes.',
            ),

            // Visión
            _buildSection(context,
              title: 'Visión',
              icon: Icons.remove_red_eye_outlined,
              content:
                'Ser una de las empresas más reconocidas como la mejor opción en centros de mantenimiento y reparación automotriz, comprometidos con la excelencia, eficiencia y competitividad, realización de trabajos garantizados con repuestos de excelente calidad, trabajo en equipo y rentabilidad para nuestros clientes.',
            ),

            // Valores
            _buildSection(context,
              title: 'Valores Corporativos',
              icon: Icons.star_outline_rounded,
              content: '',
              bulletPoints: const [
                'Honestidad',
                'Integridad',
                'Compromiso',
                'Actitud de servicio',
                'Responsabilidad',
              ],
            ),

            // Portafolio
            _buildSection(context,
              title: 'Portafolio de Servicios',
              icon: Icons.build_outlined,
              content:
                'De acuerdo con la normatividad legal vigente (Resolución 40595 del 2022), nuestro servicio se ajusta para la actualización de hojas de vida de los equipos e implementa planes de mantenimiento vehicular necesarios.',
              bulletPoints: const [
                'Cambios de aceite y filtros',
                'Revisión de niveles y luces',
                'Sistemas eléctricos y diagnóstico',
                'Revisión y reparación de frenos',
                'Mecánica especializada Diesel (ISUZU, CATERPILLAR, HINO, HYUNDAI, FREIGHTLINER, CUMMINS)',
                'Scanner y calibración de inyectores',
                'Reparación de suspensiones y dirección',
                'Cambio de embragues y cajas mecánicas',
                'Reparación de diferenciales y transmisiones',
                'Repuestos originales por encargo',
              ],
            ),

            // Garantía
            _buildSection(context,
              title: 'Garantía y Puntualidad',
              icon: Icons.verified_outlined,
              content:
                'Nuestra garantía incluye la reposición o cambio del producto por defecto. Entregamos los trabajos según lo pactado y programado.\n\n'
                'La garantía se invalida si el vehículo es manipulado por talleres externos tras nuestra intervención.',
            ),

            // Horario
            _buildSection(context,
              title: 'Horario de Servicio',
              icon: Icons.schedule_outlined,
              content: '',
              bulletPoints: const [
                'Lunes a sábado: horario regular',
                'Domingos: según programación con el área de mantenimiento',
                'Asistencia en carretera disponible',
              ],
            ),

            // Divider políticas legales
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.borderColor(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'POLÍTICAS DE USO DE LA PLATAFORMA',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.borderColor(context))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Políticas legales
            _buildSection(context,
              title: '1. Uso de Información Personal',
              icon: Icons.contact_page_outlined,
              content:
                'Los datos proporcionados (nombre, teléfono, placa, modelo del vehículo) serán utilizados de forma exclusiva para la gestión de citas, el historial de mantenimientos y la facturación. No compartiremos su información con terceros sin su consentimiento explícito.',
            ),
            _buildSection(context,
              title: '2. Condiciones de Agendamiento',
              icon: Icons.calendar_month_outlined,
              content:
                'Las citas programadas deben ser respetadas en horario. Si requiere reprogramar o cancelar una cita, deberá hacerlo con un mínimo de 3 horas de anticipación. Pasado este tiempo, el sistema bloqueará la opción para garantizar la eficiencia de nuestro taller.',
            ),
            _buildSection(context,
              title: '3. Responsabilidad sobre Objetos',
              icon: Icons.no_luggage_outlined,
              content:
                'Solicitamos amablemente retirar objetos de valor del vehículo al ingresarlo al taller. TF Centro Automotriz no se hace responsable por la pérdida de artículos personales no declarados durante el inventario de recepción.',
            ),
            _buildSection(context,
              title: '4. Garantía de Servicio',
              icon: Icons.shield_outlined,
              content:
                'Todo servicio de mano de obra cuenta con un periodo de garantía estipulado en su recibo final. Dicha garantía se invalida de forma inmediata si el vehículo es manipulado por talleres externos tras nuestra intervención.',
            ),

            const SizedBox(height: 24),
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String content,
    List<String>? bulletPoints,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
            if (content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                content,
                style: GoogleFonts.dmSans(
                  color: AppTheme.textMutedColor(context),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
            if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...bulletPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textMutedColor(context),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
