import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../models/user_role.dart';
import '../../../widgets/unread_badge.dart';

class AdminChatTab extends StatefulWidget {
  const AdminChatTab({super.key});

  @override
  State<AdminChatTab> createState() => _AdminChatTabState();
}

class _AdminChatTabState extends State<AdminChatTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    if (adminProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filtrar administradores para no mostrarse a sí mismo y aplicar la búsqueda
    final chatUsers = adminProvider.users.where((u) {
      if (u.userRole == UserRole.admin) return false;
      if (_searchQuery.isEmpty) return true;
      return u.nombreCompleto.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                setState(() {
                  _searchQuery = value;
                });
              });
            },
            style: TextStyle(color: AppTheme.textColor(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              hintStyle: TextStyle(
                color: AppTheme.textMutedColor(context),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.textMutedColor(context),
                size: 20,
              ),
              filled: true,
              fillColor: AppTheme.inputColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.green),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: chatUsers.isEmpty
              ? Center(
                  child: Text(
                    'No hay usuarios disponibles',
                    style: TextStyle(color: AppTheme.textMutedColor(context)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: chatUsers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final user = chatUsers[index];

                    return _AdminChatUserRow(
                      user: user,
                      onTap: () {
                        context.push(
                          '/chat',
                          extra: {
                            'contactId': user.idUsuario,
                            'contactName': user.nombreCompleto,
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AdminChatUserRow extends StatelessWidget {
  const _AdminChatUserRow({required this.user, required this.onTap});

  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        child: Row(
          children: [
            _ChatUserAvatar(user: user),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.nombreCompleto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.rol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textMutedColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Selector<ChatProvider, int>(
              selector: (_, provider) => provider.unreadFor(user.idUsuario),
              builder: (context, unreadCount, child) {
                return UnreadBadge(count: unreadCount, compact: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatUserAvatar extends StatelessWidget {
  const _ChatUserAvatar({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(user.userRole);
    final initial = user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?';

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border, width: 0.8),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  _ChatAvatarColors _colorsFor(UserRole role) {
    switch (role) {
      case UserRole.mechanic:
        return _ChatAvatarColors(
          background: AppTheme.amber.withValues(alpha: 0.12),
          border: AppTheme.amber.withValues(alpha: 0.28),
          foreground: const Color(0xFFB45309),
        );
      case UserRole.secretary:
        return _ChatAvatarColors(
          background: AppTheme.blue.withValues(alpha: 0.10),
          border: AppTheme.blue.withValues(alpha: 0.24),
          foreground: const Color(0xFF2563EB),
        );
      case UserRole.client:
        return _ChatAvatarColors(
          background: AppTheme.green.withValues(alpha: 0.10),
          border: AppTheme.green.withValues(alpha: 0.24),
          foreground: AppTheme.greenDim,
        );
      case UserRole.admin:
      case UserRole.unknown:
        return _ChatAvatarColors(
          background: AppTheme.textMuted.withValues(alpha: 0.10),
          border: AppTheme.textMuted.withValues(alpha: 0.20),
          foreground: AppTheme.textMuted,
        );
    }
  }
}

class _ChatAvatarColors {
  const _ChatAvatarColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
