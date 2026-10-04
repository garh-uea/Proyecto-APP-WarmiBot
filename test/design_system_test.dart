import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/core/theme/app_theme.dart';
import 'package:warmibot/domain/models/chat_message.dart';
import 'package:warmibot/presentation/components/warmi_action_card.dart';
import 'package:warmibot/presentation/components/warmi_async_content.dart';
import 'package:warmibot/presentation/pages/conversations_page.dart';

final _captureTime = DateTime(2026, 8, 22, 10, 30);

final _messages = <ChatMessage>[
  ChatMessage(
    id: '1',
    text: '¿Qué actividades tengo pendientes para hoy?',
    sender: MessageSender.user,
    timestamp: _captureTime,
  ),
  ChatMessage(
    id: '2',
    text: 'Tienes una exposición y un recordatorio programado para las 15:00.',
    sender: MessageSender.bot,
    timestamp: _captureTime,
  ),
];

ThemeData _captureTheme() {
  final base = AppTheme.darkTheme;
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: base.elevatedButtonTheme.style?.copyWith(
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

Widget _preview({
  required WarmiContentState state,
  List<ChatMessage> messages = const [],
  double textScale = 1,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _captureTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.bgGradient),
      ),
      child: ConversationsView(
        messages: messages,
        contentState: state,
        errorMessage: 'No fue posible recuperar las conversaciones.',
        onRetry: () {},
        onClear: messages.isEmpty ? null : () {},
      ),
    ),
  );
}

Future<void> _pumpAt(
  WidgetTester tester, {
  required Size size,
  required WarmiContentState state,
  List<ChatMessage> messages = const [],
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _preview(state: state, messages: messages, textScale: textScale),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? r'C:\flutter';
    final fontFile = File(
      '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}artifacts${Platform.pathSeparator}material_fonts'
      '${Platform.pathSeparator}roboto-regular.ttf',
    );
    final bytes = await fontFile.readAsBytes();
    Future<ByteData> fontData() async => ByteData.sublistView(bytes);
    await (FontLoader('Lato')..addFont(fontData())).load();
    await (FontLoader('Poppins')..addFont(fontData())).load();
    await (FontLoader('Roboto')..addFont(fontData())).load();
  });

  testWidgets('ConversationsView no desborda a 360 dp con fuente al 150 %',
      (tester) async {
    await _pumpAt(
      tester,
      size: const Size(360, 800),
      state: WarmiContentState.content,
      messages: _messages,
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp('Conversaciones')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Mensaje de Tú')), findsOneWidget);
    expect(
        find.bySemanticsLabel(RegExp('Mensaje de WarmiBot')), findsOneWidget);
  });

  testWidgets('el botón Reintentar conserva un área táctil mínima de 48 dp',
      (tester) async {
    await _pumpAt(
      tester,
      size: const Size(360, 800),
      state: WarmiContentState.error,
    );

    final size = tester
        .getSize(find.widgetWithText(ElevatedButton, 'Intentar nuevamente'));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel(RegExp('No se pudo mostrar')), findsOneWidget);
  });

  testWidgets('WarmiActionCard expone etiqueta y objetivo táctil',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Center(
          child: SizedBox(
            width: 96,
            child: WarmiActionCard(
              icon: '☀️',
              label: 'Clima',
              semanticLabel: 'Consultar el clima',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(WarmiActionCard));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Consultar el clima'), findsOneWidget);
  });

  group('capturas del informe', () {
    testWidgets('contenido a 360 dp', (tester) async {
      await _pumpAt(
        tester,
        size: const Size(360, 800),
        state: WarmiContentState.content,
        messages: _messages,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/conversaciones_360.png'),
      );
    });

    testWidgets('contenido a 600 dp', (tester) async {
      await _pumpAt(
        tester,
        size: const Size(600, 960),
        state: WarmiContentState.content,
        messages: _messages,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/conversaciones_600.png'),
      );
    });

    testWidgets('contenido a 360 dp y fuente 150 %', (tester) async {
      await _pumpAt(
        tester,
        size: const Size(360, 800),
        state: WarmiContentState.content,
        messages: _messages,
        textScale: 1.5,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/conversaciones_fuente_150.png'),
      );
    });

    for (final entry in const {
      'cargando': WarmiContentState.loading,
      'vacio': WarmiContentState.empty,
      'error': WarmiContentState.error,
    }.entries) {
      testWidgets('estado ${entry.key}', (tester) async {
        await _pumpAt(
          tester,
          size: const Size(360, 800),
          state: entry.value,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/estado_${entry.key}.png'),
        );
      });
    }
  });
}
