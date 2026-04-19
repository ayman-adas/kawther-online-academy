import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_dashboard_provider.dart';

import 'manage_materials_screen.dart';
import 'manage_users_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [
      l10n.manageUsers,
      l10n.manageContent,
    ];

    final pages = [
      const ManageUsersScreen(),
      const ManageMaterialsScreen(),
    ];

    return ChangeNotifierProvider(
      create: (_) => AdminDashboardProvider(),
      child: Consumer<AdminDashboardProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(titles[provider.selectedIndex]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: l10n.logout,
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                ),
              ],
            ),
            body: pages[provider.selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: const Icon(Icons.people),
                  label: l10n.users,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.library_books),
                  label: l10n.materials,
                ),
              ],
              currentIndex: provider.selectedIndex,
              selectedItemColor: AppColors.primary,
              onTap: (index) => provider.setIndex(index),
            ),
          );
        },
      ),
    );
  }
}
