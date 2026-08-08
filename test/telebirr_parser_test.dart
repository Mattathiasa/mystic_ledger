import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/services/telebirr_parser.dart';

// The sample messages below use representative Telebirr alert wording. Exact
// templates vary by language and app release; the parser is deliberately
// tolerant and every capture passes through the review queue, so a format
// change degrades confidence rather than losing a transaction.

void main() {
  group('looksLikeTelebirr', () {
    test('matches brand in body or sender', () {
      expect(looksLikeTelebirr(sender: 'Telebirr', body: 'Received ETB 100'),
          isTrue);
      expect(
          looksLikeTelebirr(
              sender: '9999', body: 'Telebirr: you have received ETB 500.00'),
          isTrue);
      expect(
          looksLikeTelebirr(sender: 'ETHIO', body: 'Ethio telecom payment'),
          isTrue);
    });

    test('ignores unrelated bank messages', () {
      expect(
          looksLikeTelebirr(
              sender: 'CBE', body: 'Your account was credited with ETB 900'),
          isFalse);
      expect(looksLikeTelebirr(sender: 'SPAM', body: 'Congratulations'), isFalse);
    });

    test('matches the Amharic brand name', () {
      expect(
          looksLikeTelebirr(
              sender: '9999', body: 'ተለቢር: ገንዘብ ተቀብለዋል'),
          isTrue);
    });
  });

  group('parseTelebirrSms — income', () {
    test('extracts amount, direction and counterparty name', () {
      final r = parseTelebirrSms(
          'You have received ETB 1,000.00 from Abebe Kebede. '
          'Telebirr Ref: 8X2TZ88PJ. Balance ETB 2,340.50.');
      expect(r.amount, 1000.0);
      expect(r.direction, CapturedDirection.income);
      expect(r.counterparty, 'Abebe Kebede');
      expect(r.reference, '8X2TZ88PJ');
      expect(r.confidence, SmsConfidence.high);
    });

    test('extracts counterparty phone number', () {
      final r = parseTelebirrSms(
          'You have received ETB 300.00 from 0912345678. Ref: ABC12345');
      expect(r.amount, 300.0);
      expect(r.direction, CapturedDirection.income);
      expect(r.counterparty, '0912345678');
    });
  });

  group('parseTelebirrSms — expense', () {
    test('extracts amount, direction, phone and service fee', () {
      final r = parseTelebirrSms(
          'You have sent ETB 250.00 to 0987654321. '
          'Service fee ETB 3.00. Ref: 77KLP90Q');
      expect(r.amount, 250.0);
      expect(r.direction, CapturedDirection.expense);
      expect(r.counterparty, '0987654321');
      expect(r.fee, 3.0);
      expect(r.reference, '77KLP90Q');
      expect(r.confidence, SmsConfidence.high);
    });

    test('detects payments and withdrawals', () {
      final paid = parseTelebirrSms('You have paid ETB 120.00 to Addis Cafe.');
      expect(paid.direction, CapturedDirection.expense);

      final withdrew = parseTelebirrSms('You withdrew ETB 2,000.00 at Agent.');
      expect(withdrew.direction, CapturedDirection.expense);
      expect(withdrew.amount, 2000.0);
    });

    test('parses amount written with the currency after the number', () {
      final r = parseTelebirrSms('You have paid 500.00 Birr to Addis Cafe.');
      expect(r.amount, 500.0);
      expect(r.direction, CapturedDirection.expense);
    });
  });

  group('parseTelebirrSms — degraded input', () {
    test('amount without direction words → medium confidence', () {
      final r = parseTelebirrSms('Telebirr: ETB 500.00 mobile money entry.');
      expect(r.amount, 500.0);
      expect(r.direction, CapturedDirection.unknown);
      expect(r.confidence, SmsConfidence.medium);
    });

    test('unrecognised text → low confidence, no amount, never throws', () {
      final r = parseTelebirrSms('Some unrelated promotional text.');
      expect(r.amount, isNull);
      expect(r.direction, CapturedDirection.unknown);
      expect(r.confidence, SmsConfidence.low);
    });

    test('empty body is handled', () {
      final r = parseTelebirrSms('');
      expect(r.amount, isNull);
      expect(r.confidence, SmsConfidence.low);
    });
  });

  group('smsSignature', () {
    test('is stable for identical messages', () {
      expect(
        smsSignature(id: '12', sender: 'Telebirr', body: 'Received ETB 100'),
        smsSignature(id: '12', sender: 'Telebirr', body: 'Received ETB 100'),
      );
    });

    test('differs across messages without an id (hashes sender + body)', () {
      expect(
        smsSignature(id: null, sender: 'Telebirr', body: 'Received ETB 100'),
        isNot(smsSignature(
            id: null, sender: 'Telebirr', body: 'Received ETB 101')),
      );
    });
  });

  group('CapturedSms serialisation', () {
    test('round-trips through JSON', () {
      final draft = CapturedSms(
        id: 'sig:abc123',
        sender: 'Telebirr',
        body: 'You have received ETB 1,000.00 from Abebe.',
        amount: 1000.0,
        direction: CapturedDirection.income,
        counterparty: 'Abebe',
        fee: null,
        reference: 'REF9X',
        date: DateTime(2026, 8, 8, 12, 30),
        capturedAt: DateTime(2026, 8, 8, 12, 31),
        confidence: SmsConfidence.high,
      );

      final restored = CapturedSms.fromJson(draft.toJson());
      expect(restored.id, draft.id);
      expect(restored.sender, draft.sender);
      expect(restored.body, draft.body);
      expect(restored.amount, draft.amount);
      expect(restored.direction, draft.direction);
      expect(restored.counterparty, draft.counterparty);
      expect(restored.reference, draft.reference);
      expect(restored.date, draft.date);
      expect(restored.capturedAt, draft.capturedAt);
      expect(restored.confidence, draft.confidence);
    });

    test('survives older drafts that lack optional fields', () {
      final restored = CapturedSms.fromJson(const {
        'id': 'sig:legacy',
        'amount': 250.0,
        'direction': 'expense',
        'confidence': 'medium',
        'capturedAt': 0,
      });
      expect(restored.id, 'sig:legacy');
      expect(restored.amount, 250.0);
      expect(restored.direction, CapturedDirection.expense);
      expect(restored.confidence, SmsConfidence.medium);
      expect(restored.body, '');
      expect(restored.date, isNull);
    });
  });
}
