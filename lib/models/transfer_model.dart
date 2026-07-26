import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'currency_model.dart';

/// What the transfer was *for*.
///
/// Note this is the purpose, not the destination — "Telebirr" and "CBE" are
/// modelled as accounts (the from/to selection), not as categories.
enum TransferCategory {
  supermarket,
  bills,
  familyFriends,
  business,
  savings,
  fees,
  other,
}

class Transfer {
  final String id;
  final String fromAccountId;
  final String toAccountId;

  /// Amount leaving the source account, in [currency].
  final double amount;

  /// Amount arriving in the destination account, in [toCurrency].
  /// Equal to [amount] for same-currency transfers.
  final double toAmount;

  /// Transfer fee debited from the source account, in [currency].
  final double fee;

  /// Currency of [amount] and [fee] — the source account's currency.
  final String currency;

  /// Currency of [toAmount] — the destination account's currency.
  final String toCurrency;

  /// Conversion applied: 1 unit of [currency] == [rate] units of [toCurrency].
  /// 1.0 for same-currency transfers.
  final double rate;

  /// Value of 1 unit of [currency] in the base currency at the time of record,
  /// used for fee reporting so history does not shift with rate updates.
  final double rateToBase;

  final TransferCategory? category;
  final DateTime date;
  final String? note;

  /// Set on a reversing transfer: the id of the transfer it undoes.
  /// Null on ordinary transfers.
  final String? reversalOfId;

  const Transfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    double? toAmount,
    this.fee = 0.0,
    this.currency   = Currency.defaultCode,
    String? toCurrency,
    this.rate       = 1.0,
    this.rateToBase = 1.0,
    this.category,
    required this.date,
    this.note,
    this.reversalOfId,
  })  : toAmount   = toAmount   ?? amount,
        toCurrency = toCurrency ?? currency;

  /// True when the two sides use different currencies.
  bool get isCrossCurrency => currency != toCurrency;

  /// True when this record exists only to undo another transfer.
  bool get isReversal => reversalOfId != null;

  /// [fee] expressed in the base currency.
  double get feeInBase => fee * rateToBase;

  Map<String, dynamic> toMap() => {
        'id':            id,
        'fromAccountId': fromAccountId,
        'toAccountId':   toAccountId,
        'amount':        amount,
        'toAmount':      toAmount,
        'fee':           fee,
        'currency':      currency,
        'toCurrency':    toCurrency,
        'rate':          rate,
        'rateToBase':    rateToBase,
        'category':      category?.name,
        'date':          Timestamp.fromDate(date),
        'note':          note,
        'reversalOfId':  reversalOfId,
      };

  factory Transfer.fromMap(Map<String, dynamic> m) {
    final amount = (m['amount'] as num).toDouble();
    // Pre-multi-currency documents: single ETB amount, no conversion, no
    // category, never reversed.
    final currency = m['currency'] as String? ?? Currency.defaultCode;
    return Transfer(
      id:            m['id']            as String,
      fromAccountId: m['fromAccountId'] as String,
      toAccountId:   m['toAccountId']   as String,
      amount:        amount,
      toAmount:      (m['toAmount'] as num?)?.toDouble() ?? amount,
      fee:           (m['fee'] as num?)?.toDouble() ?? 0.0,
      currency:      currency,
      toCurrency:    m['toCurrency'] as String? ?? currency,
      rate:          (m['rate'] as num?)?.toDouble() ?? 1.0,
      rateToBase:    (m['rateToBase'] as num?)?.toDouble() ?? 1.0,
      category: m['category'] == null
          ? null
          : TransferCategory.values.firstWhere(
              (e) => e.name == m['category'],
              orElse: () => TransferCategory.other,
            ),
      date:         (m['date'] as Timestamp).toDate(),
      note:          m['note'] as String?,
      reversalOfId:  m['reversalOfId'] as String?,
    );
  }

  Transfer copyWith({
    String? note,
    TransferCategory? category,
  }) =>
      Transfer(
        id:            id,
        fromAccountId: fromAccountId,
        toAccountId:   toAccountId,
        amount:        amount,
        toAmount:      toAmount,
        fee:           fee,
        currency:      currency,
        toCurrency:    toCurrency,
        rate:          rate,
        rateToBase:    rateToBase,
        category:      category ?? this.category,
        date:          date,
        note:          note ?? this.note,
        reversalOfId:  reversalOfId,
      );
}

// ── Display helpers ──────────────────────────────────────────────────────────

extension TransferCategoryDisplay on TransferCategory {
  String get label {
    switch (this) {
      case TransferCategory.supermarket:   return 'Supermarket';
      case TransferCategory.bills:         return 'Bills & Utilities';
      case TransferCategory.familyFriends: return 'Family & Friends';
      case TransferCategory.business:      return 'Business';
      case TransferCategory.savings:       return 'Savings';
      case TransferCategory.fees:          return 'Fees & Charges';
      case TransferCategory.other:         return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case TransferCategory.supermarket:   return Icons.shopping_cart_outlined;
      case TransferCategory.bills:         return Icons.receipt_long_outlined;
      case TransferCategory.familyFriends: return Icons.people_outline;
      case TransferCategory.business:      return Icons.storefront_outlined;
      case TransferCategory.savings:       return Icons.savings_outlined;
      case TransferCategory.fees:          return Icons.percent_outlined;
      case TransferCategory.other:         return Icons.swap_horiz_outlined;
    }
  }
}
