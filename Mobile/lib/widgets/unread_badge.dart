import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count, this.compact = false});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final label = count > 99 ? '99+' : '$count';
    final minSize = compact ? 24.0 : 22.0;
    final backgroundColor = compact
        ? AppTheme.green.withValues(alpha: 0.10)
        : AppTheme.green;
    final foregroundColor = compact ? AppTheme.greenDim : Colors.black;
    final border = compact
        ? Border.all(color: AppTheme.green.withValues(alpha: 0.28), width: 0.8)
        : null;

    return Semantics(
      label: '$label mensajes no leidos',
      container: true,
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: border,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foregroundColor,
              fontSize: compact ? 11 : 11,
              fontWeight: compact ? FontWeight.w700 : FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
