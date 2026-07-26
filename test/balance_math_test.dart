import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/models/transaction.dart';
import 'package:mystic_ledger/models/transfer_model.dart';
import 'package:mystic_ledger/services/finance_service.dart';

/// The arithmetic that decides how much money the user has. A wrong sign here
/// is silent and corrupting, so every rule is pinned.
void main() {
  final day = DateTime(2026, 7, 1);
  var seq = 0;
  String nextId() => 'id${seq++}';

  Transaction income(String account, double amount) => Transaction(
        id: nextId(),
        title: 'in',
        amount: amount,
        type: TransactionType.income,
        accountId: account,
        category: TransactionCategory.salary,
        date: day,
      );

  Transaction expense(String account, double amount, {double fee = 0}) =>
      Transaction(
        id: nextId(),
        title: 'out',
        amount: amount,
        type: TransactionType.expense,
        accountId: account,
        category: TransactionCategory.food,
        date: day,
        fee: fee,
      );

  Transfer move(
    String from,
    String to,
    double amount, {
    double? toAmount,
    double fee = 0,
    String currency = 'ETB',
    String? toCurrency,
    double rate = 1.0,
    String? reversalOfId,
    String? id,
  }) =>
      Transfer(
        id: id ?? nextId(),
        fromAccountId: from,
        toAccountId: to,
        amount: amount,
        toAmount: toAmount,
        fee: fee,
        currency: currency,
        toCurrency: toCurrency,
        rate: rate,
        date: day,
        reversalOfId: reversalOfId,
      );

  group('transactions', () {
    test('income adds, expense subtracts', () {
      final txs = [income('cash', 1000), expense('cash', 250)];
      expect(computeAccountBalance('cash', txs, const []), 750);
    });

    test('an expense fee comes out of the account too', () {
      final txs = [income('cash', 1000), expense('cash', 250, fee: 15)];
      expect(computeAccountBalance('cash', txs, const []), 735);
    });

    test('other accounts are unaffected', () {
      final txs = [income('cash', 1000), expense('cbe', 400)];
      expect(computeAccountBalance('cash', txs, const []), 1000);
      expect(computeAccountBalance('cbe', txs, const []), -400);
    });
  });

  group('transfers', () {
    test('same-currency transfer moves the full amount', () {
      final txs = [income('cash', 1000)];
      final moves = [move('cash', 'cbe', 300)];
      expect(computeAccountBalance('cash', txs, moves), 700);
      expect(computeAccountBalance('cbe', txs, moves), 300);
    });

    test('the fee is paid by the sender only', () {
      final txs = [income('cash', 1000)];
      final moves = [move('cash', 'cbe', 300, fee: 20)];
      // Sender loses amount + fee; receiver still gets the full amount.
      expect(computeAccountBalance('cash', txs, moves), 680);
      expect(computeAccountBalance('cbe', txs, moves), 300);
    });

    test('cross-currency transfer credits the converted amount', () {
      // 100 USD leaves the wallet, 5,720 ETB arrives at the bank.
      final txs = [income('usd', 500)];
      final moves = [
        move('usd', 'cbe', 100,
            toAmount: 5720, currency: 'USD', toCurrency: 'ETB', rate: 57.20),
      ];
      expect(computeAccountBalance('usd', txs, moves), 400,
          reason: 'source is debited in its own currency');
      expect(computeAccountBalance('cbe', txs, moves), 5720,
          reason: 'destination is credited in its own currency');
    });
  });

  group('reversal', () {
    test('reversing restores both balances exactly', () {
      final txs = [income('cash', 1000)];
      final original = move('cash', 'cbe', 300, id: 'orig');

      final before = computeAccountBalance('cash', txs, const []);
      expect(computeAccountBalance('cash', txs, [original]), 700);

      // The reversal sends back what arrived.
      final reversal =
          move('cbe', 'cash', 300, reversalOfId: 'orig');
      final after = computeAccountBalance('cash', txs, [original, reversal]);

      expect(after, before, reason: 'sender is made whole');
      expect(computeAccountBalance('cbe', txs, [original, reversal]), 0);
    });

    test('by default the fee is not refunded', () {
      final txs = [income('cash', 1000)];
      final original = move('cash', 'cbe', 300, fee: 20, id: 'orig');
      // Reversal returns the 300 that arrived, not the 20 the bank took.
      final reversal = move('cbe', 'cash', 300, reversalOfId: 'orig');

      expect(computeAccountBalance('cash', txs, [original, reversal]), 980,
          reason: 'the 20 fee stays lost');
      expect(computeAccountBalance('cbe', txs, [original, reversal]), 0);
    });

    test('refunding the fee makes the sender fully whole', () {
      final txs = [income('cash', 1000)];
      final original = move('cash', 'cbe', 300, fee: 20, id: 'orig');
      // refundFee: destination sends back amount + fee.
      final reversal =
          move('cbe', 'cash', 300, toAmount: 320, reversalOfId: 'orig');

      expect(computeAccountBalance('cash', txs, [original, reversal]), 1000);
    });

    test('reversing a cross-currency transfer returns the original amount', () {
      final txs = [income('usd', 500)];
      final original = move('usd', 'cbe', 100,
          toAmount: 5720,
          currency: 'USD',
          toCurrency: 'ETB',
          rate: 57.20,
          id: 'orig');
      // Reversal sends the 5,720 ETB back and restores the 100 USD.
      final reversal = move('cbe', 'usd', 5720,
          toAmount: 100,
          currency: 'ETB',
          toCurrency: 'USD',
          rate: 1 / 57.20,
          reversalOfId: 'orig');

      expect(computeAccountBalance('usd', txs, [original, reversal]), 500);
      expect(computeAccountBalance('cbe', txs, [original, reversal]), 0);
    });
  });

  group('edge cases', () {
    test('an account with no activity is zero, not an error', () {
      expect(computeAccountBalance('ghost', const [], const []), 0);
    });

    test('balance can go negative', () {
      expect(
          computeAccountBalance('cash', [expense('cash', 50)], const []), -50);
    });
  });
}
