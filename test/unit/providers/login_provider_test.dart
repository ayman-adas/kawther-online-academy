import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/features/auth/providers/login_provider.dart';

void main() {
  group('LoginProvider', () {
    late LoginProvider loginProvider;

    setUp(() {
      loginProvider = LoginProvider();
    });

    test('initial state should have password hidden', () {
      expect(loginProvider.isPasswordVisible, false);
    });

    test('togglePasswordVisibility should flip the state', () {
      loginProvider.togglePasswordVisibility();
      expect(loginProvider.isPasswordVisible, true);

      loginProvider.togglePasswordVisibility();
      expect(loginProvider.isPasswordVisible, false);
    });
  });
}
