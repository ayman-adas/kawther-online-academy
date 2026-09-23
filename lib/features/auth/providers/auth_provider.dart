import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<bool> checkSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.checkSession();
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(username, password);
    } catch (e) {
      _error = e.toString(); // AppErrorHandler will parse this string matches
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> registerStudent(String email, String password, String displayName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(email, password, displayName);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin Methods via Provider
  Future<void> registerUser(String username, String password,
      String displayName, UserRole role) async {
    if (!isAdmin) return;
    // This would typically be in an AdminProvider
    await _authService.createUser(username, password, displayName, role);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
