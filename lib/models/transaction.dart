import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TransactionType { income, expense }

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

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.accountId,
    required this.category,
    required this.date,
    this.note,
  });

  // ── Firestore serialisation ──────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id':        id,
        'title':     title,
        'amount':    amount,
        'type':      type.name,
        'accountId': accountId,
        'category':  category.name,
        'date':      Timestamp.fromDate(date),
        'note':      note,
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
