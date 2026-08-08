// SMS parsing for captured bank alerts (Telebirr + CBE).
//
// Regexes here are tuned against real messages the owner forwarded (see
// test/sms_parser_test.dart). Wording varies by language and release, so
// every pattern degrades gracefully: a missed match lowers SmsConfidence
// rather than dropping the message, and every capture passes through the
// review queue before it can reach the ledger.

/// How confident the parser is about a captured message.
///
/// [high] means amount + direction were both extracted cleanly. [medium]
/// means the amount was found but the direction is uncertain. [low] is a
/// message that only *looks* like a bank alert; it still lands in the review
/// queue so nothing is ever silently dropped.
enum SmsConfidence { high, medium, low }

/// Whether the money came in or went out, as far as the SMS can say.
enum CapturedDirection { income, expense, unknown }

/// Which service sent the alert.
enum CapturedBank {
  telebirr,
  cbe;

  String get label => switch (this) {
        CapturedBank.telebirr => 'Telebirr',
        CapturedBank.cbe => 'CBE',
      };
}

/// The meaningful bits of one captured bank SMS.
///
/// [body] is kept on the draft so the review screen can show exactly what was
/// read — it stays on the device and never leaves it.
class CapturedSms {
  final String id;              // dedup key — stable across live + backfill
  final CapturedBank bank;
  final String sender;          // sender number/name the SMS came from
  final String body;            // raw message text (on-device only)
  final double? amount;         // null ⇒ could not be parsed
  final CapturedDirection direction;
  final String? counterparty;   // name or number money moved to/from
  final double? fee;            // total service charge, when stated
  final String? reference;      // bank transaction reference, when stated
  final DateTime? date;         // SMS timestamp ≈ transaction time
  final DateTime capturedAt;
  final SmsConfidence confidence;

