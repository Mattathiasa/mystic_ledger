import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lock_service.dart';

/// Privacy hardening on top of the app lock.
///
/// Three jobs:
///  1. Privacy shield — the app root covers the whole tree with a branded,
///     opaque screen the moment the OS is about to snapshot it (app switcher
///     on iOS/Android), so balances never show in the task preview.
///  2. Android FLAG_SECURE — blocks screenshots and the task-switcher preview
///     entirely while the app lock is enabled.
///  3. Inactivity auto-lock — after [autoLockMinutes] without any interaction
///     the app re-seals behind the biometric gate.
class SecurityService extends ChangeNotifier {
  SecurityService._();

  static final SecurityService instance = SecurityService._();

  static const _channel = MethodChannel('mystic_ledger/security');
  static const _kAutoLock = 'auto_lock_minutes';

  int _autoLockMinutes = 1;
  Timer? _idleTimer;
  bool _covered = false;

  /// True while the privacy shield should be visible.
  bool get covered => _covered;

  /// Minutes of idleness before the auto-lock fires. 0 disables the timer.
  int get autoLockMinutes => _autoLockMinutes;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _autoLockMinutes = prefs.getInt(_kAutoLock) ?? 1;
    // The screenshot ban rides on the lock setting: no lock, no reason to
    // block screenshots of the ledger.
    await applySecureFlag(LockService.instance.isEnabled);
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    _autoLockMinutes = minutes < 0 ? 0 : minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAutoLock, _autoLockMinutes);
    if (_autoLockMinutes <= 0) _idleTimer?.cancel();
  }

  /// Called on every user interaction and on resume — postpones the lock.
  void touch() {
    _idleTimer?.cancel();
    if (_autoLockMinutes <= 0) return;
    _idleTimer = Timer(Duration(minutes: _autoLockMinutes), () {
      // No-op when the lock is disabled (see LockService.lock).
      LockService.instance.lock();
    });
  }

  /// Shows the shield — call when the OS may snapshot the screen.
  void cover() {
    if (_covered) return;
    _covered = true;
    notifyListeners();
  }

  /// Hides the shield on return to the foreground.
  void uncover() {
    if (!_covered) return;
    _covered = false;
    notifyListeners();
    touch();
  }

  /// Android-only: toggles WindowManager FLAG_SECURE. Silent no-op elsewhere
  /// (including web and tests, where the channel does not exist).
  Future<void> applySecureFlag(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('setSecure', enabled);
    } catch (_) {
      // Missing plugin in tests/desktop — nothing to do.
    }
  }
}
