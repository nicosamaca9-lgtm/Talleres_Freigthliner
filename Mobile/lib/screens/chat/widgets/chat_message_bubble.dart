import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/message_model.dart';
import 'message_status_icon.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.debugOnBuild,
  });

  final MessageModel message;
  final bool isMe;

  @visibleForTesting
  final VoidCallback? debugOnBuild;

  @override
  Widget build(BuildContext context) {
    debugOnBuild?.call();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isMe
        ? (isDark
              ? AppTheme.green.withValues(alpha: 0.18)
              : const Color(0xFFE8F8EF))
        : AppTheme.cardColor(context);
    final borderColor = isMe
        ? (isDark
              ? AppTheme.green.withValues(alpha: 0.34)
              : const Color(0xFFCBEED8))
        : AppTheme.borderColor(context);
    final textColor = AppTheme.textColor(context);
    final timeColor = AppTheme.textMutedColor(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(isMe ? 56 : 8, 3, isMe ? 8 : 56, 3),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(14).copyWith(
                  bottomRight: isMe ? const Radius.circular(5) : null,
                  bottomLeft: !isMe ? const Radius.circular(5) : null,
                ),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    textAlign: TextAlign.start,
                    softWrap: true,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: timeColor,
                          fontSize: 11,
                          height: 1,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        MessageStatusIcon(status: message.status, size: 14),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? rawTimestamp) {
    if (rawTimestamp == null || rawTimestamp.isEmpty) return '';

    final parsed = DateTime.tryParse(rawTimestamp);
    if (parsed == null) return '';

    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(parsed.hour)}:${twoDigits(parsed.minute)}';
  }
}
