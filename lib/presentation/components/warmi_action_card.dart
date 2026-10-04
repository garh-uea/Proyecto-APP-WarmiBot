import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Acción compacta reutilizada por las ocho opciones rápidas de Inicio.
class WarmiActionCard extends StatelessWidget {
  final String icon;
  final String label;
  final String? semanticLabel;
  final VoidCallback onPressed;
  final bool selected;
  final Color? accentColor;

  const WarmiActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.selected = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.warmiColors;
    final spacing = context.warmiSpacing;
    final radii = context.warmiRadii;
    final sizes = context.warmiSizes;
    final accent = accentColor ?? colors.interactive;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: selected ? 0.52 : 0.30),
              colors.surface.withValues(alpha: 0.94),
            ],
          ),
          borderRadius: BorderRadius.circular(radii.medium),
          border: Border.all(
            color: selected ? colors.focus : accent.withValues(alpha: 0.58),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.16),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radii.medium),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: sizes.minTouchTarget,
                minHeight: sizes.minTouchTarget,
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing.xxs),
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
                                : colors.textPrimary,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
