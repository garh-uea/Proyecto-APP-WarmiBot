import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:warmibot/main.dart';

void main() {
  testWidgets('WarmiBot inicia correctamente',
      (WidgetTester tester) async {

    await tester.pumpWidget(const WarmiBotApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}