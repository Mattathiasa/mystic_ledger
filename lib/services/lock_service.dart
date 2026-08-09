import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n.dart';

/// App-level privacy gate.
///
/// When enabled, the app is locked when it starts or returns from the
/// background, and stays locked until the device's biometric (or PIN, as a
/// fallback) is presented. It is device-local — it protects this phone's
/// screen, not the account — so the flag lives in hardware-backed storage
/// (Android Keystore / iOS Keychain) rather than in plain text on the file
/// system, alongside the balance-masking prefs.
class LockService extends ChangeNotifier {
  LockService._();

  static final LockService instance = LockService._();

  static const _kEnabled = 'lock_enabled';

  final _auth = LocalAuthentication();

  /// Hardware-backed vault. The lock flag decides who may open this phone's
  /// screen, so it must not sit in plain text on disk.
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _enabled = false;

  /// True while the app is waiting for (or failed) authentication.
  bool _locked = false;

  bool _migrated = false;

  bool get isEnabled => _enabled;
  bool get isLocked => _enabled && _locked;

  /// Whether this platform can attempt biometrics at all.
  bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Whether this device has something actually enrolled to verify against.
  ///
  /// Deliberately not [LocalAuthentication.canCheckBiometrics] — that reports
  /// hardware *capability*, not enrollment, so a phone with a fingerprint
  /// sensor but no enrolled fingerprints would wrongly pass and then seal the
  /// user in with no way to unlock. Enrollment or a secure lock screen is what
  /// lets [authenticate] succeed.
  Future<bool> get canUse async {
    if (!supported) return false;
    try {
      return (await _auth.getAvailableBiometrics()).isNotEmpty ||
          await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Reads the flag, migrating it out of SharedPreferences the first time
  /// (the storage it lived in before this app moved to the hardware vault).
  Future<bool?> _readEnabled() async {
    if (!_migrated) {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getBool(_kEnabled);
      if (legacy != null) {
        try {
          await _storage.write(
              key: _kEnabled, value: legacy ? 'true' : 'false');
          await prefs.remove(_kEnabled);
        } catch (_) {
          // Migration failure is non-fatal: the legacy value stays put and is
          // read again next launch.
        }
      }
      _migrated = true;
    }
    try {
      final raw = await _storage.read(key: _kEnabled);
      return raw == null ? null : raw == 'true';
    } catch (_) {
      // Unsupported platforms (web, desktop) simply have no lock flag.
      return null;
    }
  }

  Future<void> init() async {
    _enabled = (await _readEnabled()) ?? false;
    // Enabled implies locked until the user proves themselves at startup.
    _locked = _enabled;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    // Turning it on locks immediately; turning it off unlocks.
    _locked = value;
    try {
      await _storage.write(key: _kEnabled, value: value ? 'true' : 'false');
    } catch (_) {
      // A storage failure must not wedge the toggle; the in-memory state is
      // already correct for this session.
    }
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
        localizedReason: L10n.t('Unlock Mystic Ledger to see your records.'),
        options: const AuthenticationOptions(
          biometricOnly: false,
          // stickyAuth caches the last result on Android, so a cancelled or
          // interrupted attempt can silently suppress every later prompt — the
          // app would stay sealed no matter how many times UNLOCK is tapped.
          stickyAuth: false,
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

  /// Re-verifies the user before a sensitive action (account deletion, data
  /// export, import, currency reset). No-op when the lock is disabled.
  /// Returns true when the action may proceed.
  Future<bool> requireAuth() async {
    if (!_enabled) return true;
    return authenticate();
  }
}
