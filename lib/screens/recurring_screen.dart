import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../services/finance_service.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';

/// Manage recurring transactions — salary, rent, subscriptions.\n///
/// On each app resume, schedules whose due date has passed are proposed in the
/// review queue (same banner as SMS captures); this screen is where they are
/// defined and edited.
class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
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
        title: Text('Recurring',
            style: headlineStyle(22, italic: true, weight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
              height: 1.5, color: MysticColors.outlineVariant.withOpacity(0.5)),
        ),
      ),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          final all = svc.recurring;
          return Stack(
            children: [
              if (all.isEmpty)
                const _EmptyRecurring()
              else
                ListView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
                  children: [
                    Text(
                      '${all.length} SCHEDULE${all.length != 1 ? 'S' : ''} · '
                      'DUE ONES PROPOSE THEMSELVES ON RESUME',
                      style: labelStyle(10,
                          letterSpacing: 2.0,
                          color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 16),
                    ...all.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecurringCard(
                            r: r,
                            svc: svc,
                            onEdit: () => _showSheet(context, svc, existing: r),
                          ),
                        )),
                  ],
                ),
              Positioned(
                bottom: 24,
                right: 24,
                child: GestureDetector(
                  onTap: () => _showSheet(context, svc),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: MysticColors.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MysticColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat,
                            color: MysticColors.onPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text('NEW SCHEDULE',
                            style: labelStyle(11,
                                letterSpacing: 1.5,
                                color: MysticColors.onPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSheet(BuildContext context, FinanceService svc,
      {RecurringTransaction? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecurringSheet(svc: svc, existing: existing),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyRecurring extends StatelessWidget {
  const _EmptyRecurring();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 64, 32, 0),
        child: Column(
          children: [
            Icon(Icons.repeat,
                size: 56, color: MysticColors.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'Nothing repeats yet',
              style: headlineStyle(16,
                  italic: true, weight: FontWeight.w600,
                  color: MysticColors.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Salary, rent, subscriptions — set a schedule once and each '
              'occurrence lands in your review queue, ready to record.',
              style: bodyStyle(13,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── One schedule card ─────────────────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  final RecurringTransaction r;
  final FinanceService svc;
  final VoidCallback onEdit;
  const _RecurringCard({required this.r, required this.svc, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final isIncome = r.type == TransactionType.income;
    final accent = isIncome ? MysticColors.secondary : MysticColors.tertiary;
    final overdue = r.isActive && !r.nextDue.isAfter(DateTime.now());
    final dateFmt = DateFormat('MMM d, yyyy');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: r.isActive
              ? MysticColors.surfaceContainerLow
              : MysticColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: r.isActive
                ? accent.withOpacity(0.2)
                : MysticColors.outlineVariant.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: r.isActive
                    ? accent.withOpacity(0.12)
                    : MysticColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                size: 20,
                color: r.isActive ? accent : MysticColors.outline,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: bodyStyle(15,
                        weight: FontWeight.w700,
                        color: r.isActive ? null : MysticColors.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.frequency.label} · next due ${dateFmt.format(r.nextDue)}'
                    '${overdue ? ' · DUE' : ''}',
                    style: labelStyle(9,
                        letterSpacing: 0.5,
                        color: overdue
                            ? MysticColors.tertiary
                            : MysticColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${r.currency} ${fmt.format(r.amount)}',
                  style: bodyStyle(14,
                      weight: FontWeight.w700,
                      color: r.isActive ? accent : MysticColors.outline),
                ),
                SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => reportIfWriteFails(
                      ScaffoldMessenger.maybeOf(context),
                      svc.toggleRecurring(r.id, !r.isActive)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: r.isActive
                          ? accent.withOpacity(0.12)
                          : MysticColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.isActive ? 'ACTIVE' : 'PAUSED',
                      style: labelStyle(9,
                          letterSpacing: 1.0,
                          color: r.isActive
                              ? accent
                              : MysticColors.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / edit sheet ─────────────────────────────────────────────────────────

class _RecurringSheet extends StatefulWidget {
  final FinanceService svc;
  final RecurringTransaction? existing;
  const _RecurringSheet({required this.svc, this.existing});

  @override
  State<_RecurringSheet> createState() => _RecurringSheetState();
}

class _RecurringSheetState extends State<_RecurringSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _amtCtrl    = TextEditingController();
  final _noteCtrl   = TextEditingController();

  TransactionType     _type     = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.other;
  RecurrenceFrequency _freq     = RecurrenceFrequency.monthly;
  String? _accountId;
  DateTime _nextDue = DateTime.now();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) {
      final spendable = widget.svc.spendableAccounts;
      if (spendable.isNotEmpty) _accountId = spendable.first.id;
      return;
    }
    _titleCtrl.text  = e.title;
    _amtCtrl.text    = e.amount.toStringAsFixed(2);
    _noteCtrl.text   = e.note ?? '';
    _type     = e.type;
    _category = e.category;
    _freq     = e.frequency;
    _accountId = e.accountId;
    _nextDue  = e.nextDue;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) return;
    final amount = double.tryParse(_amtCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    final existing = widget.existing;
    reportIfWriteFails(
      ScaffoldMessenger.maybeOf(context),
      widget.svc.addRecurring(
        RecurringTransaction(
          id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleCtrl.text.trim(),
          amount: amount,
          type: _type,
          category: _category,
          accountId: _accountId!,
          currency: widget.svc.currencyOf(_accountId!),
          frequency: _freq,
          nextDue: existing?.nextDue ?? _nextDue,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          isActive: existing?.isActive ?? true,
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _pickNextDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDue,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 10),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: MysticColors.primary,
            surface: MysticColors.surfaceContainerLow,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _nextDue = picked);
  }

  @override
  Widget build(BuildContext context) {
    final svc      = widget.svc;
    final accounts = svc.spendableAccounts;
    final bottom   = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        decoration: BoxDecoration(
          color: MysticColors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MysticColors.outlineVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_isEdit ? 'Amend Schedule' : 'New Recurring',
                    style:
                        headlineStyle(24, italic: true, weight: FontWeight.w900)),
                const SizedBox(height: 20),

                _label('DESCRIPTION'),
                TextFormField(
                  controller: _titleCtrl,
                  style: bodyStyle(16, weight: FontWeight.w600),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _input('e.g. Monthly salary'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a description'
                      : null,
                ),
                const SizedBox(height: 20),

                _label('AMOUNT'),
                Row(
                  children: [
                    Text(_accountId == null
                        ? svc.baseCurrency
                        : svc.currencyOf(_accountId!),
                        style: headlineStyle(22,
                            italic: false, weight: FontWeight.w700,
                            color: MysticColors.primary.withOpacity(0.7))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _amtCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                        ],
                        style: headlineStyle(30,
                            italic: false, weight: FontWeight.w900),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: headlineStyle(30,
                                  italic: false, weight: FontWeight.w900)
                              .copyWith(color: MysticColors.onSurface.withOpacity(0.15)),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter an amount';
                          final p = double.tryParse(v.replaceAll(',', ''));
                          if (p == null || p <= 0) return 'Enter a valid amount';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                Container(
                    height: 1.5,
                    color: MysticColors.outlineVariant.withOpacity(0.3)),
                const SizedBox(height: 20),

                _label('TYPE'),
                Row(
                  children: [
                    Expanded(
                      child: _pill(
                        label: 'Expense',
                        selected: _type == TransactionType.expense,
                        color: MysticColors.tertiary,
                        onTap: () => setState(
                            () => _type = TransactionType.expense),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _pill(
                        label: 'Income',
                        selected: _type == TransactionType.income,
                        color: MysticColors.secondary,
                        onTap: () =>
                            setState(() => _type = TransactionType.income),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _label('FREQUENCY'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RecurrenceFrequency.values.map((f) {
                    return _chip(
                      label: f.label,
                      selected: _freq == f,
                      onTap: () => setState(() => _freq = f),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                _label('NEXT DUE'),
                GestureDetector(
                  onTap: _pickNextDue,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: MysticColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_outlined,
                            size: 18, color: MysticColors.primary),
                        const SizedBox(width: 10),
                        Text(DateFormat('EEE, MMM d, yyyy').format(_nextDue),
                            style: bodyStyle(14, weight: FontWeight.w600)),
                        const Spacer(),
                        Icon(Icons.edit_outlined,
                            size: 16, color: MysticColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _label('ACCOUNT'),
                DropdownButtonFormField<String>(
                  value:
                      accounts.any((a) => a.id == _accountId) ? _accountId : null,
                  onChanged: (v) {
                    if (v != null) setState(() => _accountId = v);
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(bottom: 8),
                    isDense: true,
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
                  style: bodyStyle(15, weight: FontWeight.w600),
                  dropdownColor: MysticColors.surfaceContainerLow,
                  items: accounts
                      .map((a) =>
                          DropdownMenuItem(value: a.id, child: Text(a.name)))
                      .toList(),
                ),
                const SizedBox(height: 20),

                _label('NOTE (OPTIONAL)'),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  style: bodyStyle(13, color: MysticColors.onSurfaceVariant)
                      .copyWith(fontStyle: FontStyle.italic),
                  decoration: _input('Add context...'),
                ),
                const SizedBox(height: 28),

                GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: MysticColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: MysticColors.primary.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _isEdit ? 'Update Schedule' : 'Set Schedule',
                        style: headlineStyle(18,
                            italic: true, weight: FontWeight.w900,
                            color: MysticColors.onPrimary),
                      ),
                    ),
                  ),
                ),

                if (_isEdit) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _confirmRemove,
                    child: Text('Remove this schedule',
                        style: bodyStyle(13, color: MysticColors.tertiary)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
      );

  InputDecoration _input(String hint) => InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: bodyStyle(16)
            .copyWith(color: MysticColors.onSurface.withOpacity(0.25)),
        contentPadding: const EdgeInsets.only(bottom: 8),
        isDense: true,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: MysticColors.outlineVariant.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: MysticColors.primary, width: 1.5),
        ),
      );

  Widget _pill({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.12)
                : MysticColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withOpacity(0.4) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(label.toUpperCase(),
                style: labelStyle(10,
                    letterSpacing: 1.2,
                    color: selected
                        ? color
                        : MysticColors.onSurfaceVariant.withOpacity(0.5))),
          ),
        ),
      );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? MysticColors.primaryContainer.withOpacity(0.35)
                : MysticColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? MysticColors.primaryContainer.withOpacity(0.6)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(label.toUpperCase(),
              style: labelStyle(10,
                  letterSpacing: 0.8,
                  color: selected
                      ? MysticColors.onSurface
                      : MysticColors.onSurfaceVariant.withOpacity(0.6))),
        ),
      );

  Future<void> _confirmRemove() async {
    final r   = widget.existing!;
    final svc = widget.svc;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MysticColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove schedule?',
            style: headlineStyle(20, italic: true, weight: FontWeight.w700)),
        content: Text('Delete the recurring "${r.title}"? Its past entries in '
            'the ledger are untouched.', style: bodyStyle(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: bodyStyle(14,
                    weight: FontWeight.w700, color: MysticColors.tertiary)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    reportIfWriteFails(
        ScaffoldMessenger.maybeOf(context), svc.deleteRecurring(r.id));
    if (mounted) Navigator.of(context).pop();
  }
}
