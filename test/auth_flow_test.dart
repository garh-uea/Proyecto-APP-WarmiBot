import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/core/theme/app_theme.dart';
import 'package:warmibot/domain/services/backend_api_service.dart';
import 'package:warmibot/infrastructure/repositories/auth_repository.dart';
import 'package:warmibot/presentation/bloc/auth_cubit.dart';
import 'package:warmibot/presentation/forms/auth_validators.dart';
import 'package:warmibot/presentation/pages/auth_pages.dart';

const _user = BackendUser(
  id: 7,
  email: 'ana@example.com',
  displayName: 'Ana',
  role: 'user',
  isActive: true,
);

const _session = AuthSession(
  user: _user,
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
);

class _FakeAuthRepository extends AuthRepository {
  bool signedOut = false;

  @override
  Future<AuthSession> signIn(String email, String password) async => _session;

  @override
  Future<void> signOut(AuthSession? session) async {
    signedOut = true;
  }
}

void main() {
  group('validaciones de autenticación', () {
    test('rechaza campos vacíos y correos incompletos', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('usuario@'), isNotNull);
      expect(AuthValidators.loginPassword(''), isNotNull);
      expect(AuthValidators.email('usuario@correo.com'), isNull);
    });

    test('registro exige nombre y contraseña mínima', () {
      expect(AuthValidators.displayName('A'), isNotNull);
      expect(AuthValidators.registrationPassword('corta'), isNotNull);
      expect(AuthValidators.displayName('Ana'), isNull);
      expect(AuthValidators.registrationPassword('ClaveSegura123'), isNull);
    });
  });

  test('AuthCubit conserva el usuario y elimina la sesión al salir', () async {
    final repository = _FakeAuthRepository();
    final cubit = AuthCubit(
      repository: repository,
      initialState: const AuthState(status: AuthStatus.unauthenticated),
    );
    addTearDown(cubit.close);

    expect(await cubit.signIn('ana@example.com', 'ClaveSegura123'), isTrue);
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.session?.user.displayName, 'Ana');

    await cubit.signOut();
    expect(repository.signedOut, isTrue);
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.session, isNull);
  });

  testWidgets('el formulario muestra mensajes comprensibles', (tester) async {
    final cubit = AuthCubit(
      repository: _FakeAuthRepository(),
      initialState: const AuthState(status: AuthStatus.unauthenticated),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginPage(),
        ),
      ),
    );
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
  });
}
