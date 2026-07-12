// ============================================================
// WarmiBot — Grid de Acciones Rápidas (8 botones del diseño)
// ============================================================

import 'package:flutter/material.dart';
import '../../core/constants/commands.dart';
import '../../core/theme/app_theme.dart';

class QuickActionsGrid extends StatelessWidget {
  final void Function(String command) onAction;

  const QuickActionsGrid({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'Acciones rápidas',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textSecondary, letterSpacing: 0.5),
          ),
        ),
        SizedBox(
          height: 170,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   4,
              mainAxisSpacing:  10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: Commands.quickActions.length,
            itemBuilder: (_, i) {
              final action = Commands.quickActions[i];
              return _ActionButton(
                action: action,
                onTap: () => onAction(action.command),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final QuickAction action;
  final VoidCallback onTap;

  const _ActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(action.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: const TextStyle(
                fontSize:   10,
                color:      AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
