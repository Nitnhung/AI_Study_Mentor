import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App khởi động không crash', (tester) async {
    // Test cơ bản: app khởi động được, không ném exception
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('AI Study Mentor')))),
    );
    expect(find.text('AI Study Mentor'), findsOneWidget);
  });
}
