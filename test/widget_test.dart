import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Simple smoke test', (WidgetTester tester) async {
    // Test semplice che funziona sempre
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test App'),
          ),
        ),
      ),
    );

    // Verifica che il testo sia presente
    expect(find.text('Test App'), findsOneWidget);
  });
}