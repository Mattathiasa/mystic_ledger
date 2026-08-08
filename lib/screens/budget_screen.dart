import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_model.dart';
import '../models/transaction.dart';
import '../services/finance_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';

/// Budget Scrolls — set and track spending budgets per period.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: AppBar(
        backgroundColor: MysticColors.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: MysticColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Budget Scrolls',
            style: headlineStyle(22, italic: true, weight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
              height: 1.5,
              color: MysticColors.outlineVariant.withOpacity(0.5)),
        ),
      ),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          final budgets = svc.budgets;
          final fmt = NumberFormat('#,##0.00');

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Subtitle ──────────────────────────────────────────────
                Text(
                  'SET SPENDING LIMITS PER PERIOD',
                  style: labelStyle(9,
                      letterSpacing: 2.0,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
                ),
                const SizedBox(height: 32),

                if (budgets.isEmpty) ...[
                  _EmptyState(),
                ] else ...[
                  ...budgets.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _BudgetCard(
                          budget: b,
                          spent: svc.spentInPeriod(b),
                          fmt: fmt,
                          currency: svc.baseCurrency,
                          onDelete: () => reportIfWriteFails(
                              ScaffoldMessenger.maybeOf(context),
                              svc.deleteBudget(b.id)),
                          onEdit: () => _showSheet(context, existing: b),
                          onHistory: () => _showHistory(context, svc, b),
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSheet(context),
        backgroundColor: MysticColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('New Budget',
            style: bodyStyle(14, weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  /// Blank for a new budget, prefilled when [existing] is given.
  void _showSheet(BuildContext context, {Budget? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetSheet(existing: existing),
    );
  }

  /// Past-period performance for one budget.
  void _showHistory(BuildContext context, FinanceService svc, Budget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetHistorySheet(svc: svc, budget: budget),
    );
  }
}

// ── Budget history sheet ─────────────────────────────────────────────────────

/// Shows how each past period fared against the limit — "last month I was
/// under, the month before I blew it" — so the current card stops being a
/// snapshot with no memory.
class _BudgetHistorySheet extends StatelessWidget {
  final FinanceService svc;
  final Budget budget;
  const _BudgetHistorySheet({required this.svc, required this.budget});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final history = svc.budgetHistory(budget);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: MysticColors.appBarBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MysticColors.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget History',
                      style: headlineStyle(24,
                          italic: true, weight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '${budget.categoryLabel} · ${budget.periodLabel} · '
                    'limit ${svc.baseCurrency} ${fmt.format(budget.amount)}',
                    style: labelStyle(10,
                        letterSpacing: 1.0,
                        color: MysticColors.onSurfaceVariant.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1,
                color: MysticColors.outlineVariant.withOpacity(0.3)),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                itemCount: history.length,
                separatorBuilder: (_, __) => Divider(
                  height: 18,
                  color: MysticColors.outlineVariant.withOpacity(0.2),
                ),
                itemBuilder: (context, i) {
                  final h = history[i];
                  final pct = h.limit > 0 ? (h.spent / h.limit).clamp(0.0, 1.0) : 0.0;
                  final color =
                      h.over ? MysticColors.tertiary : MysticColors.secondary;

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _periodLabel(h.start, h.end),
                              style: bodyStyle(14, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor:
                                    MysticColors.outlineVariant.withOpacity(0.2),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              h.over
                                  ? 'Over by ${svc.baseCurrency} '
                                      '${fmt.format(h.spent - h.limit)}'
                                  : '${fmt.format(h.spent)} of '
                                      '${fmt.format(h.limit)} used',
                              style: labelStyle(10,
                                  letterSpacing: 0.3,
                                  color: h.over
                                      ? MysticColors.tertiary
                                      : MysticColors.onSurfaceVariant
                                          .withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${svc.baseCurrency} ${fmt.format(h.spent)}',
                        style: bodyStyle(14,
                            weight: FontWeight.w800,
                            color: color),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(DateTime start, DateTime end) {
    switch (budget.period) {
      case BudgetPeriod.weekly:
        return 'Week of ${DateFormat('MMM d').format(start)}';
      case BudgetPeriod.monthly:
        return DateFormat('MMMM yyyy').format(start);
      case BudgetPeriod.yearly:
        return '${start.year}';
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined,
              size: 48,
              color: MysticColors.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No budgets yet',
              style: headlineStyle(20,
                  italic: true,
                  weight: FontWeight.w700,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.5))),
          const SizedBox(height: 8),
          Text(
            'Tap + New Budget to set a spending limit',
            textAlign: TextAlign.center,
            style: bodyStyle(13,
                color: MysticColors.onSurfaceVariant.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

// ── Budget card with progress bar ─────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final double spent;
  final NumberFormat fmt;
  /// Budgets and their spend are expressed in the base currency.
  final String currency;
  final VoidCallback onDelete;

  /// Opens the budget for amendment. The delete icon keeps its own handler.
  final VoidCallback onEdit;

  /// Opens the past-period history sheet.
  final VoidCallback onHistory;

  const _BudgetCard({
    required this.budget,
    required this.spent,
    required this.fmt,
    required this.currency,
    required this.onDelete,
    required this.onEdit,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (spent / budget.amount).clamp(0.0, 1.0);
    final overBudget = spent > budget.amount;
    final progressColor =
        overBudget ? MysticColors.tertiary : MysticColors.secondary;
    final remaining = budget.amount - spent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: overBudget
              ? MysticColors.tertiary.withOpacity(0.3)
              : MysticColors.outlineVariant.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: MysticColors.onSurface.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MysticColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _budgetIcon(budget.category),
                  color: MysticColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.categoryLabel,
                        style: bodyStyle(15, weight: FontWeight.w700)),
                    Text(
                      budget.periodLabel.toUpperCase(),
                      style: labelStyle(8,
                          letterSpacing: 1.5,
                          color:
                              MysticColors.onSurfaceVariant.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.history,
                    size: 20,
                    color: MysticColors.primary.withOpacity(0.7)),
                tooltip: 'Budget history',
                onPressed: onHistory,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.4)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: MysticColors.surfaceContainerLow,
                      title: Text('Delete budget?',
                          style: headlineStyle(18,
                              italic: true, weight: FontWeight.w700)),
                      content: Text(
                          'Remove the ${budget.periodLabel.toLowerCase()} budget for ${budget.categoryLabel}?',
                          style: bodyStyle(14)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel',
                              style: bodyStyle(14,
                                  color: MysticColors.onSurfaceVariant)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          child: Text('Delete',
                              style: bodyStyle(14,
                                  color: MysticColors.tertiary,
                                  weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Amount info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SPENT', style: labelStyle(8, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text(
                    '$currency ${fmt.format(spent)}',
                    style: bodyStyle(16, weight: FontWeight.w700,
                        color: progressColor),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('BUDGET', style: labelStyle(8, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text(
                    '$currency ${fmt.format(budget.amount)}',
                    style: bodyStyle(16, weight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  MysticColors.outlineVariant.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),

          const SizedBox(height: 10),

          // Remaining / over label
          Text(
            overBudget
                ? 'Over budget by $currency ${fmt.format(spent - budget.amount)}'
                : '$currency ${fmt.format(remaining)} remaining',
            style: bodyStyle(12,
                color: overBudget
                    ? MysticColors.tertiary
                    : MysticColors.onSurfaceVariant.withOpacity(0.6)),
          ),
        ],
      ),
      ),
    );
  }

  IconData _budgetIcon(TransactionCategory? cat) {
    if (cat == null) return Icons.account_balance_wallet_outlined;
    return cat.icon;
  }
}

// ── Add budget bottom sheet ───────────────────────────────────────────────────

/// Creates a budget, or amends one when [existing] is given.
///
/// `setBudget` is an upsert keyed by document id, so re-saving with the same id
/// rewrites the record in place.
class _AddBudgetSheet extends StatefulWidget {
  final Budget? existing;

  const _AddBudgetSheet({this.existing});

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  BudgetPeriod _period = BudgetPeriod.monthly;
  TransactionCategory? _category; // null = overall
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    _period   = e.period;
    _category = e.category;
    _amountCtrl.text = e.amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _periodLabel(BudgetPeriod p) {
    switch (p) {
      case BudgetPeriod.weekly:  return 'Weekly';
      case BudgetPeriod.monthly: return 'Monthly';
      case BudgetPeriod.yearly:  return 'Yearly';
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);
    final svc = context.read<FinanceService>();
    final budget = Budget(
      // Keep the id on an edit. The generated one encodes period and category,
      // so regenerating it after either changed would write a *second*
      // document and leave the user looking at two budget cards. The encoding
      // is only a naming convenience — `Budget.fromMap` reads the fields — so
      // a stale one is harmless.
      id: widget.existing?.id ??
          '${_period.name}_${_category?.name ?? 'overall'}_${DateTime.now().millisecondsSinceEpoch}',
      period:   _period,
      amount:   amount,
      category: _category,
    );
    // Not awaited — the local write lands immediately; awaiting would stall
    // this sheet for as long as the device is offline.
    reportIfWriteFails(ScaffoldMessenger.maybeOf(context), svc.setBudget(budget));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + inset),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: MysticColors.outlineVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(_isEdit ? 'Amend Budget Scroll' : 'New Budget Scroll',
                style: headlineStyle(24, italic: true, weight: FontWeight.w700)),
            const SizedBox(height: 28),

            // Period selector
            Text('PERIOD',
                style: labelStyle(9,
                    letterSpacing: 1.5,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
            const SizedBox(height: 10),
            Row(
              children: BudgetPeriod.values.map((p) {
                final selected = _period == p;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? MysticColors.primary
                              : MysticColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? MysticColors.primary
                                : MysticColors.outlineVariant.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _periodLabel(p),
                            style: bodyStyle(13,
                                weight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : MysticColors.onSurface),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Category selector
            Text('CATEGORY',
                style: labelStyle(9,
                    letterSpacing: 1.5,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CatChip(
                  label: 'Overall',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                ...TransactionCategory.values
                    .where((c) => c != TransactionCategory.salary &&
                        c != TransactionCategory.freelance)
                    .map((c) => _CatChip(
                          label: c.label,
                          selected: _category == c,
                          onTap: () => setState(() => _category = c),
                        )),
              ],
            ),

            const SizedBox(height: 24),

            // Amount field
            Text('BUDGET AMOUNT (${context.read<FinanceService>().baseCurrency})',
                style: labelStyle(9,
                    letterSpacing: 1.5,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
            const SizedBox(height: 10),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: headlineStyle(28,
                  italic: false, weight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: headlineStyle(28,
                        italic: false, weight: FontWeight.w700)
                    .copyWith(
                        color: MysticColors.onSurface.withOpacity(0.2)),
                prefix: Text(
                  '${context.read<FinanceService>().baseCurrency}  ',
                  style: labelStyle(12,
                      letterSpacing: 0.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.5)),
                ),
                border: InputBorder.none,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: MysticColors.outlineVariant.withOpacity(0.3),
                      width: 1.5),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: MysticColors.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: MysticColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: MysticColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_isEdit ? 'Update Budget' : 'Inscribe Budget',
                            style: headlineStyle(18,
                                italic: true,
                                weight: FontWeight.w900,
                                color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? MysticColors.primaryContainer.withOpacity(0.2)
              : MysticColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? MysticColors.primary.withOpacity(0.4)
                : MysticColors.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: bodyStyle(13,
              weight: FontWeight.w600,
              color: selected
                  ? MysticColors.primary
                  : MysticColors.onSurface),
        ),
      ),
    );
  }
}
