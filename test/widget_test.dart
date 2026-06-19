import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_mentor_study/app.dart';

void main() {
  testWidgets('Auth screen switches between login and sign up', (tester) async {
    await tester.pumpWidget(const AiMentorApp());

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login'), findsNothing);

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Smart expense management'), findsOneWidget);

    final signUpLink = find.byType(TextButton);
    await tester.ensureVisible(signUpLink);
    tester.widget<TextButton>(signUpLink).onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('Login button opens the home screen', (tester) async {
    await tester.pumpWidget(const AiMentorApp());

    final loginButton = find.byType(FilledButton);
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Ask AI'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
