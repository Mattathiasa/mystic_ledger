/// How confident the parser is about a captured message.
///
/// [high] means amount + direction were both extracted cleanly — the draft can
/// usually be approved as-is. [medium] means the amount was found but the
/// direction is uncertain (an outgoing payment that reads like a top-up).
/// [low] is a message that only *looks* Telebirr; the draft still lands in the
/// review queue so nothing is ever silently dropped.
enum SmsConfidence { high, medium, low }

/// Whether the money came in or went out, as far as the SMS can say.
enum CapturedDirection { income, expense, unknown }

/// The meaningful bits of one captured bank SMS.
///
/// [body] is kept on the draft so the review screen can show exactly what was
/// read — it stays on the device and never leaves it.
class CapturedSms {
  final String id;              // dedup key — stable across live + backfill
  final String sender;          // sender number/name the SMS came from
  final String body;            // raw message text (on-device only)
  final double? amount;         // null ⇒ could not be parsed
  final CapturedDirection direction;
  final String? counterparty;   // name or number money moved to/from
  final double? fee;            // service charge, when stated
  final String? reference;      // Telebirr transaction reference, when stated
  final DateTime? date;         // SMS timestamp ≈ transaction time
  final DateTime capturedAt;
  final SmsConfidence confidence;

  const CapturedSms({
    required this.id,
    required this.sender,
    required this.body,
    required this.amount,
    required this.direction,
    required this.counterparty,
    required this.fee,
    required this.reference,
    required this.date,
    required this.capturedAt,
    required this.confidence,
  });

  /// Direction label for the review UI.
  String get directionLabel => switch (direction) {
        CapturedDirection.income  => 'Received',
        CapturedDirection.expense => 'Sent / Paid',
        CapturedDirection.unknown => 'Direction unclear',
      };

  // ── Serialisation (SharedPreferences, on-device) ─────────────────────────

  Map<String, dynamic> toJson() => {
        'id':          id,
        'sender':      sender,
        'body':        body,
        'amount':      amount,
        'direction':   direction.name,
        'counterparty': counterparty,
        'fee':         fee,
        'reference':   reference,
        'date':        date?.millisecondsSinceEpoch,
        'capturedAt':  capturedAt.millisecondsSinceEpoch,
        'confidence':  confidence.name,
      };

