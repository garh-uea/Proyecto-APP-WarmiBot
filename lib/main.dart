import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'infrastructure/repositories/auth_repository.dart';
import 'infrastructure/repositories/reminders_repository.dart';
import 'presentation/bloc/assistant_bloc.dart';
import 'presentation/bloc/assistant_event.dart';
import 'presentation/bloc/auth_cubit.dart';
import 'presentation/navigation/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('WarmiBot inició sin .env; se usarán valores de respaldo.');
  }
  await initializeDateFormatting('es', null);
  runApp(const WarmiBotApp());
}

class WarmiBotApp extends StatefulWidget {
  final bool initializeAssistant;
  final bool initializeAuth;
  final Widget? home;

  const WarmiBotApp({
    super.key,
    this.initializeAssistant = true,
    this.initializeAuth = true,
    this.home,
  });

  @override
  State<WarmiBotApp> createState() => _WarmiBotAppState();
}

class _WarmiBotAppState extends State<WarmiBotApp> {
  late final AssistantBloc _assistantBloc;
  late final AuthCubit _authCubit;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _assistantBloc = AssistantBloc();
    if (widget.initializeAssistant) {
      _assistantBloc.add(const InitAssistant());
    }
    _authCubit = AuthCubit();
    _authSubscription = _authCubit.stream.listen(_handleAuthState);
    if (widget.initializeAuth && widget.home == null) {
      _authCubit.restoreSession();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _authSubscription?.cancel();
    _assistantBloc.close();
    _authCubit.close();
    super.dispose();
  }

  void _handleAuthState(AuthState state) {
    _syncTimer?.cancel();
    final session = state.session;
    if (session == null) return;
    unawaited(
      _synchronizeSession(session),
    );
    _syncTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_synchronizeSession(session)),
    );
  }

  Future<void> _synchronizeSession(AuthSession session) async {
    final result = await RemindersRepository.instance.synchronize(
      session.accessToken,
    );
    if (!result.authenticationRequired) return;
    final renewed = await _authCubit.renewSession();
    if (renewed != null) {
      await RemindersRepository.instance.synchronize(renewed.accessToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _assistantBloc),
        BlocProvider.value(value: _authCubit),
      ],
      child: widget.home != null
          ? MaterialApp(
              title: 'WarmiBot',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              home: widget.home,
            )
          : MaterialApp.router(
              title: 'WarmiBot',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              routerConfig: createAppRouter(_authCubit),
            ),
    );
  }
}
