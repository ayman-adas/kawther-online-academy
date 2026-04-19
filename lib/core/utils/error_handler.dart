import 'package:flutter/material.dart';
// Assuming specific exceptions exist or we parse strings.
// Assuming specific exceptions exist or we parse strings.
// Ideally we should have custom exceptions. For now we might parse strings or dynamic errors.
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_colors.dart';

class AppErrorHandler {
  static String getErrorMessage(BuildContext context, dynamic error) {
    final l10n = AppLocalizations.of(context)!;
    final s = error.toString();

    // --- Authentication errors (Firebase codes + custom app codes) ---
    if (s.contains('user-not-found') || s.contains('errorUserNotFound')) {
      return l10n.errorUserNotFound;
    }
    if (s.contains('wrong-password') ||
        s.contains('invalid-credential') ||
        s.contains('errorInvalidCredentials')) {
      return l10n.errorInvalidCredentials;
    }
    if (s.contains('email-already-in-use') || s.contains('errorUsernameExists')) {
      return l10n.errorUsernameExists;
    }
    if (s.contains('weak-password') || s.contains('errorWeakPassword')) {
      return l10n.errorWeakPassword;
    }
    if (s.contains('invalid-email') || s.contains('errorInvalidEmail')) {
      return l10n.errorInvalidEmail;
    }

    // --- Device binding ---
    if (s.contains('errorDeviceMismatch')) {
      return l10n.errorDeviceMismatch;
    }

    // --- Network & permissions ---
    if (s.contains('network-request-failed') || s.contains('errorNetwork')) {
      return l10n.errorNetwork;
    }
    if (s.contains('permission-denied') || s.contains('errorPermissionDenied')) {
      return l10n.errorPermissionDenied;
    }

    // --- Content / CRUD errors ---
    if (s.contains('errorMaterialNotFound')) return l10n.errorMaterialNotFound;
    if (s.contains('errorSubjectNotFound')) return l10n.errorSubjectNotFound;
    if (s.contains('errorContentNotFound')) return l10n.errorContentNotFound;
    if (s.contains('errorFieldRequired')) return l10n.errorFieldRequired;
    if (s.contains('errorOperationFailed')) return l10n.errorOperationFailed;

    // --- Fallback ---
    if (s.contains('errorUnknown')) return l10n.errorUnknown;

    // Strip "Exception: " prefix and show raw message as last resort
    return s.replaceAll('Exception: ', '');
  }

  static void showErrorToast(BuildContext context, dynamic error) {
    final message = getErrorMessage(context, error);
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: AppColors.error,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Helper to standardise error handling in Providers
  static String parseError(dynamic e) {
    // This returns a "code" or a raw string that getErrorMessage can parse.
    // For simplicity, we just return the string since getErrorMessage parses strings.
    return e.toString();
  }
}
