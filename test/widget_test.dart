import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uems/main.dart';

void main() {
  testWidgets('UEMS app smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const UEMSApp());

    // Verify that the splash screen appears (or any initial content)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
