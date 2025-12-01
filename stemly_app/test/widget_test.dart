// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic widget smoke test', (WidgetTester tester) async {
    // Build a minimal widget to verify test setup works.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Stemly')),
        ),
      ),
    );

    // Verify that our placeholder text is found.
    expect(find.text('Stemly'), findsOneWidget);
  });
}