  const CapturedSms({
    required this.id,
    required this.bank,
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
        'bank':        bank.name,
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
        // Drafts captured before multi-bank support are Telebirr by definition.
        bank:  CapturedBank.values.firstWhere(
            (e) => e.name == m['bank'],
            orElse: () => CapturedBank.telebirr),
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

/// Which service an alert came from, or null when it matches no known bank.
///
/// The alpha sender ID (when the platform supplies one) is the strongest
/// signal; otherwise the brand is found in the body.
CapturedBank? detectBank({required String sender, required String body}) {
  final s = sender.toLowerCase();
  final b = body.toLowerCase();

  if (s.contains('telebirr')) return CapturedBank.telebirr;
  if (s.contains('cbe')) return CapturedBank.cbe;

  if (b.contains('ተለቢር') || // Telebirr in Amharic
      b.contains('telebir') ||
      b.contains('ethio telecom') ||
      (b.contains('etb') && b.contains('mobile money'))) {
    return CapturedBank.telebirr;
  }
  if (b.contains('banking with cbe') ||
      b.contains('cbe.com') ||
      b.contains('commercial bank of ethiopia') ||
      (b.contains('cbe') &&
          (b.contains('credited') ||
              b.contains('debited') ||
              b.contains('transferred') ||
              b.contains('service charge')))) {
    return CapturedBank.cbe;
  }
  return null;
}

/// Stable dedup key for one SMS, identical whether the message arrived via the
/// live listener or a later inbox backfill. Uses the message id when the
/// platform supplied one, otherwise hashes sender + body.
String smsSignature({
  required String? id,
  required String sender,
  required String body,
}) {
  if (id != null && id.isNotEmpty) return 'id:$id';
  return 'sig:${Object.hashAll([sender, body]).toRadixString(16)}';
}

/// Parses [body] for the given [bank]. Never throws and never returns null —
/// the caller always gets a draft; a message that matches nothing just ends up
/// with low confidence so the review queue can present it for manual entry.
SmsParseResult parseSms(CapturedBank bank, String body) => switch (bank) {
      CapturedBank.telebirr => _parseTelebirr(body),
      CapturedBank.cbe => _parseCbe(body),
    };

// ── Shared helpers ────────────────────────────────────────────────────────────

// Amount may be written with the currency before ("ETB 1,000.00", "ETB60.00")
// or after ("1,000.00 Birr"), and "ብር" is Birr in Amharic. The first match in
// the text wins, and the transaction amount is stated before balances and
// totals, so those never shadow it.
final _amountRe = RegExp(
    r'(?:ETB|Birr|birr|ብር)\s*([\d,]+(?:\.\d{1,2})?)'
    r'|([\d,]+(?:\.\d{1,2})?)\s*(?:ETB|Birr|birr|ብር)',
    caseSensitive: false);

final _fullPhoneRe = RegExp(r'(\+?251|0)9\d{8}');

/// Masked phone in parentheses, as Telebirr prints them: "(2519****0924)".
final _maskedPhoneRe = RegExp(r'\(\d{4}\*+\d{4}\)');

/// The date clause Telebirr appends: " on 06/08/2026 13:57:59".
final _onDateRe = RegExp(r'\son\s\d{1,2}/\d{1,2}/\d{4}');

double? _firstAmount(String body) {
  final m = _amountRe.firstMatch(body);
  if (m == null) return null;
  return _toDouble(m.group(1) ?? m.group(2)!);
}

double? _firstMatchDouble(String body, RegExp re) {
  final m = re.firstMatch(body);
  return m == null ? null : _toDouble(m.group(1)!);
}

double _toDouble(String raw) => double.tryParse(raw.replaceAll(',', '')) ?? 0;

SmsConfidence _confidenceFor(double? amount, CapturedDirection direction) =>
    switch ((amount, direction)) {
      (final double? a, CapturedDirection.unknown) when a != null =>
          SmsConfidence.medium,
      (null, CapturedDirection.unknown) => SmsConfidence.low,
      _ => SmsConfidence.high,
    };

// ── Telebirr ──────────────────────────────────────────────────────────────────
//
// "You have transferred ETB 30.00 to Arega Teshome (2519****0924) on
//  06/08/2026 13:57:59. Your transaction number is DH60KIPTPI. The service
//  fee is ETB 0.87 and 15% VAT on the service fee is ETB 0.13. ..."

final _telebirrRefRe = RegExp(
    r'(?:Ref(?:erence)?|Transaction\s*(?:Number|No|ID)|Txn\s*(?:Number|No|ID))'
    r'[\s:#-]*(?:is\s*)?([A-Za-z0-9]{4,})',
    caseSensitive: false);
final _telebirrServiceFeeRe = RegExp(
    r'service\s*fee(?:\s+is)?\s*(?:ETB\s*)?([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false);
final _telebirrVatRe = RegExp(
    r'VAT[^.]*?\bis\s*(?:ETB\s*)?([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false);

final _incomeWords = [
  'received', 'credit', 'credited', 'deposited', 'deposit', 'top up', 'topup',
  'money in', 'added to', 'came in', 'incoming',
];
final _expenseWords = [
  'sent', 'paid', 'payment', 'pay', 'debit', 'debited', 'withdraw', 'withdrew',
  'withdrawal', 'cash out', 'cashout', 'purchase', 'transfer', 'transferred',
  'money out', 'outgoing', 'deduct',
];

SmsParseResult _parseTelebirr(String body) {
  final amount = _firstAmount(body);
  final direction = _detectTelebirrDirection(body);
  return SmsParseResult(
    amount: amount,
    direction: direction,
    counterparty: _extractTelebirrCounterparty(body),
    // The true charge is service fee + the VAT levied on it — Telebirr prints
    // both, and the account balance drop includes the sum.
    fee: _telebirrFee(body),
    reference: _firstMatch(body, _telebirrRefRe),
    confidence: _confidenceFor(amount, direction),
  );
}

CapturedDirection _detectTelebirrDirection(String body) {
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

String? _firstMatch(String body, RegExp re) => re.firstMatch(body)?.group(1);

String? _extractTelebirrCounterparty(String body) {
  // A full phone number is the most reliable signal.
  final phone = _fullPhoneRe.firstMatch(body);
  if (phone != null) return phone.group(0);

  // The name sits between a "from"/"to" marker and where it visibly ends: a
  // masked number in parentheses (with or without a space before it), a date
  // clause, or the first sentence break after the marker. Amounts like
  // "1,000.00" appear *before* the marker, so their dots never confuse the cut.
  final masked = _maskedPhoneRe.firstMatch(body);
  final onDate = _onDateRe.firstMatch(body);

  for (final marker in const [' to ', ' from ', ' to: ', ' from: ']) {
    final idx = body.indexOf(marker);
    if (idx == -1) continue;
    final start = idx + marker.length;

    var end = body.length;
    if (masked != null && masked.start > start) end = masked.start;
    if (onDate != null && onDate.start > start && onDate.start < end) {
      end = onDate.start;
    }
    final sentence = body.indexOf(RegExp(r'[.\n!]'), start);
    if (sentence != -1 && sentence < end) end = sentence;

    final raw = body.substring(start, end).trim();
    if (raw.isNotEmpty && raw.length <= 60) return raw;
  }
  return null;
}

double? _telebirrFee(String body) {
  final service = _firstMatchDouble(body, _telebirrServiceFeeRe) ?? 0;
  final vat = _firstMatchDouble(body, _telebirrVatRe) ?? 0;
  final total = service + vat;
  return total > 0 ? total : null;
}

// ── CBE ───────────────────────────────────────────────────────────────────────
//
// "You have successfully transferred ETB60.00 from account 1**0486 to account
//  1**9696 (Yordanos Taye Bayu). Service charge of ETB 0.50 and VAT(15%) of
//  ETB0.08 and Disaster Recovery(5%) of 0.03 with total of ETB60.61. ..."
// "your Account 1****0486 has been credited by SALARY SUSPENSE AGOZA GEBEYA
//  BRANCH with ETB 13000.00. Your Current Balance is ETB 21878.45. ..."

final _cbeTotalRe = RegExp(
    r'total\s+of\s*(?:ETB\s*)?([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false);
final _cbeServiceChargeRe = RegExp(
    r'service\s+charge\s+of\s*(?:ETB\s*)?([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false);
final _cbeRefRe =
    RegExp(r'((?:FT[A-Z0-9]{8,}|v2-[A-Za-z0-9]{6,}))');
final _cbeParenNameRe =
    RegExp(r'\(\s*([A-Za-z][A-Za-z\s.]{2,40}?)\s*\)');
final _cbeByRe = RegExp(
    r'\bby\s+([A-Za-z][A-Za-z0-9\s.]{2,40}?)\s+(?:with\b|\.|!|,|Your|Total|Service|on\b)',
    caseSensitive: false);
final _cbeToRe = RegExp(
    r'\bto\s+([A-Za-z][A-Za-z0-9\s.]{2,40}?)\s*(?:\.|!|,|Your|Total|Service)',
    caseSensitive: false);

SmsParseResult _parseCbe(String body) {
  final amount = _firstAmount(body);
  final direction = _detectCbeDirection(body);
  return SmsParseResult(
    amount: amount,
    direction: direction,
    counterparty: _extractCbeCounterparty(body),
    // "total of ETB X" already includes every charge — the difference is the
    // exact combined fee. Fall back to the stated service charge.
    fee: _cbeFee(body, amount),
    reference: _firstMatch(body, _cbeRefRe),
    confidence: _confidenceFor(amount, direction),
  );
}

CapturedDirection _detectCbeDirection(String body) {
  final lower = body.toLowerCase();
  if (lower.contains('credited')) return CapturedDirection.income;
  if (lower.contains('debited')) return CapturedDirection.expense;
  // Moving money between one's own accounts is neither income nor expense.
  if (lower.contains('transferred') &&
      lower.contains('from account') &&
      lower.contains('to account')) {
    return CapturedDirection.unknown;
  }
  if (lower.contains('transferred') || lower.contains('transfer')) {
    return CapturedDirection.expense;
  }
  return CapturedDirection.unknown;
}

String? _extractCbeCounterparty(String body) {
  // "to account 1**9696 (Yordanos Taye Bayu)" — the payee name in parens.
  final paren = _cbeParenNameRe.firstMatch(body);
  if (paren != null) return paren.group(1);

  // "credited by SALARY SUSPENSE AGOZA GEBEYA BRANCH with ETB ..."
  final by = _cbeByRe.firstMatch(body);
  if (by != null) return by.group(1);

  // "transferred ... to Yordanos Taye Bayu"
  final to = _cbeToRe.firstMatch(body);
  if (to != null) return to.group(1);

  return null;
}

double? _cbeFee(String body, double? amount) {
  final total = _firstMatchDouble(body, _cbeTotalRe);
  if (total != null && amount != null && total > amount) {
    return total - amount;
  }
  return _firstMatchDouble(body, _cbeServiceChargeRe);
}
