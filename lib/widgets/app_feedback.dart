import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Shared success/error feedback.
///
/// Firestore writes used to be fire-and-forget across every screen: a failed
/// save (permission denied, quota, rejected by rules) produced no visible
/// signal and the user was left believing their money had been recorded.
/// Everything that writes now reports through here.
extension AppFeedback on BuildContext {
  void showSuccess(String message) =>
      _show(ScaffoldMessenger.maybeOf(this), message, MysticColors.secondary);

  void showError(String message) =>
      _show(ScaffoldMessenger.maybeOf(this), message, MysticColors.tertiary);
}

void _show(ScaffoldMessengerState? messenger, String message, Color background) {
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: bodyStyle(13, color: Colors.white)),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

/// Turns a write failure into something a person can act on.
///
/// Firestore's own messages name internal codes and collections, which is
/// noise to the user and leaks structure.
String friendlyWriteError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'That save was rejected. Try signing out and back in.';
      case 'unauthenticated':
        return 'Your session expired. Please sign in again.';
      case 'resource-exhausted':
        return 'The archive is temporarily overloaded. Please try again in a '
            'moment.';
      case 'not-found':
        return 'That record no longer exists.';
      default:
        return 'Could not save (${error.code}). Please try again.';
    }
  }
  if (error is StateError) return error.message;
  return 'Something went wrong while saving. Please try again.';
}

/// Fires a Firestore write without blocking on it, reporting a later failure.
///
/// **Why this does not await:** with offline persistence enabled (see
/// `main.dart`), a write applies to the local cache immediately but its Future
/// does not resolve until the server acknowledges it. Awaiting would hang the
/// screen for the entire time the device is offline. The local write is what
/// drives the UI — the snapshot listener fires straight away — so the correct
/// behaviour is to return control at once and surface only an eventual
/// *rejection*.
///
/// Pass a [messenger] captured *before* navigating away, since the calling
/// screen's own context is usually gone by the time an error arrives.
void reportIfWriteFails(
  ScaffoldMessengerState? messenger,
  Future<void> write,
) {
  write.catchError((Object e) {
    _show(messenger, friendlyWriteError(e), MysticColors.tertiary);
  });
}

/// For writes the user is explicitly waiting on (deletes, reversals, settings)
/// where staying on the screen until it resolves is the expected behaviour.
///
/// Returns whether it succeeded. Unlike [reportIfWriteFails] this *does* await,
/// so only use it where an offline stall would be acceptable or impossible.
Future<bool> guardWrite(
  BuildContext context,
  Future<void> Function() write, {
  String? successMessage,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await write();
    if (successMessage != null) {
      _show(messenger, successMessage, MysticColors.secondary);
    }
    return true;
  } catch (e) {
    _show(messenger, friendlyWriteError(e), MysticColors.tertiary);
    return false;
  }
}
