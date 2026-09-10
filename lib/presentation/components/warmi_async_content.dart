import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum WarmiContentState { loading, empty, error, content }

/// Resuelve estados de datos sin conocer servicios, endpoints ni navegación.
class WarmiAsyncContent extends StatelessWidget {
  final WarmiContentState state;
  final WidgetBuilder contentBuilder;
  final String loadingLabel;
  final String emptyTitle;
  final String emptyMessage;
  final String errorTitle;
  final String errorMessage;
  final String retryLabel;
  final VoidCallback? onRetry;

  const WarmiAsyncContent({
    super.key,
    required this.state,
    required this.contentBuilder,
    this.loadingLabel = 'Cargando contenido',
    this.emptyTitle = 'Todavía no hay contenido',
    this.emptyMessage =
        'Los elementos aparecerán aquí cuando estén disponibles.',
    this.errorTitle = 'No pudimos cargar el contenido',
    this.errorMessage = 'Comprueba la conexión e inténtalo nuevamente.',
    this.retryLabel = 'Reintentar',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case WarmiContentState.loading:
        return _StatePanel(
          semanticLabel: loadingLabel,
          icon: const CircularProgressIndicator(),
          title: loadingLabel,
        );
      case WarmiContentState.empty:
        return _StatePanel(
          semanticLabel: '$emptyTitle. $emptyMessage',
          icon: Icon(
            Icons.forum_outlined,
            size: context.warmiSizes.stateIcon,
            color: context.warmiColors.textSecondary,
          ),
          title: emptyTitle,
          message: emptyMessage,
        );
      case WarmiContentState.error:
        return _StatePanel(
          semanticLabel: '$errorTitle. $errorMessage',
          icon: Icon(
            Icons.error_outline_rounded,
            size: context.warmiSizes.stateIcon,
            color: context.warmiColors.error,
          ),
          title: errorTitle,
          message: errorMessage,
          action: onRetry == null
              ? null
              : ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(retryLabel),
                ),
        );
      case WarmiContentState.content:
        return contentBuilder(context);
    }
  }
}

class _StatePanel extends StatelessWidget {
  final String semanticLabel;
  final Widget icon;
  final String title;
  final String? message;
  final Widget? action;

  const _StatePanel({
    required this.semanticLabel,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.warmiSpacing;
    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                SizedBox(height: spacing.md),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  SizedBox(height: spacing.xs),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null) ...[
                  SizedBox(height: spacing.lg),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
