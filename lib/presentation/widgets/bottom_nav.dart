// ============================================================
// WarmiBot — Bottom Navigation Bar
// ============================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WarmiBottomNav extends StatelessWidget {
  final int    currentIndex;
  final void Function(int) onTap;

  const WarmiBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          top: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap:        onTap,
        backgroundColor: Colors.transparent,
        elevation:    0,
        selectedItemColor:   AppColors.accentGreen,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:   const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon:  Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon:  Icon(Icons.chat_bubble_outline_rounded),
            label: 'Conversaciones',
          ),
          BottomNavigationBarItem(
            icon:  Icon(Icons.notifications_none_rounded),
            label: 'Recordatorios',
          ),
          BottomNavigationBarItem(
            icon:  Icon(Icons.person_outline_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
