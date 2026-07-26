import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../services/finance_service.dart';
import '../models/transaction.dart';
import '../models/account_model.dart';

/// Modal screen — slides up from the bottom when tapping ADD ENTRY.
class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _titleCtrl  = TextEditingController();
  final _noteCtrl   = TextEditingController();
  final _feeCtrl    = TextEditingController();

  TransactionType    _type     = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.other;
  String? _accountId; // set to first spendable account on first build

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  bool _saving = false;

  void _save() {
    // Guards against a double-tap writing the entry twice.
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    setState(() => _saving = true);

    final svc = context.read<FinanceService>();
    // Amounts are recorded in the holding account's currency, with the rate
    // snapshotted so reports stay stable when rates are updated later.
    final currency = svc.currencyOf(_accountId!);
    final fee = _type == TransactionType.expense
        ? (double.tryParse(_feeCtrl.text.replaceAll(',', '')) ?? 0.0)
        : 0.0;

    // Capture before popping — this screen's context is gone by the time a
    // server rejection comes back.
    final messenger = ScaffoldMessenger.of(context);
    reportIfWriteFails(
      messenger,
      svc.addTransaction(
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleCtrl.text.trim(),
          amount: amount,
          type: _type,
          category: _category,
          accountId: _accountId!,
          date: DateTime.now(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          currency: currency,
          rateToBase: svc.settings.rateFor(currency),
          fee: fee,
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final svc     = context.watch<FinanceService>();
    final accounts = svc.spendableAccounts;

    // Initialise default account on first build
    if (_accountId == null && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }

    // The entry is denominated in whichever account holds it.
    final entryCurrency =
        _accountId == null ? svc.baseCurrency : svc.currencyOf(_accountId!);

    final today     = DateTime.now();
    final dayLabel  = _ordinalDay(today.day);
    final monthYear = DateFormat('MMMM, yyyy').format(today);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: MysticColors.background,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEW RECORD',
                              style: labelStyle(10,
                                  letterSpacing: 2.0,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.6)),
                            ),
                            const SizedBox(height: 4),
                            Transform.rotate(
                              angle: -0.017,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Write Entry',
                                style: headlineStyle(32,
                                    italic: true, weight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$dayLabel Moon',
                            style: headlineStyle(16,
                                italic: true,
                                weight: FontWeight.w700,
                                color: MysticColors.primary),
                          ),
                          Text(
                            monthYear.toUpperCase(),
                            style: labelStyle(9,
                                letterSpacing: 1.5,
                                color: MysticColors.onSurfaceVariant
                                    .withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Form card ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: MysticColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: MysticColors.outlineVariant.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: MysticColors.onSurface.withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AmountField(
                          controller: _amountCtrl,
                          currency: entryCurrency,
                        ),
                        // Fees apply to money going out, not coming in.
                        if (_type == TransactionType.expense) ...[
                          const SizedBox(height: 20),
                          _FeeField(
                            controller: _feeCtrl,
                            currency: entryCurrency,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _divider(),
                        const SizedBox(height: 24),
                        _TitleField(controller: _titleCtrl),
                        const SizedBox(height: 24),
                        _divider(),
                        const SizedBox(height: 24),
                        _TypeSelector(
                          selected: _type,
                          onChanged: (t) => setState(() => _type = t),
                        ),
                        const SizedBox(height: 24),
                        _divider(),
                        const SizedBox(height: 24),
                        _CategoryPicker(
                          selected: _category,
                          type: _type,
                          onChanged: (c) => setState(() => _category = c),
                        ),
                        const SizedBox(height: 24),
                        _divider(),
                        const SizedBox(height: 24),
                        _AccountPicker(
                          accounts: accounts,
                          selectedId: _accountId ?? '',
                          onChanged: (id) => setState(() => _accountId = id),
                        ),
                        const SizedBox(height: 24),
                        _divider(),
                        const SizedBox(height: 24),
                        _NoteField(controller: _noteCtrl),
                        const SizedBox(height: 32),
                        _SaveButton(onTap: _save, busy: _saving),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'DISCARD ENTRY',
                        style: labelStyle(11,
                            letterSpacing: 1.5,
                            color: MysticColors.onSurfaceVariant.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        color: MysticColors.outlineVariant.withOpacity(0.2),
      );

  String _ordinalDay(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:  return '${day}st';
      case 2:  return '${day}nd';
      case 3:  return '${day}rd';
      default: return '${day}th';
    }
  }
}

// ── Amount field ──────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  const _AmountField({required this.controller, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AMOUNT',
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              currency,
              style: headlineStyle(24,
                  italic: false,
                  weight: FontWeight.w700,
                  color: MysticColors.primary.withOpacity(0.7)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                style: headlineStyle(48, italic: false, weight: FontWeight.w900),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '0.00',
                  hintStyle: headlineStyle(48, italic: false, weight: FontWeight.w900)
                      .copyWith(color: MysticColors.onSurface.withOpacity(0.15)),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter an amount';
                  final parsed = double.tryParse(v.replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
            ),
          ],
        ),
        Container(height: 1.5, color: MysticColors.outlineVariant.withOpacity(0.3)),
      ],
    );
  }
}

// ── Fee field ─────────────────────────────────────────────────────────────────

