import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/models/account_model.dart';
import 'package:mystic_ledger/services/finance_service.dart';

/// Savings is the one aggregate that can span currencies, so it is the one
/// place a naive sum would quietly report a wrong total. `converted` is what
/// keeps the UI from presenting an estimate as an exact figure.
void main() {
  Account vault(String id, String currency) => Account(
        id: id,
        name: id,
        type: AccountType.savings,
        currency: currency,
      );

  // 1 unit of the code in ETB. USD is deliberately far from parity so a
  // missing conversion shows up as a wildly wrong number rather than a
  // rounding difference.
  const rates = {'ETB': 1.0, 'USD': 130.0};
  double rateFor(String code) => rates[code] ?? 1.0;

  SavingsSummary summaryOf(
    List<Account> vaults,
    Map<String, double> balances, {
    String base = 'ETB',
  }) =>
      computeSavingsSummary(
        vaults,
        (id) => balances[id] ?? 0.0,
        rateFor,
        base,
      );

  group('no vaults', () {
    test('is empty and reports zero in the base currency', () {
      final s = summaryOf([], {});
      expect(s.isEmpty, isTrue);
      expect(s.amount, 0.0);
      expect(s.currency, 'ETB');
      expect(s.converted, isFalse);
    });
  });

  group('single currency', () {
    test('one vault keeps its own currency and exact balance', () {
      final s = summaryOf([vault('v1', 'ETB')], {'v1': 1500.0});
      expect(s.amount, 1500.0);
      expect(s.currency, 'ETB');
      expect(s.converted, isFalse);
      expect(s.accounts.length, 1);
    });

    test('two vaults in the same currency add natively, no conversion', () {
      final s = summaryOf(
        [vault('v1', 'ETB'), vault('v2', 'ETB')],
        {'v1': 1500.0, 'v2': 500.0},
      );
      expect(s.amount, 2000.0);
      expect(s.currency, 'ETB');
      expect(s.converted, isFalse);
    });

    test('a foreign currency shared by every vault is not converted', () {
      // All-USD vaults with an ETB base: the total is still exact in USD, so
      // converting it would lose precision for no reason.
      final s = summaryOf(
        [vault('v1', 'USD'), vault('v2', 'USD')],
        {'v1': 10.0, 'v2': 5.0},
      );
      expect(s.amount, 15.0);
      expect(s.currency, 'USD');
      expect(s.converted, isFalse);
    });
  });

  group('mixed currencies', () {
    test('converts to base and flags the result as converted', () {
      final s = summaryOf(
        [vault('etb', 'ETB'), vault('usd', 'USD')],
        {'etb': 1000.0, 'usd': 10.0},
      );
      expect(s.amount, 1000.0 + 10.0 * 130.0);
      expect(s.currency, 'ETB');
      expect(s.converted, isTrue);
    });

    test('a currency with no rate falls back to parity, still flagged', () {
      // AppSettings.rateFor returns 1.0 for unknown codes so a missing rate
      // never zeroes a balance. The figure is then wrong-ish but present, and
      // `converted` still warns the user it is an estimate.
      final s = summaryOf(
        [vault('etb', 'ETB'), vault('kes', 'KES')],
        {'etb': 100.0, 'kes': 50.0},
      );
      expect(s.amount, 150.0);
      expect(s.converted, isTrue);
    });
  });

  test('inactive vaults are the caller\'s concern, not this function\'s', () {
    // computeSavingsSummary totals whatever it is handed; the isActive filter
    // lives in FinanceService.savingsAccounts. Pinned so the responsibility
    // does not quietly move and end up applied twice or not at all.
    final s = summaryOf([vault('v1', 'ETB')], {'v1': 42.0});
    expect(s.accounts.single.id, 'v1');
    expect(s.amount, 42.0);
  });
}
