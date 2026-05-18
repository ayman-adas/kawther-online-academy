import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../models/material_model.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ignore: unused_field
  final Uuid _uuid = const Uuid();

  // --- User Management ---
  Future<List<User>> getAllUsers() async {
    return _authService.getAllUsers();
  }

  Future<User> createUser(
      String email, String password, String displayName, UserRole role) async {
    return await _authService.createUser(email, password, displayName, role);
  }

  Future<void> updateUser({
    required String uid,
    required String currentStoredPassword,
    required String currentEmail, // needed to sign in
    String? newPassword,
    String? newDisplayName,
    UserRole? newRole,
  }) async {
    return await _authService.updateUser(
      uid: uid,
      currentStoredPassword: currentStoredPassword,
      currentEmail: currentEmail,
      newPassword: newPassword,
      newDisplayName: newDisplayName,
      newRole: newRole,
    );
  }

  Future<void> deleteUser(String uid, String email, String password) async {
    return await _authService.deleteUser(uid, email, password);
  }

  Future<void> resetDeviceName(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'deviceName': FieldValue.delete(),
    });
  }

  Future<Map<String, int>> getStats() async {
    return await _authService.getStats();
  }

  // --- Material Management ---
  Future<List<CourseMaterial>> getAllMaterials() async {
    final snapshot = await _firestore.collection('courses').get();
    return snapshot.docs
        .map((doc) => CourseMaterial.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  Future<CourseMaterial> createCourse(String title, String description) async {
    final newCourse = CourseMaterial.create(
      title: title,
      description: description,
    );
    await _firestore
        .collection('courses')
        .doc(newCourse.id)
        .set(newCourse.toJson());
    return newCourse;
  }

  Future<void> updateCourse(
      String courseId, String title, String description) async {
    await _firestore.collection('courses').doc(courseId).update({
      'title': title,
      'description': description,
    });
  }

  Future<void> deleteCourse(String courseId) async {
    // Note: In a real app we might want to recursively delete sub-collections or handle storage files.
    // For now, we just delete the doc.
    await _firestore.collection('courses').doc(courseId).delete();
  }

  Future<void> addSubject(String courseId, String subjectTitle) async {
    final newSubject = Subject.create(title: subjectTitle);

    // Transaction to ensure atomicity
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('courses').doc(courseId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('errorMaterialNotFound');
      }

      final course = CourseMaterial.fromJson(snapshot.data()!, id: snapshot.id);
      final updatedSubjects = List<Subject>.from(course.subjects)
        ..add(newSubject);
      final updatedCourse = course.copyWith(subjects: updatedSubjects);

      transaction.set(docRef, updatedCourse.toJson());
    });
  }

  Future<void> addContent(String courseId, String subjectId, String title,
      String description, ContentType type, String url) async {
    final newContent = ContentItem.create(
      title: title,
      description: description,
      type: type,
      url: url,
    );

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('courses').doc(courseId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('errorMaterialNotFound');

      final course = CourseMaterial.fromJson(snapshot.data()!, id: snapshot.id);
      final subjectIndex = course.subjects.indexWhere((s) => s.id == subjectId);

      if (subjectIndex == -1) throw Exception('errorSubjectNotFound');

      final subject = course.subjects[subjectIndex];
      final updatedContents = List<ContentItem>.from(subject.contents)
        ..add(newContent);
      final updatedSubject = subject.copyWith(contents: updatedContents);

      final updatedSubjects = List<Subject>.from(course.subjects);
      updatedSubjects[subjectIndex] = updatedSubject;

      final updatedCourse = course.copyWith(subjects: updatedSubjects);
      transaction.set(docRef, updatedCourse.toJson());
    });
  }

  Future<void> updateSubject(
      String courseId, String subjectId, String newTitle) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('courses').doc(courseId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('errorMaterialNotFound');

      final course = CourseMaterial.fromJson(snapshot.data()!, id: snapshot.id);
      final subjectIndex = course.subjects.indexWhere((s) => s.id == subjectId);

      if (subjectIndex == -1) throw Exception('errorSubjectNotFound');

      final updatedSubjects = List<Subject>.from(course.subjects);
      updatedSubjects[subjectIndex] =
          updatedSubjects[subjectIndex].copyWith(title: newTitle);

      final updatedCourse = course.copyWith(subjects: updatedSubjects);
      transaction.update(docRef, updatedCourse.toJson());
    });
  }

  Future<void> deleteSubject(String courseId, String subjectId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('courses').doc(courseId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('errorMaterialNotFound');

      final course = CourseMaterial.fromJson(snapshot.data()!, id: snapshot.id);
      final updatedSubjects =
          course.subjects.where((s) => s.id != subjectId).toList();

      final updatedCourse = course.copyWith(subjects: updatedSubjects);
      transaction.update(docRef, updatedCourse.toJson());
    });
  }

  Future<void> updateContent(
      String courseId,
      String subjectId,
      String contentId,
      String newTitle,
      String newDescription,
      ContentType newType,
      String newUrl) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('courses').doc(courseId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('errorMaterialNotFound');

      final course = CourseMaterial.fromJson(snapshot.data()!, id: snapshot.id);
      final subjectIndex = course.subjects.indexWhere((s) => s.id == subjectId);

      if (subjectIndex == -1) throw Exception('errorSubjectNotFound');

      final subject = course.subjects[subjectIndex];
      final contentIndex =
          subject.contents.indexWhere((c) => c.id == contentId);

      if (contentIndex == -1) throw Exception('errorContentNotFound');

      // Update content fields
      // Note: We are creating a new ContentItem but keeping ID and createdAt
      final oldContent = subject.contents[contentIndex];
      final newContent = ContentItem(
        id: oldContent.id,
        title: newTitle,
        description: newDescription,
        type: newType,
        url: newUrl,
        createdAt: oldContent.createdAt,
      );

      final updatedContents = List<ContentItem>.from(subject.contents);
      updatedContents[contentIndex] = newContent;

      final updatedSubject = subject.copyWith(contents: updatedContents);
      final updatedSubjects = List<Subject>.from(course.subjects);
      updatedSubjects[subjectIndex] = updatedSubject;

      final updatedCourse = course.copyWith(subjects: updatedSubjects);
      transaction.update(docRef, updatedCourse.toJson());
    });
  }

  Future<void> deleteContent(
      String courseId, String subjectId, String contentId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('courses').doc(courseId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('errorMaterialNotFound');

      final course = CourseMaterial.fromJson(snapshot.data()!, id: snapshot.id);
      final subjectIndex = course.subjects.indexWhere((s) => s.id == subjectId);

      if (subjectIndex == -1) throw Exception('errorSubjectNotFound');

      final subject = course.subjects[subjectIndex];
      final updatedContents =
          subject.contents.where((c) => c.id != contentId).toList();

      final updatedSubject = subject.copyWith(contents: updatedContents);
      final updatedSubjects = List<Subject>.from(course.subjects);
      updatedSubjects[subjectIndex] = updatedSubject;

      final updatedCourse = course.copyWith(subjects: updatedSubjects);
      transaction.update(docRef, updatedCourse.toJson());
    });
  }

  Future<void> assignCourseToUser(String courseId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('courses').doc(courseId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('errorMaterialNotFound');

      final course = CourseMaterial.fromJson(snapshot.data()!, id: snapshot.id);
      if (!course.assignedUserIds.contains(userId)) {
        final updatedList = List<String>.from(course.assignedUserIds)
          ..add(userId);
        transaction.update(docRef, {'assignedUserIds': updatedList});
      }
    });
  }

  Future<void> removeAssignment(String courseId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('courses').doc(courseId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) return; // Or throw

      final course = CourseMaterial.fromJson(snapshot.data()!, id: snapshot.id);
      if (course.assignedUserIds.contains(userId)) {
        final updatedList = List<String>.from(course.assignedUserIds)
          ..remove(userId);
        transaction.update(docRef, {'assignedUserIds': updatedList});
      }
    });
  }
}
