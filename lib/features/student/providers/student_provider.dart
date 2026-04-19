import 'package:flutter/material.dart';
import '../../admin/models/material_model.dart';
import '../services/student_service.dart';

class StudentProvider with ChangeNotifier {
  final StudentService _studentService = StudentService();

  List<CourseMaterial> _assignedMaterials = [];
  bool _isLoading = false;
  String? _error;

  List<CourseMaterial> get assignedMaterials => _assignedMaterials;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAssignedMaterials(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _assignedMaterials = await _studentService.getAssignedMaterials(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
