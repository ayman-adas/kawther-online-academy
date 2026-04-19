// ignore_for_file: avoid_print
import 'dart:developer' as dev;

/// Structured application logger.
/// All log calls are no-ops in release builds.
class AppLogger {
  AppLogger._();

  static bool _enabled = true;

  // ──────────────────────────────────────────────
  // General
  // ──────────────────────────────────────────────

  static void info(String message, {String? tag}) =>
      _log('ℹ️  INFO', message, tag: tag);

  static void success(String message, {String? tag}) =>
      _log('✅ SUCCESS', message, tag: tag);

  static void warning(String message, {String? tag}) =>
      _log('⚠️  WARNING', message, tag: tag);

  static void error(String message, {String? tag, Object? exception}) {
    _log('❌ ERROR', message, tag: tag);
    if (exception != null) _log('❌ EXCEPTION', exception.toString(), tag: tag);
  }

  // ──────────────────────────────────────────────
  // Auth flow
  // ──────────────────────────────────────────────

  static void authStart(String email) =>
      _log('🔐 AUTH', 'Login attempt → $email', tag: 'Auth');

  static void authSuccess(String email, String uid) =>
      _log('🔐 AUTH', 'Login success — uid=$uid  email=$email', tag: 'Auth');

  static void authFailed(String email, Object error) =>
      _log('🔐 AUTH', 'Login FAILED — email=$email  error=$error', tag: 'Auth');

  static void authSignOut() =>
      _log('🔐 AUTH', 'User signed out', tag: 'Auth');

  static void sessionRestored(String uid) =>
      _log('🔐 AUTH', 'Session restored — uid=$uid', tag: 'Auth');

  static void sessionNone() =>
      _log('🔐 AUTH', 'No active session found', tag: 'Auth');

  // ──────────────────────────────────────────────
  // Device ID
  // ──────────────────────────────────────────────

  static void deviceIdResolved(String id, String source) =>
      _log('📱 DEVICE', 'Device ID resolved  source=$source  id=$id',
          tag: 'DeviceId');

  static void deviceIdFallback(String reason) =>
      _log('📱 DEVICE', 'Fallback to SharedPreferences — reason: $reason',
          tag: 'DeviceId');

  static void deviceBindingNew(String uid, String deviceId) =>
      _log('📱 DEVICE', 'First login — binding device to user uid=$uid  deviceId=$deviceId',
          tag: 'DeviceId');

  static void deviceBindingMatch(String uid) =>
      _log('📱 DEVICE', 'Device match OK — uid=$uid', tag: 'DeviceId');

  static void deviceBindingMismatch(String uid, String stored, String current) =>
      _log('📱 DEVICE',
          'Device MISMATCH — uid=$uid\n'
          '  stored : $stored\n'
          '  current: $current',
          tag: 'DeviceId');

  // ──────────────────────────────────────────────
  // Firestore
  // ──────────────────────────────────────────────

  static void firestoreRead(String collection, String docId) =>
      _log('🔥 FIRESTORE', 'Read  $collection/$docId', tag: 'Firestore');

  static void firestoreWrite(String collection, String docId, Map<String, dynamic> data) =>
      _log('🔥 FIRESTORE', 'Write $collection/$docId  data=$data',
          tag: 'Firestore');

  static void firestoreError(String collection, String docId, Object error) =>
      _log('🔥 FIRESTORE', 'Error $collection/$docId  error=$error',
          tag: 'Firestore');

  // ──────────────────────────────────────────────
  // Internal
  // ──────────────────────────────────────────────

  static void _log(String level, String message, {String? tag}) {
    assert(() {
      if (!_enabled) return true;
      final now = DateTime.now();
      final ts =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
      final label = tag != null ? '[$tag]' : '';
      dev.log('$ts $level $label  $message');
      return true;
    }());
  }

  static void disable() => _enabled = false;
  static void enable() => _enabled = true;
}
