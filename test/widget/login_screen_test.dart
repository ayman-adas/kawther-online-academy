import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:no_screenshot/features/auth/models/user_model.dart';
import 'package:no_screenshot/features/auth/providers/auth_provider.dart';
import 'package:no_screenshot/features/auth/screens/login_screen.dart';

// Create a MockAuthProvider manually since we can't easily run build_runner in this env
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isLoading = false;
  String? _error;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  bool get isAuthenticated => false;

  @override
  User? get currentUser => null;

  // Use dynamic to bypass strict type checking in mock for simple test
  // Ideally this should return User? from user_model.dart
  // but simpler to use noSuchMethod or dynamic here if imports are tricky
  // However, I will match the signature as best as possible without imports if dynamic works,
  // but earlier lint complained. Let's fix imports and signature.
  // Actually, I can't import User from user_model easily if not exported.
  // I'll use dynamic for simplicity in this mock or matching signature.

  @override
  bool get isAdmin => false;

  @override
  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate net
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> checkSession() async {
    return false;
  }

  @override
  Future<void> registerUser(
      String email, String password, String displayName, UserRole role) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createLoginScreen(AuthProvider authProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    final mockAuth = MockAuthProvider();
    await tester.pumpWidget(createLoginScreen(mockAuth));

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Toggling password visibility works',
      (WidgetTester tester) async {
    final mockAuth = MockAuthProvider();
    await tester.pumpWidget(createLoginScreen(mockAuth));

    // Initially obscured
    // Find the TextField inside the TextFormField
    final textFieldFinder = find.descendant(
      of: find.widgetWithText(TextFormField, 'Password'),
      matching: find.byType(TextField),
    );

    expect((tester.widget(textFieldFinder) as TextField).obscureText, isTrue);

    // Tap visibility icon
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    // Now plain text
    expect((tester.widget(textFieldFinder) as TextField).obscureText, isFalse);
  });
}
