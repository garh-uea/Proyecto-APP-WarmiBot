import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/chat_message.dart';

/// Presenta un mensaje sin consultar datos ni decidir navegación.
class WarmiMessageCard extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onLongPress;

  const WarmiMessageCard({
    super.key,
    required this.message,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.warmiColors;
    final spacing = context.warmiSpacing;
    final radii = context.warmiRadii;
    final sizes = context.warmiSizes;
    final isUser = message.sender == MessageSender.user;
    final sender = isUser ? 'Tú' : 'WarmiBot';
    final time = DateFormat('h:mm a').format(message.timestamp);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: isUser ? colors.interactive : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(radii.large),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: sizes.avatarSmall / 2,
              backgroundColor: isUser ? colors.surface : colors.interactive,
              foregroundColor: colors.textPrimary,
              child: Text(
                isUser ? 'T' : 'W',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sender,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      SizedBox(width: spacing.xs),
                      Text(time, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  Text(message.text,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      label: 'Mensaje de $sender a las $time: ${message.text}',
      hint: onLongPress == null ? null : 'Mantén presionado para ver opciones',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.only(bottom: spacing.sm),
          child: onLongPress == null
              ? card
              : InkWell(
                  onLongPress: onLongPress,
                  borderRadius: BorderRadius.circular(radii.large),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: sizes.minTouchTarget,
                    ),
                    child: card,
                  ),
                ),
        ),
      ),
    );
  }
}
