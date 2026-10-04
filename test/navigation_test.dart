import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/core/theme/app_theme.dart';
import 'package:warmibot/domain/services/backend_api_service.dart';
import 'package:warmibot/infrastructure/repositories/auth_repository.dart';
import 'package:warmibot/presentation/bloc/assistant_bloc.dart';
import 'package:warmibot/presentation/bloc/auth_cubit.dart';
import 'package:warmibot/presentation/navigation/app_router.dart';

class _NavigationAuthRepository extends AuthRepository {
  @override
  Future<void> signOut(AuthSession? session) async {}
}

void main() {
  testWidgets('una ruta protegida conserva el destino y redirige al login',
      (tester) async {
    final auth = AuthCubit(
      initialState: const AuthState(status: AuthStatus.unauthenticated),
    );
    final assistant = AssistantBloc();
    final router = createAppRouter(auth);
    addTearDown(() async {
      router.dispose();
      await auth.close();
      await assistant.close();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: assistant),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    router.go('/conversaciones/15');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.login);
    expect(
      router.state.uri.queryParameters['from'],
      '/conversaciones/15',
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('la sesión se mantiene al navegar y el cierre protege la ruta',
      (tester) async {
    const session = AuthSession(
      user: BackendUser(
        id: 8,
        email: 'maria@example.com',
        displayName: 'María',
        role: 'user',
        isActive: true,
      ),
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    final auth = AuthCubit(
      repository: _NavigationAuthRepository(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        session: session,
      ),
    );
    final assistant = AssistantBloc();
    final router = createAppRouter(auth);
    addTearDown(() async {
      router.dispose();
      await auth.close();
      await assistant.close();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: assistant),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    router.go(AppRoutes.profile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.state.uri.path, AppRoutes.profile);
    expect(auth.state.session?.user.displayName, 'María');
    expect(find.text('maria@example.com'), findsOneWidget);

    await auth.signOut();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.state.uri.path, AppRoutes.login);

    router.go(AppRoutes.reminders);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.state.uri.path, AppRoutes.login);
    expect(router.state.uri.queryParameters['from'], AppRoutes.reminders);
  });
}
