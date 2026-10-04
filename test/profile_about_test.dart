import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/core/theme/app_theme.dart';
import 'package:warmibot/domain/services/backend_api_service.dart';
import 'package:warmibot/infrastructure/repositories/auth_repository.dart';
import 'package:warmibot/presentation/bloc/auth_cubit.dart';
import 'package:warmibot/presentation/pages/conversations_page.dart';

void main() {
  testWidgets('Perfil muestra la identidad y descripción de WarmiBot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const session = AuthSession(
      user: BackendUser(
        id: 12,
        email: 'grupo12@uea.edu.ec',
        displayName: 'Grupo 12',
        role: 'user',
        isActive: true,
      ),
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    final auth = AuthCubit(
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        session: session,
      ),
    );
    addTearDown(auth.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfilePage(),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Acerca de WarmiBot'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Acerca de WarmiBot'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'WarmiBot es una aplicación desarrollada por estudiantes de la '
        'Universidad Estatal Amazónica. Combina inteligencia, accesibilidad '
        'y servicios digitales en una experiencia inspirada en la Amazonía '
        'ecuatoriana.',
      ),
      findsOneWidget,
    );
    expect(find.text('Entendido'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('WarmiBot © 2026 · Ecuador'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('WarmiBot © 2026 · Ecuador'), findsOneWidget);
  });
}
