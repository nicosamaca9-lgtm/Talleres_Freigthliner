import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';

class CommentsTab extends StatelessWidget {
  const CommentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      key: ValueKey('comments'),
      title: 'Comentarios',
      icon: Icons.star_rounded,
      children: [
        _RatingCard(),
        ResponsiveCards(
          left: _CommentHistoryCard(),
          right: _SupportNoteCard(),
        ),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.star_rounded,
            title: 'Califica tu experiencia',
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              5,
              (index) => const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.star_rounded, color: AppTheme.green, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Text(
              'Escribe un comentario sobre el servicio recibido...',
              style: GoogleFonts.dmSans(color: AppTheme.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentHistoryCard extends StatelessWidget {
  const _CommentHistoryCard();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.history_rounded,
            title: 'Comentarios recientes',
          ),
          const SizedBox(height: 18),
          Text(
            'Excelente atencion y entrega puntual.',
            style: GoogleFonts.dmSans(
              color: AppTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orden OS-2026-062 - 5 estrellas',
            style: GoogleFonts.dmSans(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SupportNoteCard extends StatelessWidget {
  const _SupportNoteCard();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.support_agent_rounded,
            title: 'Seguimiento',
          ),
          const SizedBox(height: 18),
          Text(
            'Tus comentarios ayudan al equipo a mejorar cada entrega.',
            style: GoogleFonts.dmSans(
              color: AppTheme.textMuted,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          const ActionButton(
            label: 'Enviar comentario',
            icon: Icons.send_rounded,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}
