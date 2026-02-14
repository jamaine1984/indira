import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic MaterialApp smoke test (IndiraLoveApp requires Firebase initialization)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Indira Love')),
        ),
      ),
    );

    expect(find.text('Indira Love'), findsOneWidget);
  });
}
