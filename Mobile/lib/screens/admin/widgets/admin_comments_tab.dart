import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/comment_provider.dart';

class AdminCommentsTab extends StatefulWidget {
  const AdminCommentsTab({super.key});

  @override
  State<AdminCommentsTab> createState() => _AdminCommentsTabState();
}

class _AdminCommentsTabState extends State<AdminCommentsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().loadComments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }

        if (provider.comments.isEmpty) {
          return const Center(child: Text('No hay comentarios todavía.', style: TextStyle(color: Colors.grey)));
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadComments(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.comments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final comment = provider.comments[index];
              return Card(
                color: AppTheme.cardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.borderColor(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            comment.usuario.nombre,
                            style: GoogleFonts.dmSans(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (starIndex) => Icon(
                                Icons.star_rounded,
                                color: starIndex < comment.rating
                                    ? AppTheme.amber
                                    : AppTheme.textMutedColor(context),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comment.comentario,
                        style: GoogleFonts.dmSans(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            _confirmDelete(context, provider, comment.idComentario);
                          },
                          icon: const Icon(Icons.delete, color: AppTheme.red, size: 18),
                          label: const Text('Eliminar', style: TextStyle(color: AppTheme.red)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CommentProvider provider, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Eliminar Comentario', style: TextStyle(color: AppTheme.textColor(context))),
        content: Text('¿Desea eliminar este comentario?', style: TextStyle(color: AppTheme.textMutedColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: AppTheme.textMutedColor(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteComment(idComentario: id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comentario eliminado'), backgroundColor: AppTheme.green));
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
