import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'currency_model.dart';

enum TransactionType { income, expense }

/// Which rate an entry should carry after an edit.
///
/// [Transaction.rateToBase] is snapshotted at write time precisely so that
/// updating the rate table later does not rewrite past months' reports. An edit
/// must therefore *keep* the original snapshot — re-reading the live rate to
/// fix a typo in a title would silently restate the figures for whatever month
/// the entry falls in.
///
/// The one exception is a change of currency: the old snapshot describes a
/// different currency and means nothing for the new one, so it has to be
/// re-taken.
double resolveRateToBase({
  Transaction? existing,
  required String currency,
  required double liveRate,
}) =>
    (existing != null && existing.currency == currency)
        ? existing.rateToBase
        : liveRate;

enum TransactionCategory {
  food, transport, utilities, entertainment,
  tithe, salary, freelance, other,
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String accountId;
  final TransactionCategory category;
  final DateTime date;
  final String? note;

  /// Currency of [amount] and [fee] — always the holding account's currency.
  final String currency;

  /// Value of 1 unit of [currency] in the base currency, snapshotted when the
  /// entry was recorded. Reports use this rather than the live rate so history
  /// does not shift when the user updates their rate table.
  final double rateToBase;

  /// Bank/service charge paid on top of [amount]. Leaves the account with the
  /// amount, so it reduces the balance further.
  final double fee;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.accountId,
    required this.category,
    required this.date,
    this.note,
    this.currency   = Currency.defaultCode,
    this.rateToBase = 1.0,
    this.fee        = 0.0,
  });

  /// [amount] expressed in the base currency.
  double get amountInBase => amount * rateToBase;

  /// [fee] expressed in the base currency.
  double get feeInBase => fee * rateToBase;

  // ── Firestore serialisation ──────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id':         id,
        'title':      title,
        'amount':     amount,
        'type':       type.name,
        'accountId':  accountId,
        'category':   category.name,
        'date':       Timestamp.fromDate(date),
        'note':       note,
        'currency':   currency,
        'rateToBase': rateToBase,
        'fee':        fee,
      };

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
        id:        m['id']        as String,
        title:     m['title']     as String,
        amount:    (m['amount'] as num).toDouble(),
        type:      TransactionType.values.firstWhere(
            (e) => e.name == m['type'], orElse: () => TransactionType.expense),
        accountId: m['accountId'] as String,
        category:  TransactionCategory.values.firstWhere(
            (e) => e.name == m['category'], orElse: () => TransactionCategory.other),
        date: (m['date'] as Timestamp).toDate(),
        note: m['note'] as String?,
        // Pre-multi-currency documents are ETB at parity with no fee.
        currency:   m['currency'] as String? ?? Currency.defaultCode,
        rateToBase: (m['rateToBase'] as num?)?.toDouble() ?? 1.0,
        fee:        (m['fee'] as num?)?.toDouble() ?? 0.0,
      );

  // ── Display helpers ──────────────────────────────────────────────────────

  String get categoryLabel {
    switch (category) {
      case TransactionCategory.food:          return 'Sustenance';
      case TransactionCategory.transport:     return 'Carriage';
      case TransactionCategory.utilities:     return 'The Hearth';
      case TransactionCategory.entertainment: return 'Vices & Joy';
      case TransactionCategory.tithe:         return 'Tithe';
      case TransactionCategory.salary:        return 'Salary';
      case TransactionCategory.freelance:     return 'Grimoire Sales';
      case TransactionCategory.other:         return 'Miscellany';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case TransactionCategory.food:          return Icons.restaurant_outlined;
      case TransactionCategory.transport:     return Icons.directions_car_outlined;
      case TransactionCategory.utilities:     return Icons.home_outlined;
      case TransactionCategory.entertainment: return Icons.celebration_outlined;
      case TransactionCategory.tithe:         return Icons.volunteer_activism_outlined;
      case TransactionCategory.salary:        return Icons.work_outline;
      case TransactionCategory.freelance:     return Icons.auto_stories_outlined;
      case TransactionCategory.other:         return Icons.category_outlined;
    }
  }
}
