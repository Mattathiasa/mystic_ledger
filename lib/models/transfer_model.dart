import 'package:cloud_firestore/cloud_firestore.dart';

class Transfer {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final double fee;   // Optional transfer fee debited from fromAccountId
  final DateTime date;
  final String? note;

  const Transfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.fee = 0.0,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id':            id,
        'fromAccountId': fromAccountId,
        'toAccountId':   toAccountId,
        'amount':        amount,
        'fee':           fee,
        'date':          Timestamp.fromDate(date),
        'note':          note,
      };

  factory Transfer.fromMap(Map<String, dynamic> m) => Transfer(
        id:            m['id']            as String,
        fromAccountId: m['fromAccountId'] as String,
        toAccountId:   m['toAccountId']   as String,
        amount:        (m['amount'] as num).toDouble(),
        fee:           (m['fee'] as num?)?.toDouble() ?? 0.0,
        date:          (m['date'] as Timestamp).toDate(),
        note:          m['note'] as String?,
      );
}
