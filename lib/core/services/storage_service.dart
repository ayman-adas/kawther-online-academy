import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadFile(PlatformFile file, String folder) async {
    try {
      final fileName = '${_uuid.v4()}_${file.name}';
      final ref = _storage.ref().child('$folder/$fileName');

      UploadTask uploadTask;

      if (file.bytes != null) {
        // Web or when bytes are available (e.g. small files)
        uploadTask = ref.putData(file.bytes!);
      } else if (file.path != null) {
        // Mobile/Desktop
        uploadTask = ref.putFile(File(file.path!));
      } else {
        throw Exception('errorFieldRequired');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('errorOperationFailed');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignore if not found, or log
      debugPrint('Error deleting file: $e');
    }
  }
}
