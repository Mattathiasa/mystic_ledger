import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/models/transaction.dart';
import 'package:mystic_ledger/services/finance_service.dart';

/// The old calculation was `totalIncome * 0.1` with no subtraction of what had
/// already been given, and a progress ring hardcoded to "Done". These tests pin
/// the corrected behaviour.
void main() {
  var seq = 0;
  Transaction tx({
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    required DateTime date,
    double rateToBase = 1.0,
  }) =>
      Transaction(
        id: 'id${seq++}',
        title: 't',
        amount: amount,
        type: type,
        accountId: 'cash',
        category: category,
        date: date,
        rateToBase: rateToBase,
      );

  group('TitheStatus', () {
    test('obligation is income times the rate', () {
      final s = TitheStatus.of(income: 24000, given: 0, rate: 0.10);
      expect(s.obligation, 2400);
      expect(s.remaining, 2400);
      expect(s.progress, 0.0);
    });

    test('giving reduces what is still owed', () {
      final s = TitheStatus.of(income: 24000, given: 1000, rate: 0.10);
      expect(s.obligation, 2400);
      expect(s.given, 1000);
      expect(s.remaining, 1400);
      expect(s.progress, closeTo(0.4166, 0.001));
    });

    test('giving the full amount settles it', () {
      final s = TitheStatus.of(income: 24000, given: 2400, rate: 0.10);
      expect(s.remaining, 0);
      expect(s.progress, 1.0);
    });

    test('giving extra never produces a negative balance or >100%', () {
      final s = TitheStatus.of(income: 24000, given: 5000, rate: 0.10);
      expect(s.remaining, 0, reason: 'no negative "owed"');
      expect(s.progress, 1.0, reason: 'progress is clamped');
    });

    test('no income means nothing owed, shown as fulfilled', () {
      final s = TitheStatus.of(income: 0, given: 0, rate: 0.10);
      expect(s.obligation, 0);
      expect(s.remaining, 0);
      expect(s.progress, 1.0,
          reason: 'an empty period should not read as 0% done');
    });

    test('negative income does not create a negative obligation', () {
      final s = TitheStatus.of(income: -500, given: 0, rate: 0.10);
      expect(s.obligation, 0);
      expect(s.remaining, 0);
    });

    test('the rate is configurable, not fixed at 10%', () {
      expect(TitheStatus.of(income: 1000, given: 0, rate: 0.125).obligation,
          125);
      expect(TitheStatus.of(income: 1000, given: 0, rate: 0.0).obligation, 0);
    });
  });

  group('computeTitheGiven', () {
    final july = DateTime(2026, 7, 10);
    final june = DateTime(2026, 6, 10);

    test('counts only tithe-categorised expenses', () {
      final txs = [
        tx(
            amount: 500,
            type: TransactionType.expense,
            category: TransactionCategory.tithe,
            date: july),
        tx(
            amount: 900,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: july),
      ];
      expect(computeTitheGiven(txs), 500);
    });

    test('ignores income even if categorised as tithe', () {
      final txs = [
        tx(
            amount: 700,
            type: TransactionType.income,
            category: TransactionCategory.tithe,
            date: july),
      ];
      expect(computeTitheGiven(txs), 0);
    });

    test('respects the period boundary', () {
      final txs = [
        tx(
            amount: 300,
            type: TransactionType.expense,
            category: TransactionCategory.tithe,
            date: june),
        tx(
            amount: 400,
            type: TransactionType.expense,
            category: TransactionCategory.tithe,
            date: july),
      ];
      expect(computeTitheGiven(txs, from: DateTime(2026, 7, 1)), 400,
          reason: 'June giving does not count toward July');
      expect(computeTitheGiven(txs), 700, reason: 'all-time counts both');
    });

    test('foreign-currency giving converts via its rate snapshot', () {
      final txs = [
        tx(
            amount: 10,
            type: TransactionType.expense,
            category: TransactionCategory.tithe,
            date: july,
            rateToBase: 57.20),
      ];
      expect(computeTitheGiven(txs), closeTo(572.0, 0.001));
    });
  });
}
