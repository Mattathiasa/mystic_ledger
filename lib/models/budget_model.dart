import 'transaction.dart';

enum BudgetPeriod { weekly, monthly, yearly }

class Budget {
  final String id;
  final BudgetPeriod period;
  final double amount;
  final TransactionCategory? category; // null = overall spending

  const Budget({
    required this.id,
    required this.period,
    required this.amount,
    this.category,
  });

  String get periodLabel {
    switch (period) {
      case BudgetPeriod.weekly:  return 'Weekly';
      case BudgetPeriod.monthly: return 'Monthly';
      case BudgetPeriod.yearly:  return 'Yearly';
    }
  }

  String get categoryLabel =>
      category == null ? 'Overall Spending' : catLabel(category!);

  static String catLabel(TransactionCategory c) {
    switch (c) {
      case TransactionCategory.food:          return 'Food';
      case TransactionCategory.transport:     return 'Transport';
      case TransactionCategory.utilities:     return 'Utilities';
      case TransactionCategory.entertainment: return 'Entertainment';
      case TransactionCategory.tithe:         return 'Tithe';
      case TransactionCategory.salary:        return 'Salary';
      case TransactionCategory.freelance:     return 'Freelance';
      case TransactionCategory.other:         return 'Other';
    }
  }

  Map<String, dynamic> toMap() => {
    'id':       id,
    'period':   period.name,
    'amount':   amount,
    'category': category?.name,
  };

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
    id:       m['id'] as String,
    period:   BudgetPeriod.values.firstWhere(
      (e) => e.name == m['period'],
      orElse: () => BudgetPeriod.monthly,
    ),
    amount:   (m['amount'] as num).toDouble(),
    category: m['category'] != null
        ? TransactionCategory.values.firstWhere(
            (e) => e.name == m['category'],
            orElse: () => TransactionCategory.other,
          )
        : null,
  );
}
