import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether a user has finished the first-run wizard.
///
/// Keyed by uid so a signed-out user who signs back in (or a second user on
/// the same phone) sees the wizard exactly once each. Everything stays on the
/// device — completing onboarding is not something that needs to sync.
///
/// A ChangeNotifier so the auth gate can rebuild the moment a user finishes
/// the wizard: the gate listens, and `markComplete` fires the rebuild that
/// swaps the wizard for the main shell.
class OnboardingService extends ChangeNotifier {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static String _key(String uid) => 'onboarding_done_$uid';

  Future<bool> isComplete(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(uid)) ?? false;
  }

  Future<void> markComplete(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(uid), true);
    notifyListeners();
  }
}
