import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtType { owe, owed }

class Debt {
  final String id;
  final String name;
  final double amount;
  final DebtType type;
  final DateTime date;
  final String? note;
  final bool isPaid;

  const Debt({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() => {
        'id':     id,
        'name':   name,
        'amount': amount,
        'type':   type.name,
        'date':   Timestamp.fromDate(date),
        'note':   note,
        'isPaid': isPaid,
      };

  factory Debt.fromMap(Map<String, dynamic> m) => Debt(
        id:     m['id']     as String,
        name:   m['name']   as String,
        amount: (m['amount'] as num).toDouble(),
        type:   DebtType.values.firstWhere(
            (e) => e.name == m['type'], orElse: () => DebtType.owe),
        date:   (m['date'] as Timestamp).toDate(),
        note:   m['note']   as String?,
        isPaid: m['isPaid'] as bool? ?? false,
      );

  Debt copyWith({bool? isPaid}) => Debt(
        id:     id,
        name:   name,
        amount: amount,
        type:   type,
        date:   date,
        note:   note,
        isPaid: isPaid ?? this.isPaid,
      );
}
