import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/models/budget_model.dart';
import 'package:mystic_ledger/models/transaction.dart';
import 'package:mystic_ledger/services/finance_service.dart';

/// Pins the budget spend arithmetic and the trend-chart bucketing. Both were
/// refactored into pure functions precisely so they can be tested without a
/// Firestore-backed service; these tests keep them honest.
void main() {
  var seq = 0;
  String nextId() => 'id${seq++}';

  Transaction expense({
    required double amount,
    required DateTime date,
    TransactionCategory category = TransactionCategory.food,
    double fee = 0,
  }) =>
      Transaction(
        id: nextId(),
        title: 'out',
        amount: amount,
        type: TransactionType.expense,
        accountId: 'cash',
        category: category,
        date: date,
        fee: fee,
      );

  Transaction income({
    required double amount,
    required DateTime date,
  }) =>
      Transaction(
        id: nextId(),
        title: 'in',
        amount: amount,
        type: TransactionType.income,
        accountId: 'cash',
        category: TransactionCategory.salary,
        date: date,
      );

  Budget budget({
    BudgetPeriod period = BudgetPeriod.monthly,
    TransactionCategory? category,
    double amount = 1000,
  }) =>
      Budget(
        id: 'b1',
        period: period,
        amount: amount,
        category: category,
      );

  group('computeSpentAgainstBudget', () {
    final july   = DateTime(2026, 7, 15);
    final june   = DateTime(2026, 6, 15);
    final august = DateTime(2026, 8, 1);

    test('counts expense amounts only, in the window', () {
      final txs = [
        expense(amount: 300, date: july),
        expense(amount: 200, date: june),
        income(amount: 5000, date: july),
      ];
      expect(
        computeSpentAgainstBudget(txs, budget(),
            from: DateTime(2026, 7, 1), to: DateTime(2026, 8, 1)),
        300,
      );
    });

    test('fees ride along with the entry they belong to', () {
      final txs = [expense(amount: 250, date: july, fee: 15)];
      expect(
        computeSpentAgainstBudget(txs, budget(),
            from: DateTime(2026, 7, 1), to: DateTime(2026, 8, 1)),
        265,
      );
    });

    test('an income-category budget sees nothing', () {
      final txs = [expense(amount: 300, date: july)];
      expect(
        computeSpentAgainstBudget(txs, budget(category: TransactionCategory.salary),
            from: DateTime(2026, 7, 1), to: DateTime(2026, 8, 1)),
        0,
      );
    });

    test('null bounds mean unbounded', () {
      final txs = [expense(amount: 100, date: june), expense(amount: 200, date: august)];
      expect(computeSpentAgainstBudget(txs, budget()), 300);
    });

    test('the upper bound is exclusive', () {
      final txs = [
        expense(amount: 100, date: DateTime(2026, 7, 31, 23, 59)),
        expense(amount: 50, date: DateTime(2026, 8, 1)),
      ];
      expect(
        computeSpentAgainstBudget(txs, budget(),
            from: DateTime(2026, 7, 1), to: DateTime(2026, 8, 1)),
        100,
      );
    });
  });

  group('computeTrendFor', () {
    // A fixed Wednesday so week bucketing is deterministic.
    final wed = DateTime(2026, 7, 15);
    const zero = 0.0;
    double always0(DateTime a, DateTime b) => 0;
    double countDays(DateTime a, DateTime b) =>
        b.difference(a).inDays.toDouble();

    test('week yields seven day buckets labelled M–S', () {
      final buckets = computeTrendFor(
          LedgerPeriod.week, wed, countDays, always0, always0);
      expect(buckets.length, 7);
      expect(buckets.map((b) => b.label).toList(),
          ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
      expect(buckets.first.start.weekday, DateTime.monday);
    });

    test('month yields whole-week buckets covering the month exactly', () {
      final buckets = computeTrendFor(
          LedgerPeriod.month, wed, countDays, always0, always0);
      expect(buckets.first.start, DateTime(2026, 7, 1),
          reason: 'bucketing starts on the first of the month');
      // Consecutive buckets tile the month: each starts where the last ended,
      // and the final bucket ends exactly at the first of the next month.
      for (var i = 1; i < buckets.length; i++) {
        final prevEnd =
            buckets[i - 1].start.add(const Duration(days: 7));
        expect(buckets[i].start, prevEnd,
            reason: 'buckets must not overlap or leave gaps');
      }
      expect(buckets.map((b) => b.label).toList().first, 'W1');
    });

    test('six months yields six month buckets, oldest first', () {
      final buckets = computeTrendFor(
          LedgerPeriod.sixMonths, wed, countDays, always0, always0);
      expect(buckets.length, 6);
      expect(buckets.first.label, 'Feb'); // July − 5 months
      expect(buckets.last.label, 'Jul');
    });

    test('a year yields twelve trailing months, oldest first', () {
      // The year view shows the last 12 months ending in the current one
      // (so on 15 Jul 2026 the window is Aug 2025 … Jul 2026).
      final buckets = computeTrendFor(
          LedgerPeriod.year, wed, countDays, always0, always0);
      expect(buckets.length, 12);
      expect(buckets.first.label, 'Aug'); // 12 months before July
      expect(buckets.last.label, 'Jul');
      expect(buckets.last.start.month, 7);
    });

    test('aggregators are called per bucket with their exact window', () {
      final calls = <(DateTime, DateTime)>[];
      double spy(DateTime a, DateTime b) {
        calls.add((a, b));
        return zero;
      }

      // Three aggregators (income/expenses/fees), each called once per bucket.
      computeTrendFor(LedgerPeriod.week, wed, spy, spy, spy);
      expect(calls.length, 7 * 3,
          reason: 'one call per bucket per aggregator');
      expect(calls.first.$2.difference(calls.first.$1).inDays, 1,
          reason: 'day-sized buckets');
    });

    test('income is routed to the bucket that contains it', () {
      // The Wednesday mid-month: income lands only in the W3 bucket.
      final buckets = computeTrendFor(
        LedgerPeriod.month,
        wed,
        (a, b) =>
            (a.isBefore(wed) && !b.isBefore(wed)) ? 500 : 0,
        always0,
        always0,
      );
      final withIncome = buckets.where((b) => b.income > 0).toList();
      expect(withIncome.length, 1, reason: 'one bucket owns the Wednesday');
    });
  });

  group('computeTrendBetween', () {
    test('spans whole months from from to to', () {
      final buckets = computeTrendBetween(
        DateTime(2026, 4, 10),
        DateTime(2026, 7, 20),
        (a, b) => 0,
        (a, b) => 0,
        (a, b) => 0,
      );
      expect(buckets.length, 4);
      expect(buckets.first.start, DateTime(2026, 4, 1));
      expect(buckets.map((b) => b.label).toList(),
          ['Apr', 'May', 'Jun', 'Jul']);
    });

    test('aggregates income within each bucket only', () {
      double income(DateTime a, DateTime b) =>
          a.month == 6 ? 100 : 0;
      final buckets = computeTrendBetween(
        DateTime(2026, 6, 1),
        DateTime(2026, 8, 1),
        income,
        (a, b) => 0,
        (a, b) => 0,
      );
      expect(buckets.first.income, 100);
      expect(buckets.last.income, 0);
    });
  });
}
