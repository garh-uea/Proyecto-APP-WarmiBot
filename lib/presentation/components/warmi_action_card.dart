import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Acción compacta reutilizada por las ocho opciones rápidas de Inicio.
class WarmiActionCard extends StatelessWidget {
  final String icon;
  final String label;
  final String? semanticLabel;
  final VoidCallback onPressed;
  final bool selected;

  const WarmiActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.warmiColors;
    final spacing = context.warmiSpacing;
    final radii = context.warmiRadii;
    final sizes = context.warmiSizes;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.interactive : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.medium),
          side: BorderSide(
            color: selected ? colors.focus : colors.outline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sizes.minTouchTarget,
              minHeight: sizes.minTouchTarget,
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.xs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: spacing.xxs),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? colors.onInteractive
                              : colors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
