import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/features/auth/models/user_model.dart';

void main() {
  group('User Model Device Binding Tests', () {
    test('fromJson and toJson correctly handle deviceName', () {
      final user = User(
        id: 'user123',
        username: 'johndoe',
        displayName: 'John Doe',
        role: UserRole.student,
        deviceName: 'Samsung Galaxy S22',
        email: 'john@example.com',
      );

      final json = user.toJson();
      expect(json['id'], 'user123');
      expect(json['username'], 'johndoe');
      expect(json['deviceName'], 'Samsung Galaxy S22');
      expect(json['email'], 'john@example.com');

      final parsedUser = User.fromJson(json);
      expect(parsedUser.id, 'user123');
      expect(parsedUser.deviceName, 'Samsung Galaxy S22');
      expect(parsedUser.role, UserRole.student);
    });

    test('fromJson handles missing deviceName (null)', () {
      final json = {
        'id': 'user456',
        'username': 'janedoe',
        'displayName': 'Jane Doe',
        'role': 'student',
      };

      final parsedUser = User.fromJson(json);
      expect(parsedUser.id, 'user456');
      expect(parsedUser.deviceName, isNull);
    });
  });
}
