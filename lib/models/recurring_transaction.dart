import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction.dart';
import 'currency_model.dart';

/// How often a recurring entry repeats.
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

extension RecurrenceFrequencyDisplay on RecurrenceFrequency {
  String get label => switch (this) {
        RecurrenceFrequency.daily   => 'Daily',
        RecurrenceFrequency.weekly  => 'Weekly',
        RecurrenceFrequency.monthly => 'Monthly',
        RecurrenceFrequency.yearly  => 'Yearly',
      };
}

/// A transaction that repeats on a schedule — salary, rent, subscriptions.
///
/// Stored in Firestore (`users/{uid}/recurring`). On app resume, any active
/// recurrence whose [nextDue] has passed is proposed as a draft in the
/// SMS-capture review queue; the user records it (or dismisses it), and
/// [nextDue] advances to the following occurrence.
class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String accountId;

  /// Currency of [amount] — the holding account's currency, snapshotted so a
  /// later account currency change never reinterprets a standing entry.
  final String currency;

  final RecurrenceFrequency frequency;
  final DateTime nextDue;
  final String? note;
  final bool isActive;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.accountId,
    this.currency = Currency.defaultCode,
    required this.frequency,
    required this.nextDue,
    this.note,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id':       id,
        'title':    title,
        'amount':   amount,
        'type':     type.name,
        'category': category.name,
        'accountId': accountId,
        'currency': currency,
        'frequency': frequency.name,
        'nextDue':  Timestamp.fromDate(nextDue),
        'note':     note,
        'isActive': isActive,
      };

  factory RecurringTransaction.fromMap(Map<String, dynamic> m) =>
      RecurringTransaction(
        id:        m['id']        as String,
        title:     m['title']     as String,
        amount:    (m['amount'] as num).toDouble(),
        type:      TransactionType.values.firstWhere(
            (e) => e.name == m['type'], orElse: () => TransactionType.expense),
        category:  TransactionCategory.values.firstWhere(
            (e) => e.name == m['category'],
            orElse: () => TransactionCategory.other),
        accountId: m['accountId'] as String,
        currency:  m['currency'] as String? ?? Currency.defaultCode,
        frequency: RecurrenceFrequency.values.firstWhere(
            (e) => e.name == m['frequency'],
            orElse: () => RecurrenceFrequency.monthly),
        nextDue:   (m['nextDue'] as Timestamp).toDate(),
        note:      m['note'] as String?,
        isActive:  m['isActive'] as bool? ?? true,
      );

  /// The next occurrence strictly after [from], for advancing [nextDue].
  DateTime nextOccurrence(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        // Clamp to the last day of the target month so a 31st never overflows.
        final target = DateTime(from.year, from.month + 1, 1);
        final lastDay = DateTime(target.year, target.month + 1, 0).day;
        final day = from.day <= lastDay ? from.day : lastDay;
        return DateTime(target.year, target.month, day);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  RecurringTransaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? accountId,
    RecurrenceFrequency? frequency,
    DateTime? nextDue,
    String? note,
    bool? isActive,
  }) =>
      RecurringTransaction(
        id:        id,
        title:     title     ?? this.title,
        amount:    amount    ?? this.amount,
        type:      type      ?? this.type,
        category:  category  ?? this.category,
        accountId: accountId ?? this.accountId,
        currency:  currency,
        frequency: frequency ?? this.frequency,
        nextDue:   nextDue   ?? this.nextDue,
        note:      note      ?? this.note,
        isActive:  isActive  ?? this.isActive,
      );
}
