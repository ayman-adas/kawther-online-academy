import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../models/material_model.dart';
import '../services/admin_service.dart';
import '../../../../core/services/storage_service.dart';
import 'package:file_picker/file_picker.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  final StorageService _storageService = StorageService();

  List<User> _users = [];
  List<CourseMaterial> _materials = [];
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  List<CourseMaterial> get materials => _materials;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, int> _stats = {};
  Map<String, int> get stats => _stats;

  // --- User Actions ---
  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _adminService.getAllUsers();
      _stats = await _adminService.getStats(); // Load stats when loading users
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(
      String email, String password, String displayName, UserRole role) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.createUser(email, password, displayName, role);
      await loadUsers(); // Refresh list
    } catch (e) {
      _error = e.toString();
      rethrow; // Rethrow to let UI handle it (close dialog etc)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser({
    required String uid,
    required String currentStoredPassword,
    required String currentEmail, // needed to sign in
    String? newPassword,
    String? newDisplayName,
    UserRole? newRole,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.updateUser(
        uid: uid,
        currentStoredPassword: currentStoredPassword,
        currentEmail: currentEmail,
        newPassword: newPassword,
        newDisplayName: newDisplayName,
        newRole: newRole,
      );
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.deleteUser(uid, email, password);
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetDeviceName(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.resetDeviceName(uid);
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Material Actions ---
  Future<void> loadMaterials() async {
    _isLoading = true;
    notifyListeners();
    try {
      _materials = await _adminService.getAllMaterials();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCourse(String title, String description) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.createCourse(title, description);
      await loadMaterials();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCourse(
      String courseId, String title, String description) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.updateCourse(courseId, title, description);
      await loadMaterials();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCourse(String courseId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.deleteCourse(courseId);
      await loadMaterials();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubject(String courseId, String subjectTitle) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.addSubject(courseId, subjectTitle);
      await loadMaterials();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSubject(
      String courseId, String subjectId, String newTitle) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.updateSubject(courseId, subjectId, newTitle);
      await loadMaterials();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSubject(String courseId, String subjectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.deleteSubject(courseId, subjectId);
      await loadMaterials();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContent(String courseId, String subjectId, String title,
      String description, ContentType type,
      {String? url, PlatformFile? file}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String finalUrl = url ?? '';

      if (file != null) {
        // Upload file first
        final folder = 'courses/$courseId/subjects/$subjectId';
        finalUrl = await _storageService.uploadFile(file, folder);
      }

      if (finalUrl.isEmpty) {
        throw Exception('errorFieldRequired');
      }

      await _adminService.addContent(
          courseId, subjectId, title, description, type, finalUrl);
      await loadMaterials();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateContent(String courseId, String subjectId,
      String contentId, String title, String description, ContentType type,
      {String? url, PlatformFile? file, String? currentUrl}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String finalUrl = url ?? currentUrl ?? '';

      if (file != null) {
        // Upload new file if provided
        final folder = 'courses/$courseId/subjects/$subjectId';
        finalUrl = await _storageService.uploadFile(file, folder);
      }

      if (finalUrl.isEmpty) {
        throw Exception('errorFieldRequired');
      }

      await _adminService.updateContent(
          courseId, subjectId, contentId, title, description, type, finalUrl);
      await loadMaterials();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteContent(
      String courseId, String subjectId, String contentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.deleteContent(courseId, subjectId, contentId);
      await loadMaterials();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCourseAssignments(
      String courseId, List<String> newAssignedUserIds) async {
    // 1. Optimistic Update
    final materialIndex = _materials.indexWhere((m) => m.id == courseId);
    if (materialIndex == -1) return;

    final originalMaterial = _materials[materialIndex];
    final originalAssignments =
        List<String>.from(originalMaterial.assignedUserIds);

    // Update local state and notify UI immediately
    final updatedMaterial =
        originalMaterial.copyWith(assignedUserIds: newAssignedUserIds);
    _materials[materialIndex] = updatedMaterial;
    notifyListeners();

    try {
      // 2. Perform Network Calls (Diffing)
      final addedIds = newAssignedUserIds
          .where((id) => !originalAssignments.contains(id))
          .toList();
      final removedIds = originalAssignments
          .where((id) => !newAssignedUserIds.contains(id))
          .toList();

      // Execute all changes
      // In a real app with batch support, this would be one call.
      // Here we chain them. failing one might leave partial state, but ok for now.
      for (final userId in addedIds) {
        await _adminService.assignCourseToUser(courseId, userId);
      }
      for (final userId in removedIds) {
        await _adminService.removeAssignment(courseId, userId);
      }
    } catch (e) {
      // 3. Revert on Error
      _error = e.toString();
      _materials[materialIndex] =
          originalMaterial.copyWith(assignedUserIds: originalAssignments);
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
