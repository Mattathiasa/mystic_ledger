import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/l10n.dart';
import 'app_theme.dart';

/// Shared success/error feedback.
///
/// Firestore writes used to be fire-and-forget across every screen: a failed
/// save (permission denied, quota, rejected by rules) produced no visible
/// signal and the user was left believing their money had been recorded.
/// Everything that writes now reports through here.
///
/// The API takes a [ScaffoldMessengerState], not a `BuildContext`, on purpose:
/// most writes report *after* the form has popped, by which point the calling
/// screen's context is dead. Capture the messenger before navigating away.
void showFeedback(
  ScaffoldMessengerState? messenger,
  String message, {
  bool error = false,
}) =>
    _show(messenger, message,
        error ? MysticColors.tertiary : MysticColors.secondary);

void _show(ScaffoldMessengerState? messenger, String message, Color background) {
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content:
            Text(message, style: bodyStyle(13, color: readableOn(background))),
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
        return L10n.t('That save was rejected. Try signing out and back in.');
      case 'unauthenticated':
        return L10n.t('Your session expired. Please sign in again.');
      case 'resource-exhausted':
        return L10n.t('The archive is temporarily overloaded. Please try again '
            'in a moment.');
      case 'not-found':
        return L10n.t('That record no longer exists.');
      default:
        return '${L10n.t('Could not save')} (${error.code}). '
            '${L10n.t('Please try again.')}';
    }
  }
  if (error is StateError) return error.message;
  return L10n.t('Something went wrong while saving. Please try again.');
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
