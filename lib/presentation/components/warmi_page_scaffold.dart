import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Estructura consistente para pantallas del catálogo.
class WarmiPageScaffold extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;
  final List<Widget> actions;

  const WarmiPageScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.warmiColors;
    final spacing = context.warmiSpacing;
    final radii = context.warmiRadii;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.md,
            spacing.sm,
            spacing.md,
            spacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                container: true,
                label: '$title. $description',
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(radii.large),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(spacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: spacing.xxs),
                                Text(
                                  description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          if (actions.isNotEmpty) ...[
                            SizedBox(width: spacing.xs),
                            ...actions,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing.md),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
