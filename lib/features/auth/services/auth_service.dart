import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../../../core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache current user
  User? _currentUser;

  Future<User> login(String email, String password) async {
    try {
      AppLogger.authStart(email);

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('errorUnknown');
      }

      final uid = credential.user!.uid;
      AppLogger.authSuccess(email, uid);

      // Fetch user details from Firestore
      AppLogger.firestoreRead('users', uid);
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw Exception('errorUserNotFound');
      }

      final userData = doc.data()!;
      var user = User.fromJson(userData, id: doc.id);

      // --- Strict Device Binding Check ---
      try {
        final currentDeviceId = await _getDeviceId();
        if (currentDeviceId != null) {
          if (user.deviceId == null) {
            // First time login - Bind device forever
            AppLogger.deviceBindingNew(user.id, currentDeviceId);
            AppLogger.firestoreWrite(
                'users', user.id, {'deviceId': currentDeviceId});
            await _firestore.collection('users').doc(user.id).update({
              'deviceId': currentDeviceId,
            });
            user = User.fromJson({...userData, 'deviceId': currentDeviceId},
                id: user.id);
          } else if (user.deviceId != currentDeviceId) {
            AppLogger.deviceBindingMismatch(
                user.id, user.deviceId!, currentDeviceId);
            await _firebaseAuth.signOut();
            throw Exception('errorDeviceMismatch');
          } else {
            AppLogger.deviceBindingMatch(user.id);
          }
        }
      } catch (e) {
        if (e.toString().contains('errorDeviceMismatch')) rethrow;
        AppLogger.error('Device check failed', tag: 'DeviceId', exception: e);
      }

      _currentUser = user;
      await _persistUser(_currentUser!);
      return _currentUser!;
    } on auth.FirebaseAuthException catch (e) {
      AppLogger.authFailed(email, e);
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw Exception('errorInvalidCredentials');
      }
      throw Exception('errorUnknown');
    } catch (e) {
      if (e.toString().contains('errorDeviceMismatch')) rethrow;
      AppLogger.error('Login failed', tag: 'Auth', exception: e);
      throw Exception('errorUnknown');
    }
  }

  static const _deviceIdChannel =
      MethodChannel('com.aou.no_screenshot/device_id');

  /// Returns a truly stable device identifier:
  /// - Android: Settings.Secure.ANDROID_ID — stable per device+signing key,
  ///            survives reinstall, only resets on factory reset.
  /// - iOS: UUID stored in Keychain — survives app uninstall/reinstall.
  /// - Other platforms: UUID persisted in SharedPreferences (best effort).
  Future<String?> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final id = await _deviceIdChannel.invokeMethod<String>('getAndroidId');
        if (id != null && id.isNotEmpty && id != '9774d56d682e549c') {
          AppLogger.deviceIdResolved(id, 'Android ANDROID_ID');
          return id;
        }
        AppLogger.deviceIdFallback('Android ID was null/empty/fake: $id');
      } else if (Platform.isIOS) {
        final id =
            await _deviceIdChannel.invokeMethod<String>('getIosDeviceId');
        if (id != null && id.isNotEmpty) {
          AppLogger.deviceIdResolved(id, 'iOS Keychain');
          return id;
        }
        AppLogger.deviceIdFallback('iOS Keychain returned null/empty');
      }
    } catch (e) {
      AppLogger.deviceIdFallback('Native channel error: $e');
    }
    // Fallback: SharedPreferences UUID
    const key = 'stable_device_id';
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(key);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(key, deviceId);
      AppLogger.deviceIdResolved(deviceId, 'SharedPreferences UUID (new)');
    } else {
      AppLogger.deviceIdResolved(deviceId, 'SharedPreferences UUID (cached)');
    }
    return deviceId;
  }

  Future<void> logout() async {
    AppLogger.authSignOut();
    await _firebaseAuth.signOut();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
  }

  Future<User?> checkSession() async {
    AppLogger.info('Checking session...', tag: 'Auth');
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      try {
        AppLogger.firestoreRead('users', firebaseUser.uid);
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          var user = User.fromJson(doc.data()!, id: doc.id);
          final currentDeviceId = await _getDeviceId();
          if (currentDeviceId != null &&
              user.deviceId != null &&
              user.deviceId != currentDeviceId) {
            AppLogger.deviceBindingMismatch(
                user.id, user.deviceId!, currentDeviceId);
            await logout();
            throw Exception('errorDeviceMismatch');
          }
          AppLogger.sessionRestored(user.id);
          _currentUser = user;
          return _currentUser;
        }
      } catch (e) {
        if (e.toString().contains('errorDeviceMismatch')) rethrow;
        AppLogger.warning('Firestore offline — falling back to cache',
            tag: 'Auth');
      }
    }

    // Fallback to shared prefs (offline mode)
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('current_user');
    if (userStr != null) {
      try {
        final cachedUser = User.fromJson(jsonDecode(userStr));
        // Still validate device even in offline mode
        if (cachedUser.deviceId != null) {
          final currentDeviceId = await _getDeviceId();
          if (currentDeviceId != null &&
              cachedUser.deviceId != currentDeviceId) {
            await logout();
            throw Exception('errorDeviceMismatch');
          }
        }
        _currentUser = cachedUser;
        return _currentUser;
      } catch (e) {
        if (e.toString().contains('errorDeviceMismatch')) rethrow;
        return null;
      }
    }
    return null;
  }

  Future<void> _persistUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  // Admin features - Create User (Authentication + Firestore)
  // Note: Only admins should call this. In a real app, this might be a Cloud Function to prevent
  // regular users from creating accounts with roles. For now, we do it client side assuming
  // only Admin has access to the UI.
  // Admin Features: Create User (Authentication + Firestore)
  Future<User> createUser(
      String email, String password, String displayName, UserRole role) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'tempAppCreate-${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      auth.UserCredential credential =
          await auth.FirebaseAuth.instanceFor(app: tempApp)
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = User(
        id: credential.user!.uid,
        username: email.split('@')[0],
        displayName: displayName,
        role: role,
        password: password, // Store password
        email: email, // Store email
      );

      await _firestore
          .collection('users')
          .doc(newUser.id)
          .set(newUser.toJson());

      await tempApp.delete();
      return newUser;
    } on auth.FirebaseAuthException catch (e) {
      await tempApp.delete();
      if (e.code == 'email-already-in-use') {
        throw Exception('errorUsernameExists');
      }
      throw Exception('errorUnknown');
    }
  }

  // Helper to seed the first admin
  Future<void> seedAdminUser() async {
    const adminEmail = 'admin@school.com';
    const adminPass = 'admin123';

    try {
      // Check if user exists (by trying to login)
      await _firebaseAuth.signInWithEmailAndPassword(
          email: adminEmail, password: adminPass);
      // If successful, user exists. Ensure firestore doc exists.
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        final doc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (!doc.exists) {
          final adminUser = User(
              id: currentUser.uid,
              username: 'admin',
              displayName: 'System Admin',
              role: UserRole.admin);
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .set(adminUser.toJson());
        }
      }
    } on auth.FirebaseAuthException {
      // Likely user doesn't exist, create it
      try {
        final cred = await _firebaseAuth.createUserWithEmailAndPassword(
            email: adminEmail, password: adminPass);
        final adminUser = User(
            id: cred.user!.uid,
            username: 'admin',
            displayName: 'System Admin',
            role: UserRole.admin);
        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(adminUser.toJson());
      } catch (e) {
        AppLogger.error('Error seeding admin', tag: 'Auth', exception: e);
      }
    }
  }

  Future<List<User>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => User.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  // Admin Features: Update User
  Future<void> updateUser({
    required String uid,
    required String currentStoredPassword, // needed to sign in
    required String currentEmail, // needed to sign in
    String? newPassword,
    String? newDisplayName,
    UserRole? newRole,
  }) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'tempAppUpdate-${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      // 1. Authenticate as the user using stored credentials
      final tempAuth = auth.FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.signInWithEmailAndPassword(
        email: currentEmail,
        password: currentStoredPassword,
      );
      final user = credential.user!;

      // 2. Update Auth Profile
      if (newPassword != null && newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      // Note: Updating email is tricky if we change it here,
      // but for now we assume email is immutable or we don't change it.
      // If we *did* want to change email: await user.updateEmail(newEmail);

      // 3. Update Firestore
      final updates = <String, dynamic>{};
      if (newPassword != null && newPassword.isNotEmpty) {
        updates['password'] = newPassword;
      }
      if (newDisplayName != null) updates['displayName'] = newDisplayName;
      if (newRole != null) updates['role'] = newRole.name;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }

      await tempApp.delete();
    } catch (e) {
      await tempApp.delete();
      rethrow;
    }
  }

  // Admin Features: Delete User
  Future<void> deleteUser(String uid, String email, String password) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'tempAppDelete-${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final tempAuth = auth.FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Delete from Auth
      await credential.user!.delete();

      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();

      await tempApp.delete();
    } catch (e) {
      await tempApp.delete();
      rethrow;
    }
  }

  // Admin Features: Statistics
  Future<Map<String, int>> getStats() async {
    final userSnapshot = await _firestore.collection('users').get();
    final materialSnapshot = await _firestore.collection('courses').get();

    int students = 0;
    int admins = 0;

    for (var doc in userSnapshot.docs) {
      final role = doc.data()['role'];
      if (role == 'admin') {
        admins++;
      } else {
        students++;
      }
    }

    return {
      'totalUsers': userSnapshot.size,
      'students': students,
      'admins': admins,
      'materials': materialSnapshot.size,
    };
  }
}
