import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/services/sms_parser.dart';

// Samples 1–4 are REAL messages the app owner forwarded. 5+ are synthetic
// stand-ins for formats the parser must also tolerate. The parser is
// deliberately tolerant and every capture passes through the review queue, so
// a wording change degrades confidence rather than losing a transaction.

const realTelebirrSent = 'Dear MATTATHIAS \n'
    'You have transferred ETB 30.00 to Arega Teshome (2519****0924) on '
    '06/08/2026 13:57:59. Your transaction number is DH60KIPTPI. The service '
    'fee is  ETB 0.87 and  15% VAT on the service fee is ETB 0.13. Your '
    'current E-Money Account  balance is ETB 121.61. To download your payment '
    'information please click this link: '
    'https://transactioninfo.ethiotelecom.et/receipt/DH60KIPTPI.\n\n'
    'Thank you for using telebirr\nEthio telecom';

const realTelebirrReceived = 'Dear MATTATHIAS \n'
    'You have received ETB 110.00 from SAMUEL TEMESEGEN(2519****4016)  on '
    '06/08/2026 13:57:18. Your transaction number is DH68KIOY0C. Your current '
    'E-Money Account balance is ETB 152.61.\n'
    'Thank you for using telebirr\nEthio telecom';

const realCbeTransfer = 'Dear  Mattathias Abraham Belayneh You have '
    'successfully transferred ETB60.00 from account 1**0486 to account 1**9696 '
    '(Yordanos Taye Bayu). Service charge of ETB 0.50 and VAT(15%) of ETB0.08 '
    'and Disaster Recovery(5%) of 0.03 with total of ETB60.61 .Your current '
    'balance is ETB21,817.84. Thanks for Banking with CBE. '
    'https://mbreciept.cbe.com.et/v2-hfHCxG7d5TZoDYoSPR6m  for feedback: '
    'https://forms.gle/kGNGQpG3mQCCk3iD6';

const realCbeCredit = 'Dear Mr Mattathias your Account 1****0486 has been '
    'credited by SALARY SUSPENSE AGOZA GEBEYA BRANCH with ETB 13000.00. Your '
    'Current Balance is ETB 21878.45. Thank you for Banking with CBE! for '
    'Reciept https://apps.cbe.com.et:100/BranchReceipt/FT26217N43BR&52290486';

