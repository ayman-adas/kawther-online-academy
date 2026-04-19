import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/error_handler.dart';
import '../providers/auth_provider.dart';

import 'login_screen.dart';
import '../../admin/screens/admin_dashboard.dart';
import '../../student/screens/student_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // Check session only once on startup
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isInitialized) {
        auth.checkSession();
      }
      _isInit = false;
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (auth.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppErrorHandler.showErrorToast(context, auth.error!);
            auth.clearError();
          });
        }

        if (auth.isAuthenticated && auth.currentUser != null) {
          if (auth.isAdmin) {
            return const AdminDashboard();
          } else {
            return const StudentDashboard();
          }
        }

        return const LoginScreen();
      },
    );
  }
}