/// Bank or service charge paid alongside an expense. Comes out of the same
/// account and is tracked separately so total fees can be reported.
class _FeeField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  const _FeeField({required this.controller, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FEE / SERVICE CHARGE (OPTIONAL)',
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(currency,
                style: bodyStyle(15,
                    weight: FontWeight.w600,
                    color: MysticColors.tertiary.withOpacity(0.7))),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                style: bodyStyle(20,
                    weight: FontWeight.w700, color: MysticColors.tertiary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '0.00',
                  hintStyle: bodyStyle(20, weight: FontWeight.w700)
                      .copyWith(color: MysticColors.onSurface.withOpacity(0.15)),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        Container(
            height: 1, color: MysticColors.outlineVariant.withOpacity(0.3)),
      ],
    );
  }
}

// ── Title field ───────────────────────────────────────────────────────────────

class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  const _TitleField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DESCRIPTION',
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: bodyStyle(18, weight: FontWeight.w600),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'What was this entry for?',
            hintStyle: bodyStyle(18, weight: FontWeight.w600)
                .copyWith(color: MysticColors.onSurface.withOpacity(0.25)),
            contentPadding: const EdgeInsets.only(bottom: 8),
            isDense: true,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Enter a description' : null,
        ),
        Container(height: 1.5, color: MysticColors.outlineVariant.withOpacity(0.3)),
      ],
    );
  }
}

// ── Type selector ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TYPE',
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                label: 'Expense',
                icon: Icons.remove_circle_outline,
                selected: selected == TransactionType.expense,
                activeColor: MysticColors.tertiary,
                rotation: -0.017,
                onTap: () => onChanged(TransactionType.expense),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeCard(
                label: 'Income',
                icon: Icons.add_circle_outline,
                selected: selected == TransactionType.income,
                activeColor: MysticColors.secondary,
                rotation: 0.017,
                onTap: () => onChanged(TransactionType.income),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final double rotation;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.rotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: selected
            ? (Matrix4.identity()..rotateZ(rotation))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.12)
              : MysticColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? activeColor.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: activeColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected
                    ? activeColor
                    : MysticColors.onSurfaceVariant.withOpacity(0.4),
                size: 24),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: labelStyle(10,
                  letterSpacing: 1.2,
                  color: selected
                      ? activeColor
                      : MysticColors.onSurfaceVariant.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category picker ───────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final TransactionCategory selected;
  final TransactionType type;
  final ValueChanged<TransactionCategory> onChanged;
  const _CategoryPicker(
      {required this.selected, required this.type, required this.onChanged});

  static const _expenseCategories = [
    TransactionCategory.food,
    TransactionCategory.transport,
    TransactionCategory.utilities,
    TransactionCategory.entertainment,
    TransactionCategory.tithe,
    TransactionCategory.other,
  ];

  static const _incomeCategories = [
    TransactionCategory.salary,
    TransactionCategory.freelance,
    TransactionCategory.tithe,
    TransactionCategory.other,
  ];

  @override
  Widget build(BuildContext context) {
    final cats =
        type == TransactionType.income ? _incomeCategories : _expenseCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATEGORY',
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cats.map((cat) {
            final isSelected = selected == cat;
            return GestureDetector(
              onTap: () => onChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MysticColors.primaryContainer.withOpacity(0.35)
                      : MysticColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? MysticColors.primaryContainer.withOpacity(0.6)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  cat.pickerLabel,
                  style: labelStyle(10,
                      letterSpacing: 0.8,
                      color: isSelected
                          ? MysticColors.onSurface
                          : MysticColors.onSurfaceVariant.withOpacity(0.6)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Account picker (dynamic) ──────────────────────────────────────────────────

class _AccountPicker extends StatelessWidget {
  final List<Account> accounts;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _AccountPicker({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACCOUNT',
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: accounts.any((a) => a.id == selectedId) ? selectedId : null,
          onChanged: (v) {
            if (v != null) onChanged(v);
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
            focusedBorder: const UnderlineInputBorder(
              borderSide:
                  BorderSide(color: MysticColors.primary, width: 1.5),
            ),
          ),
          style: bodyStyle(15, weight: FontWeight.w600),
          dropdownColor: MysticColors.surfaceContainerLow,
          items: accounts
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
              .toList(),
        ),
      ],
    );
  }
}

// ── Note field ────────────────────────────────────────────────────────────────

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOTE (OPTIONAL)',
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: bodyStyle(14, color: MysticColors.onSurfaceVariant)
              .copyWith(fontStyle: FontStyle.italic),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'A brief annotation for the archive...',
            hintStyle: bodyStyle(14, color: MysticColors.onSurface.withOpacity(0.2))
                .copyWith(fontStyle: FontStyle.italic),
            contentPadding: const EdgeInsets.only(bottom: 8),
            isDense: true,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: MysticColors.outlineVariant.withOpacity(0.3),
                  width: 1.5),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: MysticColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool busy;
  const _SaveButton({required this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: busy
              ? MysticColors.primary.withOpacity(0.5)
              : MysticColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: busy
              ? null
              : [
                  BoxShadow(
                    color: MysticColors.primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'Save Entry',
                  style: headlineStyle(20,
                      italic: true,
                      weight: FontWeight.w900,
                      color: MysticColors.onPrimary),
                ),
        ),
      ),
    );
  }
}

// ── Category label extension ──────────────────────────────────────────────────

extension _CategoryLabel on TransactionCategory {
  String get pickerLabel {
    switch (this) {
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
}
