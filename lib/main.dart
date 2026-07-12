// ============================================================
// WarmiBot - main.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'domain/services/alarm_service.dart';
import 'presentation/bloc/assistant_bloc.dart';
import 'presentation/bloc/assistant_event.dart';
import 'presentation/pages/conversations_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/reminders_page.dart';
import 'presentation/widgets/bottom_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await _safeStartup();

  runApp(const WarmiBotApp());
}

Future<void> _safeStartup() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Permite abrir la app aunque el archivo .env no exista o no este incluido.
  }

  try {
    await initializeDateFormatting('es', null);
  } catch (_) {
    // Intl puede seguir usando formatos base si falla la inicializacion local.
  }

  try {
    await AlarmService.instance.init();
  } catch (_) {
    // Las notificaciones no deben impedir que la app principal arranque.
  }
}

class WarmiBotApp extends StatelessWidget {
  const WarmiBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AssistantBloc()..add(const InitAssistant()),
      child: MaterialApp(
        title: 'WarmiBot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _MainScaffold(),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.2,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _MainScaffold extends StatefulWidget {
  const _MainScaffold();

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _idx = 0;

  static const _pages = [
    HomePage(),
    ConversationsPage(),
    RemindersPage(),
    ProfilePage(),
  ];

  void _changePage(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() => _idx = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBody: true,
      drawer: _WarmiDrawer(onPageChange: _changePage),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.bgGradient,
          ),
        ),
        child: IndexedStack(index: _idx, children: _pages),
      ),
      bottomNavigationBar: WarmiBottomNav(
        currentIndex: _idx,
        onTap: _changePage,
      ),
    );
  }
}

class _WarmiDrawer extends StatelessWidget {
  final void Function(int) onPageChange;

  const _WarmiDrawer({required this.onPageChange});

  @override
  Widget build(BuildContext context) {
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
                gradient: LinearGradient(
                  colors: AppColors.avatarGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('W', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    'WarmiBot',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Text(
                    '"Warmi" - sabiduria amazonica',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _item(context, Icons.home_rounded, 'Inicio', 0),
            _item(context, Icons.chat_bubble_rounded, 'Conversaciones', 1),
            _item(context, Icons.notifications_rounded, 'Recordatorios', 2),
            _item(context, Icons.person_rounded, 'Perfil', 3),
            const Divider(color: Color(0x221B8A3C)),
            ListTile(
              leading: const Icon(
                Icons.wb_sunny_rounded,
                color: AppColors.accentGreen,
              ),
              title: const Text(
                'Clima en Tena',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              ),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<AssistantBloc>()
                    .add(const ProcessTextCommand('clima en Tena'));
                onPageChange(0);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.newspaper_rounded,
                color: AppColors.accentGreen,
              ),
              title: const Text(
                'Ultimas noticias',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              ),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<AssistantBloc>()
                    .add(const ProcessTextCommand('noticias'));
                onPageChange(0);
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'WarmiBot 2025\nUniversidad Estatal Amazonica\nTena, Napo, Ecuador',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.6,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentGreen, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      onTap: () {
        Navigator.pop(context);
        onPageChange(index);
      },
    );
  }
}
