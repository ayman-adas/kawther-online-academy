import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/models/material_model.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CourseMaterial>> getAssignedMaterials(String userId) async {
    try {
      // Firestore supports array queries
      final snapshot = await _firestore
          .collection('courses')
          .where('assignedUserIds', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => CourseMaterial.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw Exception('errorNetwork');
    }
  }
}
