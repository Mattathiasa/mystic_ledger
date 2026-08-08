import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'sms_capture_store.dart';
import 'telebirr_parser.dart';

/// Background-isolate handler for the `telephony` plugin.
///
/// MUST stay a top-level function: the plugin needs a stable `CallbackHandle`
/// to wake it when an SMS arrives while the app is closed. It only ever talks
/// to [SmsCaptureStore], so no widget state or service instance is involved.
Future<void> smsBackgroundHandler(SmsMessage message) async {
  await SmsCaptureStore.captureIncoming(
    // The plugin exposes raw values: id is the row id (int) and date is a
    // millisecond timestamp. Normalise them here so the store only ever sees
    // the friendly types.
    id: message.id?.toString(),
    sender: message.address ?? '',
    body: message.body ?? '',
    date: message.date == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(message.date!),
  );
}

/// Orchestrates SMS auto-capture and exposes the draft queue to the UI.
///
/// A singleton on purpose: it is app-scoped rather than user-scoped. Captured
/// drafts live on the device (via [SmsCaptureStore]) and are reviewed before
/// they ever touch Firestore, so they belong to no account until the user
/// approves them.
class SmsCaptureService extends ChangeNotifier {
  SmsCaptureService._();

  static final SmsCaptureService instance = SmsCaptureService._();

  List<CapturedSms> _drafts = [];
  bool _enabled = false;

  /// True on a device where this feature can work at all (Android).
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  List<CapturedSms> get pendingDrafts => List.unmodifiable(_drafts);
  bool get isEnabled => _enabled;
  int get pendingCount => _drafts.length;

  /// Loads persisted state. Call once at app start.
  Future<void> init() async {
    _enabled = await SmsCaptureStore.isEnabled();
    _drafts = await SmsCaptureStore.loadDrafts();
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    await SmsCaptureStore.setEnabled(value);
    if (value && supported) await _registerListener();
    notifyListeners();
  }

  /// Asks the OS for READ_SMS + RECEIVE_SMS (runtime permissions). The OS
  /// dialog only appears on the first request; afterwards it returns the
  /// current grant state.
  Future<bool> requestPermission() async {
    if (!supported) return false;
    final granted = await Telephony.instance.requestSmsPermissions;
    return granted ?? false;
  }

  /// Starts listening for incoming SMS. No-op when disabled or unsupported.
  Future<void> startListening() async {
    if (!_enabled) return;
    if (!supported) return;
    await _registerListener();
  }

  Future<void> _registerListener() async {
    Telephony.instance.listenIncomingSms(
      onNewMessage: _onForegroundMessage,
      onBackgroundMessage: smsBackgroundHandler,
    );
  }

  void _onForegroundMessage(SmsMessage message) {
    // Fire-and-forget: capture is persisted before the user could possibly
    // interact with anything. The plugin's date is the raw Android SMS DATE
    // column — milliseconds since epoch.
    handleMessage(message);
  }

  /// Entry point for one SMS — gate, dedup, parse, queue, notify.
  Future<void> handleMessage(SmsMessage message) async {
    final draft = await SmsCaptureStore.captureIncoming(
      id: message.id?.toString(),
      sender: message.address ?? '',
      body: message.body ?? '',
      date: message.date == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(message.date!),
    );
    if (draft == null) return;
    await _refreshDrafts();
  }

  /// Scans the inbox for past Telebirr alerts and queues them as drafts.
  ///
  /// Two targeted queries rather than one dump: alerts may carry the brand in
  /// the body, the sender field, or both. Dedup signatures keep this safe even
  /// if a message was already captured live. Returns how many were added, or
  /// -1 when the inbox could not be read (permission missing or a platform
  /// error) so callers can say so honestly instead of claiming "none found".
  Future<int> backfillInbox() async {
    if (!supported || !_enabled) return 0;
    // Asks on first use (or returns the current grant state); a scan without
    // read access is meaningless.
    final granted = await Telephony.instance.requestSmsPermissions;
    if (granted != true) return -1;

    try {
      final telephony = Telephony.instance;
      final byBody = await telephony.getInboxSms(
        filter: SmsFilter.where(SmsColumn.BODY).like('%telebirr%'),
      );
      final bySender = await telephony.getInboxSms(
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals('Telebirr'),
      );

      var added = 0;
      for (final m in {...byBody, ...bySender}) {
        final draft = await SmsCaptureStore.captureIncoming(
          id: m.id?.toString(),
          sender: m.address ?? '',
          body: m.body ?? '',
          date: m.date == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(m.date!),
        );
        if (draft != null) added++;
      }
      if (added > 0) await _refreshDrafts();
      return added;
    } catch (_) {
      return -1;
    }
  }

  /// Re-reads the queue from disk. Call on app resume so drafts captured by
  /// the background isolate while the app was paused show up.
  Future<void> refresh() async {
    await _refreshDrafts();
  }

  /// Removes a draft without recording anything (user decided it was not
  /// theirs, or a duplicate slipped through).
  Future<void> dismiss(String id) async {
    await SmsCaptureStore.removeDraft(id);
    await _refreshDrafts();
  }

  /// Called once the user has saved the entry for [draft] — clears the queue.
  Future<void> approve(CapturedSms draft) async {
    await SmsCaptureStore.removeDraft(draft.id);
    await _refreshDrafts();
  }

  Future<void> _refreshDrafts() async {
    _drafts = await SmsCaptureStore.loadDrafts();
    notifyListeners();
  }
}