void main() {
  group('detectBank', () {
    test('identifies Telebirr from body or sender', () {
      expect(detectBank(sender: 'Telebirr', body: 'hi'), CapturedBank.telebirr);
      expect(detectBank(sender: '9999', body: realTelebirrSent),
          CapturedBank.telebirr);
      expect(detectBank(sender: '9999', body: 'ተለቢር: ገንዘብ ተቀብለዋል'),
          CapturedBank.telebirr);
    });

    test('identifies CBE from body or sender', () {
      expect(detectBank(sender: 'CBE', body: 'hi'), CapturedBank.cbe);
      expect(detectBank(sender: '8080', body: realCbeCredit),
          CapturedBank.cbe);
      expect(detectBank(sender: '8080', body: realCbeTransfer),
          CapturedBank.cbe);
    });

    test('returns null for unrelated messages', () {
      expect(
          detectBank(
              sender: 'SPAM', body: 'Congratulations, you have won a prize!'),
          isNull);
      expect(
          detectBank(
              sender: 'AWASH', body: 'Your account balance is ETB 500.00'),
          isNull);
    });
  });

  group('real Telebirr samples', () {
    test('transfer out: amount, counterparty, fee incl. VAT, reference', () {
      final r = parseSms(CapturedBank.telebirr, realTelebirrSent);
      expect(r.amount, 30.0);
      expect(r.direction, CapturedDirection.expense);
      expect(r.counterparty, 'Arega Teshome');
      expect(r.reference, 'DH60KIPTPI');
      // Service fee 0.87 + 15% VAT 0.13 — the balance drop proves the sum.
      expect(r.fee, closeTo(1.0, 0.0001));
      expect(r.confidence, SmsConfidence.high);
    });

    test('received: amount, counterparty, no fee, reference', () {
      final r = parseSms(CapturedBank.telebirr, realTelebirrReceived);
      expect(r.amount, 110.0);
      expect(r.direction, CapturedDirection.income);
      expect(r.counterparty, 'SAMUEL TEMESEGEN');
      expect(r.reference, 'DH68KIOY0C');
      expect(r.fee, isNull);
      expect(r.confidence, SmsConfidence.high);
    });
  });

  group('real CBE samples', () {
    test('internal transfer: amount, payee, combined fee from total', () {
      final r = parseSms(CapturedBank.cbe, realCbeTransfer);
      expect(r.amount, 60.0);
      // Own account → own account is neither income nor expense.
      expect(r.direction, CapturedDirection.unknown);
      expect(r.counterparty, 'Yordanos Taye Bayu');
      // total 60.61 − amount 60.00 = 0.61 (charge + VAT + disaster recovery).
      expect(r.fee, closeTo(0.61, 0.0001));
      expect(r.reference, 'v2-hfHCxG7d5TZoDYoSPR6m');
      expect(r.confidence, SmsConfidence.medium);
    });

    test('salary credit: amount, branch name, reference from receipt URL', () {
      final r = parseSms(CapturedBank.cbe, realCbeCredit);
      expect(r.amount, 13000.0);
      expect(r.direction, CapturedDirection.income);
      expect(r.counterparty, 'SALARY SUSPENSE AGOZA GEBEYA BRANCH');
      expect(r.reference, 'FT26217N43BR');
      expect(r.fee, isNull);
      expect(r.confidence, SmsConfidence.high);
    });
  });

  group('synthetic tolerance cases', () {
    test('amount without direction words → medium confidence', () {
      final r = parseSms(CapturedBank.telebirr,
          'Telebirr: ETB 500.00 mobile money entry.');
      expect(r.amount, 500.0);
      expect(r.direction, CapturedDirection.unknown);
      expect(r.confidence, SmsConfidence.medium);
    });

    test('amount written with the currency after the number', () {
      final r = parseSms(
          CapturedBank.telebirr, 'You have paid 500.00 Birr to Addis Cafe.');
      expect(r.amount, 500.0);
      expect(r.direction, CapturedDirection.expense);
    });

    test('unrecognised text → low confidence, no amount, never throws', () {
      final r = parseSms(CapturedBank.cbe, 'Some unrelated text.');
      expect(r.amount, isNull);
      expect(r.direction, CapturedDirection.unknown);
      expect(r.confidence, SmsConfidence.low);
    });

    test('empty body is handled', () {
      final r = parseSms(CapturedBank.telebirr, '');
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
        bank: CapturedBank.cbe,
        sender: 'CBE',
        body: 'credited by SALARY with ETB 13000.00',
        amount: 13000.0,
        direction: CapturedDirection.income,
        counterparty: 'SALARY',
        fee: null,
        reference: 'FT26217N43BR',
        date: DateTime(2026, 8, 8, 12, 30),
        capturedAt: DateTime(2026, 8, 8, 12, 31),
        confidence: SmsConfidence.high,
      );

      final restored = CapturedSms.fromJson(draft.toJson());
      expect(restored.id, draft.id);
      expect(restored.bank, draft.bank);
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

    test('pre-bank drafts default to Telebirr; older drafts keep working', () {
      final restored = CapturedSms.fromJson(const {
        'id': 'sig:legacy',
        'amount': 250.0,
        'direction': 'expense',
        'confidence': 'medium',
        'capturedAt': 0,
      });
      expect(restored.id, 'sig:legacy');
      expect(restored.bank, CapturedBank.telebirr);
      expect(restored.amount, 250.0);
      expect(restored.direction, CapturedDirection.expense);
      expect(restored.confidence, SmsConfidence.medium);
      expect(restored.body, '');
      expect(restored.date, isNull);
    });
  });
}
