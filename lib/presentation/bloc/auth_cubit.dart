import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/backend_api_service.dart';
import '../../infrastructure/repositories/auth_repository.dart';

enum AuthStatus { checking, unauthenticated, authenticated, forbidden }

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthSession? session;
  final String? message;

  const AuthState({
    this.status = AuthStatus.checking,
    this.session,
    this.message,
  });

  bool get isAuthenticated => session != null;
  bool get isAdmin => session?.user.isAdmin == true;

  @override
  List<Object?> get props => [status, session, message];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  Future<AuthSession?>? _renewal;

  AuthCubit({
    AuthRepository? repository,
    AuthState initialState = const AuthState(),
  })  : repository = repository ?? AuthRepository(),
        super(initialState);

  Future<void> restoreSession() async {
    emit(const AuthState(status: AuthStatus.checking));
    try {
      final session = await repository.restore();
      emit(AuthState(
        status: session == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        session: session,
      ));
    } catch (_) {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        message: 'No fue posible comprobar la sesión.',
      ));
    }
  }

  Future<bool> signIn(String email, String password) async {
    emit(const AuthState(status: AuthStatus.checking));
    try {
      final session = await repository.signIn(email, password);
      emit(AuthState(status: AuthStatus.authenticated, session: session));
      return true;
    } on BackendApiException catch (error) {
      emit(AuthState(
        status: error.isForbidden
            ? AuthStatus.forbidden
            : AuthStatus.unauthenticated,
        message: error.message,
      ));
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String displayName,
    required String password,
  }) async {
    emit(const AuthState(status: AuthStatus.checking));
    try {
      await repository.register(
        email: email,
        displayName: displayName,
        password: password,
      );
      return signIn(email, password);
    } on BackendApiException catch (error) {
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        message: error.message,
      ));
      return false;
    }
  }

  Future<void> handleProtectedFailure(BackendApiException error) async {
    final session = state.session;
    if (error.isUnauthorized && session != null) {
      final renewed = await repository.renew(session);
      if (renewed != null) {
        emit(AuthState(status: AuthStatus.authenticated, session: renewed));
        return;
      }
      await signOut(message: 'Tu sesión expiró. Inicia sesión nuevamente.');
      return;
    }
    if (error.isForbidden) {
      emit(AuthState(
        status: AuthStatus.forbidden,
        session: session,
        message: error.message,
      ));
    }
  }

  void clearForbidden() {
    if (state.session == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } else {
      emit(AuthState(
        status: AuthStatus.authenticated,
        session: state.session,
      ));
    }
  }

  Future<AuthSession?> renewSession() {
    final activeRenewal = _renewal;
    if (activeRenewal != null) return activeRenewal;
    final future = _performRenewal();
    _renewal = future;
    future.whenComplete(() {
      if (identical(_renewal, future)) _renewal = null;
    });
    return future;
  }

  Future<AuthSession?> _performRenewal() async {
    final session = state.session;
    if (session == null) return null;
    final renewed = await repository.renew(session);
    if (renewed != null) {
      emit(AuthState(status: AuthStatus.authenticated, session: renewed));
    }
    return renewed;
  }

  Future<void> signOut({String? message}) async {
    final session = state.session;
    emit(const AuthState(status: AuthStatus.checking));
    try {
      await repository.signOut(session);
    } finally {
      emit(AuthState(status: AuthStatus.unauthenticated, message: message));
    }
  }
}
