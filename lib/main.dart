// ============================================================
// WarmiBot — main.dart
// Punto de entrada · Flutter 3.44 · Dart 3.x
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'presentation/bloc/assistant_bloc.dart';
import 'presentation/bloc/assistant_event.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/conversations_page.dart';
import 'presentation/pages/reminders_page.dart';
import 'presentation/widgets/bottom_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('es', null);

  runApp(const WarmiBotApp());
}

class WarmiBotApp extends StatelessWidget {
  final bool initializeAssistant;
  final Widget? home;

  const WarmiBotApp({
    super.key,
    this.initializeAssistant = true,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = AssistantBloc();
        if (initializeAssistant) bloc.add(const InitAssistant());
        return bloc;
      },
      child: MaterialApp(
        title: 'WarmiBot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: home ?? const _MainScaffold(),
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBody: true,
      drawer: _WarmiDrawer(onPageChange: (i) => setState(() => _idx = i)),
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
        onTap: (i) => setState(() => _idx = i),
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
                    const Text('🌿', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text('WarmiBot',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                    const Text('"Warmi" — sabiduría amazónica',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
            ),
            const SizedBox(height: 8),
            _item(context, Icons.home_rounded, 'Inicio', 0),
            _item(context, Icons.chat_bubble_rounded, 'Conversaciones', 1),
            _item(context, Icons.notifications_rounded, 'Recordatorios', 2),
            //_item(context, Icons.person_rounded, 'Perfil', 3),
            const Divider(color: Color(0x221B8A3C)),
            ListTile(
              leading: const Icon(Icons.wb_sunny_rounded,
                  color: AppColors.accentGreen),
              title: const Text('Clima en Tena',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<AssistantBloc>()
                    .add(const ProcessTextCommand('clima en Tena'));
                onPageChange(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper_rounded,
                  color: AppColors.accentGreen),
              title: const Text('Últimas noticias',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
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
                'WarmiBot © 2025\nUniversidad Estatal Amazónica\nTena, Napo, Ecuador 🇪🇨',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textMuted, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext ctx, IconData icon, String label, int idx) =>
      ListTile(
        leading: Icon(icon, color: AppColors.accentGreen, size: 22),
        title: Text(label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        onTap: () {
          Navigator.pop(ctx);
          onPageChange(idx);
        },
      );
}
