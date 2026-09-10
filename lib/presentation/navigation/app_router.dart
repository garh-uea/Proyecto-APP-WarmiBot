import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_cubit.dart';
import '../pages/auth_pages.dart';
import '../pages/conversations_page.dart';
import '../pages/home_page.dart';
import '../pages/reminders_page.dart';
import '../pages/system_pages.dart';
import 'main_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/registro';
  static const apiStatus = '/estado-api';
  static const loading = '/cargando';
  static const forbidden = '/acceso-restringido';
  static const home = '/inicio';
  static const conversations = '/conversaciones';
  static const reminders = '/recordatorios';
  static const profile = '/perfil';
  static const diagnostics = '/diagnosticos';
}

GoRouter createAppRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _RouterRefresh(authCubit.stream),
    redirect: (context, state) {
      final auth = authCubit.state;
      final location = state.uri.path;
      final isPublic = {
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.apiStatus,
        AppRoutes.loading,
      }.contains(location);

      if (auth.status == AuthStatus.checking) {
        if (isPublic) return null;
        final from = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.loading}?from=$from';
      }
      if (!auth.isAuthenticated) {
        if (location == AppRoutes.loading) {
          final requested = state.uri.queryParameters['from'] ?? AppRoutes.home;
          return '${AppRoutes.login}?from=${Uri.encodeComponent(requested)}';
        }
        if (isPublic) return null;
        final from = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.login}?from=$from';
      }
      if (auth.status == AuthStatus.forbidden &&
          location != AppRoutes.forbidden) {
        return AppRoutes.forbidden;
      }
      if (location == AppRoutes.diagnostics && !auth.isAdmin) {
        return AppRoutes.forbidden;
      }
      if (location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.loading) {
        final requested = state.uri.queryParameters['from'];
        return requested == null || requested.isEmpty
            ? AppRoutes.home
            : requested;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => AppRoutes.home),
      GoRoute(
        path: AppRoutes.loading,
        builder: (_, __) => const SessionLoadingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) => LoginPage(
          returnLocation: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.apiStatus,
        builder: (_, __) => const ApiStatusPage(),
      ),
      GoRoute(
        path: AppRoutes.forbidden,
        builder: (_, __) => const ForbiddenPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.conversations,
            builder: (_, __) => const ConversationsPage(),
            routes: [
              GoRoute(
                path: ':conversationId',
                builder: (_, state) => ProtectedResourcePage(
                  title: 'Detalle de conversación',
                  endpoint:
                      '/api/v1/conversations/${state.pathParameters['conversationId']}',
                  resourceId: state.pathParameters['conversationId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.reminders,
            builder: (_, __) => const RemindersPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/trabajos/:jobId',
            builder: (_, state) => ProtectedResourcePage(
              title: 'Estado del resumen',
              endpoint: '/api/v1/jobs/${state.pathParameters['jobId']}',
              resourceId: state.pathParameters['jobId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.diagnostics,
            builder: (_, __) => const ProtectedResourcePage(
              title: 'Diagnóstico administrativo',
              endpoint: '/api/v1/diagnostics/cache',
              resourceId: 'cache',
            ),
          ),
        ],
      ),
    ],
  );
}

class _RouterRefresh extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _RouterRefresh(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
