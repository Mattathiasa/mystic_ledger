import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/models/transaction.dart';

/// Every entry stores the rate that applied when it was written, so updating
/// the rate table later cannot restate past months. Editing an entry has to
/// respect that — which is easy to lose in a refactor, because "just read the
/// current rate" looks like a simplification.
void main() {
  Transaction entry({
    required String currency,
    required double rateToBase,
  }) =>
      Transaction(
        id: 'e1',
        title: 'Salary',
        amount: 100,
        type: TransactionType.income,
        accountId: 'a1',
        category: TransactionCategory.salary,
        date: DateTime(2026, 6, 15),
        currency: currency,
        rateToBase: rateToBase,
      );

  test('a new entry takes the live rate', () {
    expect(
      resolveRateToBase(existing: null, currency: 'USD', liveRate: 130.0),
      130.0,
    );
  });

  test('editing without changing currency keeps the original snapshot', () {
    // The rate has since moved 120 → 130. Fixing a typo in the title must not
    // restate what June was worth.
    final june = entry(currency: 'USD', rateToBase: 120.0);
    expect(
      resolveRateToBase(existing: june, currency: 'USD', liveRate: 130.0),
      120.0,
    );
  });

  test('changing currency re-snapshots, since the old rate described another '
      'currency', () {
    final june = entry(currency: 'USD', rateToBase: 120.0);
    expect(
      resolveRateToBase(existing: june, currency: 'EUR', liveRate: 145.0),
      145.0,
    );
  });

  test('moving to the base currency takes its live rate, not the old one', () {
    final june = entry(currency: 'USD', rateToBase: 120.0);
    expect(
      resolveRateToBase(existing: june, currency: 'ETB', liveRate: 1.0),
      1.0,
    );
  });

  test('an unchanged snapshot survives repeated edits', () {
    // Three edits in a row must not compound: the snapshot is the original's,
    // every time, not the previous edit's live rate.
    var e = entry(currency: 'USD', rateToBase: 120.0);
    for (final live in [125.0, 131.0, 118.0]) {
      final r = resolveRateToBase(
          existing: e, currency: 'USD', liveRate: live);
      expect(r, 120.0);
      e = entry(currency: 'USD', rateToBase: r);
    }
  });
}
