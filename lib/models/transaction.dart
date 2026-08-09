import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/l10n.dart';
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
  health, education, rent, clothing,
  business, taxes, insurance, subscriptions,
}

/// Display names and icons shared by every screen that renders a category.
///
/// The ledger filter, budget picker, insights drill-down and entry form all
/// read from here so a category label never drifts between screens.
extension TransactionCategoryDisplay on TransactionCategory {
  /// Plain label — used in chips, filters, and pickers.
  String get label {
    switch (this) {
      case TransactionCategory.food:          return L10n.t('Food');
      case TransactionCategory.transport:     return L10n.t('Transport');
      case TransactionCategory.utilities:     return L10n.t('Utilities');
      case TransactionCategory.entertainment: return L10n.t('Entertainment');
      case TransactionCategory.tithe:         return L10n.t('Tithe');
      case TransactionCategory.salary:        return L10n.t('Salary');
      case TransactionCategory.freelance:     return L10n.t('Freelance');
      case TransactionCategory.other:         return L10n.t('Other');
      case TransactionCategory.health:        return L10n.t('Health');
      case TransactionCategory.education:     return L10n.t('Education');
      case TransactionCategory.rent:          return L10n.t('Rent & Housing');
      case TransactionCategory.clothing:      return L10n.t('Clothing & Shopping');
      case TransactionCategory.business:      return L10n.t('Business');
      case TransactionCategory.taxes:         return L10n.t('Taxes');
      case TransactionCategory.insurance:     return L10n.t('Insurance');
      case TransactionCategory.subscriptions: return L10n.t('Subscriptions');
    }
  }

  /// Mystic-flavoured label — used in the entry form and transaction tiles.
  String get mystiqueLabel {
    switch (this) {
      case TransactionCategory.food:          return L10n.t('Sustenance');
      case TransactionCategory.transport:     return L10n.t('Carriage');
      case TransactionCategory.utilities:     return L10n.t('The Hearth');
      case TransactionCategory.entertainment: return L10n.t('Vices & Joy');
      case TransactionCategory.tithe:         return L10n.t('Tithe');
      case TransactionCategory.salary:        return L10n.t('Salary');
      case TransactionCategory.freelance:     return L10n.t('Grimoire Sales');
      case TransactionCategory.other:         return L10n.t('Miscellany');
      case TransactionCategory.health:        return L10n.t('The Leech');
      case TransactionCategory.education:     return L10n.t('The Scriptorium');
      case TransactionCategory.rent:          return L10n.t('The Hearthstone');
      case TransactionCategory.clothing:      return L10n.t('The Wardrobe');
      case TransactionCategory.business:      return L10n.t('The Merchant Guild');
      case TransactionCategory.taxes:         return L10n.t("The Crown's Due");
      case TransactionCategory.insurance:     return L10n.t('The Shield');
      case TransactionCategory.subscriptions: return L10n.t('The Standing Dues');
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionCategory.food:          return Icons.restaurant_outlined;
      case TransactionCategory.transport:     return Icons.directions_car_outlined;
      case TransactionCategory.utilities:     return Icons.home_outlined;
      case TransactionCategory.entertainment: return Icons.celebration_outlined;
      case TransactionCategory.tithe:         return Icons.volunteer_activism_outlined;
      case TransactionCategory.salary:        return Icons.work_outline;
      case TransactionCategory.freelance:     return Icons.auto_stories_outlined;
      case TransactionCategory.other:         return Icons.category_outlined;
      case TransactionCategory.health:        return Icons.local_hospital_outlined;
      case TransactionCategory.education:     return Icons.school_outlined;
      case TransactionCategory.rent:          return Icons.home_work_outlined;
      case TransactionCategory.clothing:      return Icons.checkroom_outlined;
      case TransactionCategory.business:      return Icons.storefront_outlined;
      case TransactionCategory.taxes:         return Icons.receipt_long_outlined;
      case TransactionCategory.insurance:     return Icons.shield_outlined;
      case TransactionCategory.subscriptions: return Icons.subscriptions_outlined;
    }
  }
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

  /// Free-form cross-cutting labels (#vacation2026, #reimbursable, …). Filtered
  /// and searchable in the ledger. Kept lowercase, trimmed, de-duplicated.
  final List<String> tags;

  /// Multi-category line items for a single payment (e.g. one supermarket
  /// bill split into Food + Household). When non-empty their amounts sum to
  /// [amount]; reports allocate the entry across these categories instead of
  /// [category].
  final List<TransactionSplit> splits;

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
    this.tags       = const [],
    this.splits     = const [],
  });

  /// [amount] expressed in the base currency.
  double get amountInBase => amount * rateToBase;

  /// [fee] expressed in the base currency.
  double get feeInBase => fee * rateToBase;

  /// True when this entry carries split line items.
  bool get isSplit => splits.isNotEmpty;

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
        'tags':       tags,
        'splits':     splits.map((s) => s.toMap()).toList(),
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
        // Older documents predate tags and splits.
        tags:       (m['tags'] as List?)?.cast<String>() ?? const [],
        splits:     (m['splits'] as List?)
                ?.map((e) => TransactionSplit.fromMap(
                    (e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
      );

  // ── Display helpers ──────────────────────────────────────────────────────

  String get categoryLabel => category.mystiqueLabel;

  IconData get categoryIcon => category.icon;
}

/// One line of a split transaction — a category share of the total payment.
class TransactionSplit {
  final TransactionCategory category;
  final double amount;
  final String? note;

  const TransactionSplit({
    required this.category,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'category': category.name,
        'amount':   amount,
        'note':     note,
      };

  factory TransactionSplit.fromMap(Map<String, dynamic> m) => TransactionSplit(
        category: TransactionCategory.values.firstWhere(
            (e) => e.name == m['category'],
            orElse: () => TransactionCategory.other),
        amount: (m['amount'] as num).toDouble(),
        note:   m['note'] as String?,
      );
}
