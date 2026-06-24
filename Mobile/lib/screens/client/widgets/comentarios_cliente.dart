import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';
import '../../../providers/comment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/comment_model.dart';

class CommentsTab extends StatefulWidget {
  const CommentsTab({super.key});

  @override
  State<CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<CommentsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().loadComments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      key: ValueKey('comments'),
      title: 'Comentarios',
      icon: Icons.star_rounded,
      children: [
        _SupportNoteCard(),
        _CommentListCard(),
      ],
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
            title: 'Tus comentarios importan',
          ),
          const SizedBox(height: 18),
          Text(
            'Tus comentarios ayudan al equipo a mejorar cada entrega. Cuéntanos tu experiencia.',
            style: GoogleFonts.dmSans(
              color: AppTheme.textMuted,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          ActionButton(
            label: 'Crear comentario',
            icon: Icons.add_comment_rounded,
            isPrimary: true,
            onPressed: () {
              _showCommentModal(context);
            },
          ),
        ],
      ),
    );
  }
}

class _CommentListCard extends StatelessWidget {
  const _CommentListCard();

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
          Consumer2<CommentProvider, AuthProvider>(
            builder: (context, commentProvider, authProvider, child) {
              if (commentProvider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: AppTheme.green),
                  ),
                );
              }

              if (commentProvider.comments.isEmpty) {
                return Text(
                  'No hay comentarios todavía.',
                  style: GoogleFonts.dmSans(color: AppTheme.textMuted),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commentProvider.comments.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xFF2A2A2A)),
                itemBuilder: (context, index) {
                  final comment = commentProvider.comments[index];
                  final isOwner = comment.idUsuario == authProvider.userId;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment.usuario.nombre,
                                  style: GoogleFonts.dmSans(
                                    color: AppTheme.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: List.generate(
                                    5,
                                    (starIndex) => Icon(
                                      Icons.star_rounded,
                                      color: starIndex < comment.rating
                                          ? AppTheme.green
                                          : AppTheme.textDim,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isOwner)
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: AppTheme.textMuted, size: 20),
                                onPressed: () {
                                  _showCommentModal(context, comment: comment);
                                },
                              )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comment.comentario,
                          style: GoogleFonts.dmSans(
                            color: AppTheme.text,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

void _showCommentModal(BuildContext context, {CommentModel? comment}) {
  showDialog(
    context: context,
    builder: (context) {
      return _CommentDialog(comment: comment);
    },
  );
}

class _CommentDialog extends StatefulWidget {
  final CommentModel? comment;
  const _CommentDialog({this.comment});

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  late int _rating;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _rating = widget.comment?.rating ?? 5;
    _controller = TextEditingController(text: widget.comment?.comentario ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final commentProvider = context.read<CommentProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    
    if (userId == null) return;
    
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    bool success;
    if (widget.comment == null) {
      success = await commentProvider.createComment(
        idUsuario: userId,
        rating: _rating,
        comentario: text,
      );
    } else {
      success = await commentProvider.updateComment(
        idComentario: widget.comment!.idComentario,
        rating: _rating,
        comentario: text,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF171717),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.comment == null ? 'Nuevo comentario' : 'Editar comentario',
              style: GoogleFonts.dmSans(
                color: AppTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star_rounded,
                      color: index < _rating ? AppTheme.green : AppTheme.textDim,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              style: GoogleFonts.dmSans(color: AppTheme.text),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Escribe tu comentario...',
                hintStyle: GoogleFonts.dmSans(color: AppTheme.textDim),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.green),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.dmSans(color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<CommentProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.green,
                          strokeWidth: 2,
                        ),
                      );
                    }
                    return ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: AppTheme.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Guardar',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
