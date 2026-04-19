import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/features/admin/providers/admin_dashboard_provider.dart';

void main() {
  group('AdminDashboardProvider', () {
    late AdminDashboardProvider adminProvider;

    setUp(() {
      adminProvider = AdminDashboardProvider();
    });

    test('initial index should be 0', () {
      expect(adminProvider.selectedIndex, 0);
    });

    test('setIndex should update selection', () {
      adminProvider.setIndex(1);
      expect(adminProvider.selectedIndex, 1);

      adminProvider.setIndex(0);
      expect(adminProvider.selectedIndex, 0);
    });
  });
}
