import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/services/backup_service.dart';

void main() {
  group('BackupService encryption', () {
    test('encrypt → decrypt round-trips with the right password', () async {
      final bytes =
          await BackupService.encryptToFileBytes('hello ledger', 's3cret');
      // Envelope is text, not raw bytes — and carries the kdf metadata.
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      expect(envelope['kdf'], 'pbkdf2-sha256');
      expect(envelope['alg'], 'aes-256-gcm');
      expect(envelope['ciphertext'], isNotEmpty);

      final plain = await BackupService.decryptFileBytes(bytes, 's3cret');
      expect(plain, 'hello ledger');
    });

    test('wrong password fails to decrypt', () async {
      final bytes =
          await BackupService.encryptToFileBytes('secret data', 'right-pw');
      await expectLater(
        BackupService.decryptFileBytes(bytes, 'wrong-pw'),
        throwsA(anything),
      );
    });

    test('each backup uses a fresh salt and nonce', () async {
      final a = await BackupService.encryptToFileBytes('same', 'pw');
      final b = await BackupService.encryptToFileBytes('same', 'pw');
      expect(a, isNot(equals(b)));
    });
  });

  group('BackupService payload parsing', () {
    final payload = <String, dynamic>{
      'version': '1',
      'exportedAt': '2026-08-08T00:00:00.000',
      'accounts': [
        {
          'id': 'a1',
          'name': 'CBE',
          'type': 'bank',
          'isActive': true,
          'currency': 'ETB',
          'targetAmount': null,
        },
      ],
      'transactions': [
        {
          'id': 't1',
          'title': 'Coffee',
          'amount': 80.0,
          'type': 'expense',
          'accountId': 'a1',
          'category': 'food',
          'date': '2026-08-01T09:00:00.000',
          'note': null,
          'currency': 'ETB',
          'rateToBase': 1.0,
          'fee': 0.0,
          'tags': <String>[],
          'splits': <dynamic>[],
        },
      ],
      'transfers': <dynamic>[],
      'debts': <dynamic>[],
      'budgets': <dynamic>[],
      'recurring': <dynamic>[],
      'settings': {
        'baseCurrency': 'ETB',
        'titheRate': 0.1,
        'rates': <String, double>{},
      },
    };

    test('maps records and restores ISO dates to DateTimes', () {
      final data = BackupService.parsePayload(payload);
      expect(data.accounts.length, 1);
      expect(data.transactions.length, 1);
      expect(data.transactions.first.title, 'Coffee');
      expect(data.transactions.first.amount, 80.0);
      expect(data.transactions.first.date,
          DateTime.parse('2026-08-01T09:00:00.000'));
      expect(data.settings!.baseCurrency, 'ETB');
      expect(data.count, 2);
    });

    test('a note that looks like a date is left alone', () {
      final withDateNote = Map<String, dynamic>.from(payload);
      final tx = Map<String, dynamic>.from(
          (payload['transactions'] as List).first as Map<String, dynamic>)
        ..['note'] = '2026-08-01 is a date-looking note';
      withDateNote['transactions'] = [tx];
      final data = BackupService.parsePayload(withDateNote);
      expect(data.transactions.first.note, '2026-08-01 is a date-looking note');
    });
  });
}
