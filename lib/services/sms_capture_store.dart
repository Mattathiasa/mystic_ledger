import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import 'sms_parser.dart';

/// On-device persistence for SMS auto-capture.
///
/// Everything here is deliberately static and independent of any widget or
/// service instance: the `telephony` plugin runs its background handler in a
/// separate isolate, where it must be able to store a captured message without
/// reaching for app state. Both the background isolate and the foreground
/// [SmsCaptureService] funnel through this one class, so the two never fight
/// over different caches.
///
/// Privacy contract: only *parsed* fields (amount, direction, counterparty,
/// fee, reference) and the raw body needed for the review screen are stored,
/// and they are stored on the device only. Nothing here is ever uploaded.
class SmsCaptureStore {
  SmsCaptureStore._();

  static const _kDrafts = 'sms_capture_drafts';
  static const _kProcessed = 'sms_capture_processed';
  static const _kEnabled = 'sms_capture_enabled';

  // ── Enabled flag (read by the background isolate too) ─────────────────────

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
  }

  // ── Draft queue ───────────────────────────────────────────────────────────

  static Future<List<CapturedSms>> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDrafts);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(CapturedSms.fromJson).toList();
  }

  static Future<void> _saveDrafts(List<CapturedSms> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kDrafts, jsonEncode(drafts.map((d) => d.toJson()).toList()));
  }

  /// Adds [draft] unless a message with the same signature is already queued.
  /// Returns true when the draft was actually queued.
  static Future<bool> addDraft(CapturedSms draft) async {
    final drafts = await loadDrafts();
    if (drafts.any((d) => d.id == draft.id)) return false;
    drafts.insert(0, draft); // newest first
    await _saveDrafts(drafts);
    return true;
  }

  static Future<void> removeDraft(String id) async {
    final drafts = await loadDrafts();
    drafts.removeWhere((d) => d.id == id);
    await _saveDrafts(drafts);
  }

  // ── Dedup: signatures already turned into drafts ──────────────────────────

  static Future<Set<String>> _loadProcessed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kProcessed) ?? const []).toSet();
  }

  static Future<bool> isProcessed(String signature) async {
    final set = await _loadProcessed();
    return set.contains(signature);
  }

  static Future<void> markProcessed(String signature) async {
    final set = await _loadProcessed();
    set.add(signature);
    // Cap the set so it cannot grow without bound over years of alerts.
    final trimmed = set.length > 5000 ? set.take(5000).toSet() : set;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kProcessed, trimmed.toList());
  }

  /// Queues a draft for a recurring schedule that has come due.
  ///
  /// Presented through the same review queue as SMS captures (same banner,
  /// same RECORD flow). The id encodes the occurrence date, so re-running a
  /// check (another resume, a refresh) can never queue the same occurrence
  /// twice. Returns true when the draft was newly queued.
  static Future<bool> addRecurringDraft(RecurringTransaction r) async {
    final draft = CapturedSms(
      id: 'recurring:${r.id}:${r.nextDue.millisecondsSinceEpoch}',
      bank: CapturedBank.recurring,
      sender: 'Recurring',
      body:
          'Recurring: ${r.title} — ${r.frequency.label} · next due '
          '${r.nextDue.toString()} — review before recording.',
      amount: r.amount,
      direction: r.type == TransactionType.income
          ? CapturedDirection.income
          : CapturedDirection.expense,
      counterparty: r.title,
      fee: null,
      reference: null,
      date: r.nextDue,
      capturedAt: DateTime.now(),
      confidence: SmsConfidence.high,
    );
    return addDraft(draft);
  }

  /// Full pipeline for a raw incoming SMS: gate, dedup, parse, queue.
  ///
  /// Used by both the foreground service and the background isolate. Returns
  /// the drafted message, or null when the SMS was ignored (disabled, not
  /// Telebirr, or already captured).
  static Future<CapturedSms?> captureIncoming({
    String? id,
    required String sender,
    required String body,
    DateTime? date,
  }) async {
    if (!await isEnabled()) return null;
    final bank = detectBank(sender: sender, body: body);
    if (bank == null) return null;

    final signature = smsSignature(id: id, sender: sender, body: body);
    if (await isProcessed(signature)) return null;

    final parsed = parseSms(bank, body);
    final draft = CapturedSms(
      id: signature,
      bank: bank,
      sender: sender,
      body: body,
      amount: parsed.amount,
      direction: parsed.direction,
      counterparty: parsed.counterparty,
      fee: parsed.fee,
      reference: parsed.reference,
      date: date,
      capturedAt: DateTime.now(),
      confidence: parsed.confidence,
    );
    // Queue first, mark processed after. A crash in between leaves the message
    // unprocessed, so the next pass re-runs this — and addDraft's id check
    // turns that retry into a no-op rather than a duplicate or a lost alert.
    final added = await addDraft(draft);
    await markProcessed(signature); // queued (new or already there) either way
    return added ? draft : null;
  }
}
