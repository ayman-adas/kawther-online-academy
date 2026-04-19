import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/main.dart';

void main() {
  testWidgets('Login Screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EducationApp());

    // Verify title is present
    expect(find.text('Aou Online Academy'), findsOneWidget);
    expect(find.text('Secure Learning Environment'), findsOneWidget);

    // Verify fields are present
    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

    // Verify Login button is present
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
