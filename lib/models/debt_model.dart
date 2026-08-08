import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtType { owe, owed }

class Debt {
  final String id;
  final String name;
  final double amount;
  final DebtType type;
  final DateTime date;

  /// When this debt should be settled. Null = no deadline.
  final DateTime? dueDate;

  final String? note;
  final bool isPaid;

  const Debt({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.date,
    this.dueDate,
    this.note,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() => {
        'id':      id,
        'name':    name,
        'amount':  amount,
        'type':    type.name,
        'date':    Timestamp.fromDate(date),
        'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
        'note':    note,
        'isPaid':  isPaid,
      };

  factory Debt.fromMap(Map<String, dynamic> m) => Debt(
        id:      m['id']      as String,
        name:    m['name']    as String,
        amount:  (m['amount'] as num).toDouble(),
        type:    DebtType.values.firstWhere(
            (e) => e.name == m['type'], orElse: () => DebtType.owe),
        date:    (m['date'] as Timestamp).toDate(),
        dueDate: (m['dueDate'] as Timestamp?)?.toDate(),
        note:    m['note']    as String?,
        isPaid:  m['isPaid']  as bool? ?? false,
      );

  Debt copyWith({bool? isPaid, DateTime? dueDate}) => Debt(
        id:      id,
        name:    name,
        amount:  amount,
        type:    type,
        date:    date,
        dueDate: dueDate ?? this.dueDate,
        note:    note,
        isPaid:  isPaid ?? this.isPaid,
      );

  /// Days from today until [dueDate]; negative when already overdue.
  int? get daysUntilDue {
    if (dueDate == null) return null;
    return DateTime(dueDate!.year, dueDate!.month, dueDate!.day)
        .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
  }

  bool get isOverdue => daysUntilDue != null && daysUntilDue! < 0;
}
