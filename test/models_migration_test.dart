import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/models/account_model.dart';
import 'package:mystic_ledger/models/app_settings.dart';
import 'package:mystic_ledger/models/currency_model.dart';
import 'package:mystic_ledger/models/transaction.dart';
import 'package:mystic_ledger/models/transfer_model.dart';

/// Documents written before multi-currency must keep parsing and must behave
/// exactly as they did before. These tests pin that contract.
void main() {
  final when = DateTime(2026, 3, 14);

  group('legacy documents (pre multi-currency)', () {
    test('Account defaults to the base currency and stays active', () {
      final a = Account.fromMap({
        'id': 'telebirr',
        'name': 'Telebirr',
        'type': 'mobile',
        'isActive': true,
      });

      expect(a.currency, Currency.defaultCode);
      expect(a.isActive, isTrue);
      expect(a.type, AccountType.mobile);
    });

    test('Account with no isActive field is treated as active', () {
      final a = Account.fromMap({'id': 'cash', 'name': 'Cash', 'type': 'cash'});
      expect(a.isActive, isTrue);
      expect(a.currency, Currency.defaultCode);
    });

    test('Transaction parses at parity with no fee', () {
      final t = Transaction.fromMap({
        'id': 't1',
        'title': 'Salary',
        'amount': 1200.50,
        'type': 'income',
        'accountId': 'cbe',
        'category': 'salary',
        'date': Timestamp.fromDate(when),
        'note': null,
      });

      expect(t.currency, Currency.defaultCode);
      expect(t.rateToBase, 1.0);
      expect(t.fee, 0.0);
      // The critical property: old amounts are unchanged by conversion.
      expect(t.amountInBase, 1200.50);
      expect(t.feeInBase, 0.0);
    });

    test('Transfer mirrors amount to toAmount and is not a reversal', () {
      final t = Transfer.fromMap({
        'id': 'x1',
        'fromAccountId': 'cash',
        'toAccountId': 'cbe',
        'amount': 500.0,
        'fee': 15.0,
        'date': Timestamp.fromDate(when),
        'note': 'rent',
      });

      expect(t.amount, 500.0);
      expect(t.toAmount, 500.0, reason: 'same-currency transfers mirror');
      expect(t.currency, Currency.defaultCode);
      expect(t.toCurrency, Currency.defaultCode);
      expect(t.rate, 1.0);
      expect(t.fee, 15.0);
      expect(t.category, isNull);
      expect(t.reversalOfId, isNull);
      expect(t.isReversal, isFalse);
      expect(t.isCrossCurrency, isFalse);
    });

    test('Transfer with no fee field defaults to zero', () {
      final t = Transfer.fromMap({
        'id': 'x2',
        'fromAccountId': 'cash',
        'toAccountId': 'savings',
        'amount': 100.0,
        'date': Timestamp.fromDate(when),
      });
      expect(t.fee, 0.0);
      expect(t.toAmount, 100.0);
    });
  });

  group('multi-currency round trip', () {
    test('cross-currency Transfer survives toMap/fromMap', () {
      final original = Transfer(
        id: 'x3',
        fromAccountId: 'usd_wallet',
        toAccountId: 'cbe',
        amount: 100.0,
        toAmount: 5720.0,
        fee: 2.0,
        currency: 'USD',
        toCurrency: 'ETB',
        rate: 57.20,
        rateToBase: 57.20,
        category: TransferCategory.familyFriends,
        date: when,
        note: 'remittance',
      );

      final round = Transfer.fromMap(original.toMap());

      expect(round.amount, 100.0);
      expect(round.toAmount, 5720.0);
      expect(round.currency, 'USD');
      expect(round.toCurrency, 'ETB');
      expect(round.rate, 57.20);
      expect(round.isCrossCurrency, isTrue);
      expect(round.category, TransferCategory.familyFriends);
      // 2 USD of fees, expressed in ETB.
      expect(round.feeInBase, closeTo(114.40, 0.001));
    });

    test('reversal keeps its back-reference', () {
      final reversal = Transfer(
        id: 'r1',
        fromAccountId: 'cbe',
        toAccountId: 'cash',
        amount: 500.0,
        date: when,
        reversalOfId: 'x1',
      );

      final round = Transfer.fromMap(reversal.toMap());
      expect(round.reversalOfId, 'x1');
      expect(round.isReversal, isTrue);
    });

    test('foreign Transaction converts to base via its rate snapshot', () {
      final t = Transaction(
        id: 't2',
        title: 'Consulting',
        amount: 200.0,
        type: TransactionType.income,
        accountId: 'usd_wallet',
        category: TransactionCategory.freelance,
        date: when,
        currency: 'USD',
        rateToBase: 57.20,
        fee: 5.0,
      );

      final round = Transaction.fromMap(t.toMap());
      expect(round.amountInBase, closeTo(11440.0, 0.001));
      expect(round.feeInBase, closeTo(286.0, 0.001));
    });
  });

  group('AppSettings', () {
    test('missing document yields sane defaults', () {
      const s = AppSettings();
      expect(s.baseCurrency, 'ETB');
      expect(s.titheRate, 0.10);
      expect(s.rates, isEmpty);
    });

    test('base currency is always parity, unknown codes fall back to 1.0', () {
      const s = AppSettings(baseCurrency: 'ETB', rates: {'USD': 57.20});
      expect(s.rateFor('ETB'), 1.0);
      expect(s.rateFor('USD'), 57.20);
      // A missing rate must not silently zero out a balance.
      expect(s.rateFor('JPY'), 1.0);
    });

    test('survives toMap/fromMap', () {
      const s = AppSettings(
        baseCurrency: 'USD',
        titheRate: 0.125,
        rates: {'ETB': 0.0175},
      );
      final round = AppSettings.fromMap(s.toMap());
      expect(round.baseCurrency, 'USD');
      expect(round.titheRate, 0.125);
      expect(round.rateFor('ETB'), 0.0175);
    });
  });
}
