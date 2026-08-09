import '../services/l10n.dart';
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
      case BudgetPeriod.weekly:  return L10n.t('Weekly');
      case BudgetPeriod.monthly: return L10n.t('Monthly');
      case BudgetPeriod.yearly:  return L10n.t('Yearly');
    }
  }

  String get categoryLabel =>
      category == null ? L10n.t('Overall Spending') : category!.label;

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
