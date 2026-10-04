// ============================================================
// WarmiBot — Grid de Acciones Rápidas (8 botones del diseño)
// ============================================================

import 'package:flutter/material.dart';
import '../../core/constants/commands.dart';
import '../../core/theme/app_theme.dart';
import '../components/warmi_action_card.dart';

class QuickActionsGrid extends StatelessWidget {
  final void Function(String command) onAction;

  static const _accentColors = [
    AppColors.accentTeal,
    AppColors.accentAmber,
    AppColors.accentGreen,
    AppColors.accentCoral,
  ];

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
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: Commands.quickActions.length,
            itemBuilder: (_, i) {
              final action = Commands.quickActions[i];
              return WarmiActionCard(
                icon: action.icon,
                label: action.label,
                accentColor: _accentColors[i % _accentColors.length],
                semanticLabel: '${action.label}. Ejecutar acción rápida',
                onPressed: () => onAction(action.command),
              );
            },
          ),
        ),
      ],
    );
  }
}
