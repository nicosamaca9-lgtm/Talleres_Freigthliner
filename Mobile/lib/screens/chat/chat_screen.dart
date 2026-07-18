import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final dynamic contactId;
  final String contactName;

  const ChatScreen({
    super.key,
    required this.contactId,
    required this.contactName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatProvider _chatProvider;
  late final int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _currentUserId = context.read<AuthProvider>().userId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.connect();
      _chatProvider.setActiveContact(widget.contactId);
      _chatProvider.loadHistory(widget.contactId);
    });

    // Paginación: cargar más al llegar al tope (scroll inverso = "final" de la lista)
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels != 0) {
        _chatProvider.loadMoreHistory(widget.contactId);
      }
    });
  }

  @override
  void dispose() {
    _chatProvider.setActiveContact(null);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!_chatProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión. Reintentando...')),
      );
      return;
    }

    _chatProvider.sendMessage(widget.contactId, text, senderId: _currentUserId);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        foregroundColor: AppTheme.textColor(context),
        title: Text(widget.contactName),
      ),
      body: Column(
        children: [
          // Banner de desconexión
          Selector<ChatProvider, bool>(
            selector: (_, provider) => provider.isConnected,
            builder: (context, isConnected, child) {
              if (isConnected) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.orange[800],
                child: const Text(
                  'Reconectando...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              );
            },
          ),
          Expanded(
            child: _ChatMessagesView(
              scrollController: _scrollController,
              currentUserId: _currentUserId,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLength: 2000,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      style: TextStyle(color: AppTheme.textColor(context)),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(
                          color: AppTheme.textMutedColor(context),
                        ),
                        counterText: '', // Oculta el contador "0/2000"
                        filled: true,
                        fillColor: AppTheme.inputColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.green,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessagesView extends StatelessWidget {
  const _ChatMessagesView({
    required this.scrollController,
    required this.currentUserId,
  });

  final ScrollController scrollController;
  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Selector<ChatProvider, _MessagesViewportState>(
      selector: (_, provider) => _MessagesViewportState(
        isLoadingHistory: provider.isLoadingHistory,
        hasMoreHistory: provider.hasMoreHistory,
        messageIds: provider.messageIds,
      ),
      builder: (context, state, child) {
        if (state.isLoadingHistory && state.messageIds.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          clipBehavior: Clip.hardEdge,
          reverse: true,
          itemCount: state.messageIds.length + (state.hasMoreHistory ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.messageIds.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final messageId = state.messageIds[index];
            return _ChatMessageListItem(
              key: ValueKey(messageId),
              messageId: messageId,
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }
}

class _ChatMessageListItem extends StatelessWidget {
  const _ChatMessageListItem({
    super.key,
    required this.messageId,
    required this.currentUserId,
  });

  final int messageId;
  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Selector<ChatProvider, MessageModel?>(
      selector: (_, provider) => provider.messageById(messageId),
      builder: (context, message, child) {
        if (message == null) return const SizedBox.shrink();

        return ChatMessageBubble(
          message: message,
          isMe: message.senderId == currentUserId,
        );
      },
    );
  }
}

class _MessagesViewportState {
  const _MessagesViewportState({
    required this.isLoadingHistory,
    required this.hasMoreHistory,
    required this.messageIds,
  });

  final bool isLoadingHistory;
  final bool hasMoreHistory;
  final List<int> messageIds;

  @override
  bool operator ==(Object other) {
    return other is _MessagesViewportState &&
        other.isLoadingHistory == isLoadingHistory &&
        other.hasMoreHistory == hasMoreHistory &&
        listEquals(other.messageIds, messageIds);
  }

  @override
  int get hashCode =>
      Object.hash(isLoadingHistory, hasMoreHistory, Object.hashAll(messageIds));
}
