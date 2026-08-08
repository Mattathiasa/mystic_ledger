import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-level privacy gate.
///
/// When enabled, the app is locked when it starts or returns from the
/// background, and stays locked until the device's biometric (or PIN, as a
/// fallback) is presented. It is device-local — it protects this phone's
/// screen, not the account — so the flag lives in SharedPreferences rather
/// than Firestore, alongside the balance-masking prefs.
class LockService extends ChangeNotifier {
  LockService._();

  static final LockService instance = LockService._();

  static const _kEnabled = 'lock_enabled';

  final _auth = LocalAuthentication();

  bool _enabled = false;

  /// True while the app is waiting for (or failed) authentication.
  bool _locked = false;

  bool get isEnabled => _enabled;
  bool get isLocked => _enabled && _locked;

  /// Whether this platform can attempt biometrics at all.
  bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Whether this device has biometrics (or a device credential) enrolled.
  Future<bool> get canUse async {
    if (!supported) return false;
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabled) ?? false;
    // Enabled implies locked until the user proves themselves at startup.
    _locked = _enabled;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    // Turning it on locks immediately; turning it off unlocks.
    _locked = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
    notifyListeners();
  }

  /// Locks after returning from background. No-op when disabled or already
  /// locked.
  void lock() {
    if (!_enabled || _locked) return;
    _locked = true;
    notifyListeners();
  }

  /// Tries the OS prompt (biometric, falling back to device credential/PIN).
  /// Returns true only on success.
  Future<bool> authenticate() async {
    if (!_enabled) return true;
    try {
      final ok = await _auth.authenticate(
        localizedReason:
            'Unlock Mystic Ledger to see your records.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
      );
      if (ok) _locked = false;
      notifyListeners();
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Unlocks without authentication — used when the device has nothing
  /// enrolled to check against.
  void unlock() {
    _locked = false;
    notifyListeners();
  }
}
