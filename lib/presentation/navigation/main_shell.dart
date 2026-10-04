import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/assistant_bloc.dart';
import '../bloc/assistant_event.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/bottom_nav.dart';

class MainShell extends StatelessWidget {
  static const destinations = [
    '/inicio',
    '/conversaciones',
    '/recordatorios',
    '/perfil',
  ];

  final String location;
  final Widget child;

  const MainShell({super.key, required this.location, required this.child});

  int get _currentIndex {
    final index = destinations.indexWhere(
      (route) => location == route || location.startsWith('$route/'),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBody: false,
      drawer: const _WarmiDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.bgGradient,
          ),
        ),
        child: child,
      ),
      bottomNavigationBar: WarmiBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            context.read<AssistantBloc>().add(const ShowHomeMenu());
          }
          context.go(destinations[index]);
        },
      ),
    );
  }
}

class _WarmiDrawer extends StatelessWidget {
  const _WarmiDrawer();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.session?.user;
    return Drawer(
      backgroundColor: AppColors.bgCard,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.avatarGradient),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 36)),
                  Text(
                    user?.displayName ?? 'WarmiBot',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    user?.email ?? 'Asistente amazónico',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _item(context, Icons.home_rounded, 'Inicio', '/inicio'),
            _item(context, Icons.chat_bubble_rounded, 'Conversaciones',
                '/conversaciones'),
            _item(context, Icons.notifications_rounded, 'Recordatorios',
                '/recordatorios'),
            _item(context, Icons.person_rounded, 'Perfil', '/perfil'),
            if (user?.isAdmin == true)
              _item(context, Icons.admin_panel_settings_outlined, 'Diagnóstico',
                  '/diagnosticos'),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.wb_sunny_rounded,
                  color: AppColors.accentGreen),
              title: const Text('Clima en Tena'),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<AssistantBloc>()
                    .add(const ProcessTextCommand('clima en Tena'));
                context.go('/inicio');
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper_rounded,
                  color: AppColors.accentGreen),
              title: const Text('Últimas noticias'),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<AssistantBloc>()
                    .add(const ProcessTextCommand('noticias'));
                context.go('/inicio');
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthCubit>().signOut(
                      message:
                          'Sesión cerrada. Credenciales y datos locales eliminados.',
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentGreen),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        if (route == '/inicio') {
          context.read<AssistantBloc>().add(const ShowHomeMenu());
        }
        context.go(route);
      },
    );
  }
}