  factory CapturedSms.fromJson(Map<String, dynamic> m) => CapturedSms(
        id:    m['id']    as String,
        sender: m['sender'] as String? ?? '',
        body:  m['body']  as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble(),
        direction: CapturedDirection.values.firstWhere(
            (e) => e.name == m['direction'],
            orElse: () => CapturedDirection.unknown),
        counterparty: m['counterparty'] as String?,
        fee: (m['fee'] as num?)?.toDouble(),
        reference: m['reference'] as String?,
        date: m['date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['date'] as int)
            : null,
        capturedAt: m['capturedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['capturedAt'] as int)
            : DateTime.now(),
        confidence: SmsConfidence.values.firstWhere(
            (e) => e.name == m['confidence'],
            orElse: () => SmsConfidence.low),
      );
}

/// Result of parsing a message body.
class SmsParseResult {
  final double? amount;
  final CapturedDirection direction;
  final String? counterparty;
  final double? fee;
  final String? reference;
  final SmsConfidence confidence;

  const SmsParseResult({
    required this.amount,
    required this.direction,
    required this.counterparty,
    required this.fee,
    required this.reference,
    required this.confidence,
  });
}

/// Gate: does this message look like a Telebirr transaction alert?
///
/// Matched against the sender as well as the body, because some alerts arrive
/// from a bare number with the brand name only inside the text.
bool looksLikeTelebirr({required String sender, required String body}) {
  final haystack = '$sender $body';
  final lower = haystack.toLowerCase();
  return lower.contains('telebirr') ||
      lower.contains('telebir') ||
      lower.contains('ተለቢር') || // Telebirr in Amharic
      lower.contains('ethio telecom') ||
      (lower.contains('etb') && lower.contains('mobile money'));
}

/// Stable dedup key for one SMS, identical whether the message arrived via the
/// live listener or a later inbox backfill. Uses the message id when the
/// platform supplied one, otherwise hashes sender + body.
String smsSignature({required String? id, required String sender, required String body}) {
  if (id != null && id.isNotEmpty) return 'id:$id';
  return 'sig:${Object.hashAll([sender, body]).toRadixString(16)}';
}

// ── Amount / fee / reference extraction ────────────────────────────────────────
//
// Telebirr alerts are short and formulaic but the exact wording varies by
// language and release. These patterns are deliberately tolerant: a missed
// match degrades confidence rather than dropping the message, and every draft
// passes through the review queue anyway.

// Amount may be written with the currency before ("ETB 1,000.00") or after
// ("1,000.00 Birr"), and "ብር" is Birr in Amharic. The first match wins, and
// balances are usually stated after the transaction amount, so the amount
// itself is what gets caught.
final _amountRe = RegExp(
    r'(?:ETB|Birr|birr|ብር)\s*([\d,]+(?:\.\d{1,2})?)'
    r'|([\d,]+(?:\.\d{1,2})?)\s*(?:ETB|Birr|birr|ብር)',
    caseSensitive: false);
final _feeRe = RegExp(
    r'(?:fee|charge|service\s*fee|service\s*charge)\D{0,12}?([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false);
final _refRe = RegExp(
    r'(?:Ref(?:erence)?|Transaction\s*(?:ID|No)|Txn\s*(?:ID|No))[\s:#-]*([A-Za-z0-9]{4,})',
    caseSensitive: false);
final _phoneRe = RegExp(r'(\+?251|0)9\d{8}');

/// Keywords that point at money *coming in*.
final _incomeWords = [
  'received', 'credit', 'credited', 'deposited', 'deposit', 'top up', 'topup',
  'money in', 'added to', 'came in', 'incoming',
];

/// Keywords that point at money *going out*.
final _expenseWords = [
  'sent', 'paid', 'payment', 'pay', 'debit', 'debited', 'withdraw', 'withdrew',
  'withdrawal', 'cash out', 'cashout', 'purchase', 'transfer', 'transferred',
  'money out', 'outgoing', 'deduct',
];

/// Parses one Telebirr message body.
///
/// Never throws and never returns null — the caller always gets a draft. A
/// message that fails to match anything still yields [SmsConfidence.low], so
/// the review queue can show it for manual entry.
SmsParseResult parseTelebirrSms(String body) {
  final amount = _firstAmount(body);
  final fee = _firstMatchDouble(body, _feeRe);
  final reference = _firstMatch(body, _refRe);
  final direction = _detectDirection(body);
  final counterparty = _extractCounterparty(body);

  final confidence = switch ((amount, direction)) {
    (final double? a, CapturedDirection.unknown) when a != null =>
        SmsConfidence.medium,
    (null, CapturedDirection.unknown) => SmsConfidence.low,
    _ => SmsConfidence.high,
  };

  return SmsParseResult(
    amount: amount,
    direction: direction,
    counterparty: counterparty,
    fee: fee,
    reference: reference,
    confidence: confidence,
  );
}

double? _firstAmount(String body) {
  final m = _amountRe.firstMatch(body);
  if (m == null) return null;
  return _toDouble(m.group(1) ?? m.group(2)!);
}

double? _firstMatchDouble(String body, RegExp re) {
  final m = re.firstMatch(body);
  return m == null ? null : _toDouble(m.group(1)!);
}

String? _firstMatch(String body, RegExp re) => re.firstMatch(body)?.group(1);

double _toDouble(String raw) =>
    double.tryParse(raw.replaceAll(',', '')) ?? 0;

CapturedDirection _detectDirection(String body) {
  final lower = body.toLowerCase();
  var incomeHits = 0;
  var expenseHits = 0;
  for (final w in _incomeWords) {
    if (lower.contains(w)) incomeHits++;
  }
  for (final w in _expenseWords) {
    if (lower.contains(w)) expenseHits++;
  }
  if (expenseHits > incomeHits) return CapturedDirection.expense;
  if (incomeHits > 0) return CapturedDirection.income;
  return CapturedDirection.unknown;
}

String? _extractCounterparty(String body) {
  // A phone number is the most reliable signal.
  final phone = _phoneRe.firstMatch(body);
  if (phone != null) return phone.group(0);

  final lower = body.toLowerCase();
  // Money received from X / sent to X — grab a short run of words/name after
  // the preposition, stopping at punctuation or a full stop.
  for (final marker in [' from ', ' to ', ' to: ', ' from: ']) {
    final idx = lower.indexOf(marker);
    if (idx == -1) continue;
    final start = idx + marker.length;
    final end = body.indexOf(RegExp(r'[.\n]'), start);
    final raw = body
        .substring(start, end == -1 ? body.length : end)
        .trim();
    if (raw.isNotEmpty && raw.length <= 40) return raw;
  }
  return null;
}
