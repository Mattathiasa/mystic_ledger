import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../services/finance_service.dart';
import '../models/debt_model.dart';

/// Screen to track debts — money I owe and money owed to me.
class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCF0),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: MysticColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Debt Ledger',
          style: headlineStyle(22, italic: true, weight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelStyle: labelStyle(11,
              letterSpacing: 1.5, color: MysticColors.primary),
          unselectedLabelStyle:
              labelStyle(11, letterSpacing: 1.5),
          labelColor: MysticColors.primary,
          unselectedLabelColor: MysticColors.onSurfaceVariant,
          indicatorColor: MysticColors.primary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'I OWE'),
            Tab(text: 'OWED TO ME'),
          ],
        ),
      ),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          return Stack(
            children: [
              TabBarView(
                controller: _tabs,
                children: [
                  _DebtList(
                    debts: svc.iOwe,
                    allDebts: svc.debts.where((d) => d.type == DebtType.owe).toList(),
                    emptyMessage: 'No outstanding debts — your ledger is clean.',
                    type: DebtType.owe,
                    svc: svc,
                  ),
                  _DebtList(
                    debts: svc.owedToMe,
                    allDebts: svc.debts.where((d) => d.type == DebtType.owed).toList(),
                    emptyMessage: 'No one owes you gold at the moment.',
                    type: DebtType.owed,
                    svc: svc,
                  ),
                ],
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: _AddDebtFab(
                  onTap: () => _showAddSheet(context, svc),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, FinanceService svc) =>
      showDebtSheet(context, svc,
          initialType: _tabs.index == 0 ? DebtType.owe : DebtType.owed);
}

/// Opens the debt form — blank for a new record, prefilled when [existing] is
/// given. Shared so the FAB and tap-to-edit present identically.
void showDebtSheet(
  BuildContext context,
  FinanceService svc, {
  DebtType initialType = DebtType.owe,
  Debt? existing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddDebtSheet(
      svc: svc,
      initialType: initialType,
      existing: existing,
    ),
  );
}

// ── Debt list ─────────────────────────────────────────────────────────────────

class _DebtList extends StatelessWidget {
  final List<Debt> debts;       // unpaid only
  final List<Debt> allDebts;    // includes paid (for history)
  final String emptyMessage;
  final DebtType type;
  final FinanceService svc;

  const _DebtList({
    required this.debts,
    required this.allDebts,
    required this.emptyMessage,
    required this.type,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    final fmt    = NumberFormat('#,##0.00');
    final unpaid = debts;
    final paid   = allDebts.where((d) => d.isPaid).toList();

    if (allDebts.isEmpty) {
      return _EmptyState(message: emptyMessage);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        if (unpaid.isNotEmpty) ...[
          _SummaryBanner(
              debts: unpaid,
              type: type,
              fmt: fmt,
              currency: svc.baseCurrency),
          const SizedBox(height: 20),
          Text('OUTSTANDING',
              style: labelStyle(10,
                  letterSpacing: 2.0,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.7))),
          const SizedBox(height: 12),
          ...unpaid.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DebtCard(
                  debt: d,
                  fmt: fmt,
                  svc: svc,
                  onEdit: () => showDebtSheet(context, svc, existing: d),
                ),
              )),
        ],
        if (paid.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('SETTLED',
              style: labelStyle(10,
                  letterSpacing: 2.0,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.7))),
          const SizedBox(height: 12),
          ...paid.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DebtCard(
                  debt: d,
                  fmt: fmt,
                  svc: svc,
                  muted: true,
                  onEdit: () => showDebtSheet(context, svc, existing: d),
                ),
              )),
        ],
        if (unpaid.isEmpty && allDebts.isNotEmpty)
          _EmptyState(message: emptyMessage),
      ],
    );
  }
}

// ── Summary banner ────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final List<Debt> debts;
  final DebtType type;
  final NumberFormat fmt;
  /// Debts are recorded in the base currency.
  final String currency;

  const _SummaryBanner({
    required this.debts,
    required this.type,
    required this.fmt,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final total = debts.fold<double>(0, (s, d) => s + d.amount);
    final isOwe = type == DebtType.owe;

    return Transform.rotate(
      angle: -0.009,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isOwe
              ? MysticColors.tertiary.withOpacity(0.12)
              : MysticColors.secondary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOwe
                ? MysticColors.tertiary.withOpacity(0.25)
                : MysticColors.secondary.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOwe ? Icons.arrow_upward : Icons.arrow_downward,
              color: isOwe ? MysticColors.tertiary : MysticColors.secondary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwe ? 'TOTAL I OWE' : 'TOTAL OWED TO ME',
                    style: labelStyle(9,
                        letterSpacing: 1.5,
                        color: isOwe
                            ? MysticColors.tertiary
                            : MysticColors.secondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currency ${fmt.format(total)}',
                    style: headlineStyle(26,
                        italic: false,
                        weight: FontWeight.w900,
                        color: isOwe
                            ? MysticColors.tertiary
                            : MysticColors.secondary),
                  ),
                ],
              ),
            ),
            Text(
              '${debts.length} item${debts.length != 1 ? 's' : ''}',
              style: labelStyle(10, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual debt card ──────────────────────────────────────────────────────

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final NumberFormat fmt;
  final FinanceService svc;
  final bool muted;

  /// Opens the debt for amendment. The SETTLE toggle and the SETTLED chip keep
  /// their own handlers, so those still toggle rather than open the sheet.
  final VoidCallback onEdit;

  const _DebtCard({
    required this.debt,
    required this.fmt,
    required this.svc,
    required this.onEdit,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOwe   = debt.type == DebtType.owe;
    final color   = isOwe ? MysticColors.tertiary : MysticColors.secondary;
    final dateFmt = DateFormat('MMM d, yyyy · h:mm a');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: muted
            ? MysticColors.surfaceContainerHighest
            : MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MysticColors.outlineVariant.withOpacity(muted ? 0.05 : 0.15),
        ),
        boxShadow: muted
            ? []
            : [
                BoxShadow(
                  color: MysticColors.onSurface.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          // Initials avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: muted
                  ? MysticColors.surfaceContainer
                  : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                debt.name.isNotEmpty
                    ? debt.name[0].toUpperCase()
                    : '?',
                style: headlineStyle(18,
                    italic: false,
                    weight: FontWeight.w900,
                    color: muted ? MysticColors.outline : color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.name,
                  style: bodyStyle(15,
                          weight: FontWeight.w700,
                          color: muted ? MysticColors.outline : null)
                      .copyWith(
                          decoration: muted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(debt.date),
                  style: labelStyle(9, letterSpacing: 0.5),
                ),
                if (debt.note != null && debt.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    debt.note!,
                    style: bodyStyle(11,
                            color: MysticColors.onSurfaceVariant
                                .withOpacity(0.7))
                        .copyWith(fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${svc.baseCurrency} ${fmt.format(debt.amount)}',
                style: bodyStyle(14,
                    weight: FontWeight.w700,
                    color: muted ? MysticColors.outline : color),
              ),
              const SizedBox(height: 6),
              if (!muted)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => reportIfWriteFails(
                      ScaffoldMessenger.maybeOf(context),
                      svc.toggleDebtPaid(debt.id)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: color.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      'SETTLE',
                      style: labelStyle(9,
                          letterSpacing: 1.0, color: color),
                    ),
                  ),
                )
              else
                // Settling was one-way: this chip used to be inert, so a debt
                // marked settled by mistake could never be reopened.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => reportIfWriteFails(
                      ScaffoldMessenger.maybeOf(context),
                      svc.toggleDebtPaid(debt.id)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MysticColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SETTLED',
                      style: labelStyle(9,
                          letterSpacing: 1.0,
                          color: MysticColors.secondary),
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 64, 32, 0),
        child: Column(
          children: [
            const Icon(Icons.handshake_outlined,
                size: 56, color: MysticColors.outlineVariant),
            const SizedBox(height: 16),
            Text(
              message,
              style: headlineStyle(16,
                  italic: true,
                  weight: FontWeight.w600,
                  color: MysticColors.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add debt FAB ──────────────────────────────────────────────────────────────

class _AddDebtFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddDebtFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
            const Icon(Icons.add, color: MysticColors.onPrimary, size: 22),
            const SizedBox(width: 8),
            Text('ADD DEBT',
                style: labelStyle(11,
                    letterSpacing: 1.5, color: MysticColors.onPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Add debt bottom sheet ─────────────────────────────────────────────────────

/// Records a debt, or amends one when [existing] is given.
///
/// `addDebt` is an upsert keyed by document id, so re-saving with the same id
/// rewrites the record in place.
class _AddDebtSheet extends StatefulWidget {
  final FinanceService svc;
  final DebtType initialType;
  final Debt? existing;

  const _AddDebtSheet({
    required this.svc,
    required this.initialType,
    this.existing,
  });

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _amtCtrl   = TextEditingController();
  final _noteCtrl  = TextEditingController();

  late DebtType _type;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.initialType;
    if (e == null) return;
    _nameCtrl.text = e.name;
    _amtCtrl.text  = e.amount.toStringAsFixed(2);
    _noteCtrl.text = e.note ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amtCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    final existing = widget.existing;
    reportIfWriteFails(
      ScaffoldMessenger.maybeOf(context),
      widget.svc.addDebt(
        Debt(
          // Same id ⇒ the upsert rewrites this debt instead of adding one.
          id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameCtrl.text.trim(),
          amount: amount,
          type: _type,
          // The form collects neither of these, and `Debt` defaults isPaid to
          // false — so amending a settled debt would quietly un-settle it and
          // put it back in the outstanding totals.
          date: existing?.date ?? DateTime.now(),
          isPaid: existing?.isPaid ?? false,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        decoration: const BoxDecoration(
          color: MysticColors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
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
              Text(_isEdit ? 'Amend Debt' : 'Record Debt',
                  style: headlineStyle(24, italic: true, weight: FontWeight.w900)),
              const SizedBox(height: 20),

              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: _TypeToggle(
                      label: 'I OWE',
                      selected: _type == DebtType.owe,
                      color: MysticColors.tertiary,
                      onTap: () => setState(() => _type = DebtType.owe),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeToggle(
                      label: 'OWED TO ME',
                      selected: _type == DebtType.owed,
                      color: MysticColors.secondary,
                      onTap: () => setState(() => _type = DebtType.owed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Person name
              Text('PERSON / ORGANISATION',
                  style: labelStyle(9,
                      letterSpacing: 1.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: bodyStyle(16, weight: FontWeight.w600),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Who is involved?',
                  hintStyle: bodyStyle(16)
                      .copyWith(color: MysticColors.onSurface.withOpacity(0.25)),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 20),

              // Amount
              Text('AMOUNT',
                  style: labelStyle(9,
                      letterSpacing: 1.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(widget.svc.baseCurrency,
                      style: headlineStyle(22,
                          italic: false,
                          weight: FontWeight.w700,
                          color: MysticColors.primary.withOpacity(0.7))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _amtCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                      style: headlineStyle(32,
                          italic: false, weight: FontWeight.w900),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: headlineStyle(32,
                                italic: false, weight: FontWeight.w900)
                            .copyWith(
                                color:
                                    MysticColors.onSurface.withOpacity(0.15)),
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
              const SizedBox(height: 16),

              // Note
              Text('NOTE (OPTIONAL)',
                  style: labelStyle(9,
                      letterSpacing: 1.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                style: bodyStyle(13, color: MysticColors.onSurfaceVariant)
                    .copyWith(fontStyle: FontStyle.italic),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add context...',
                  hintStyle: bodyStyle(13,
                          color: MysticColors.onSurface.withOpacity(0.2))
                      .copyWith(fontStyle: FontStyle.italic),
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
                      _isEdit ? 'Update Record' : 'Record in Ledger',
                      style: headlineStyle(18,
                          italic: true,
                          weight: FontWeight.w900,
                          color: MysticColors.onPrimary),
                    ),
                  ),
                ),
              ),

              // Deletion lives here rather than on the card: the card's row is
              // already avatar | name | amount + SETTLE, and putting a
              // destructive control beside a state toggle on a money record
              // invites mis-taps. Mirrors the account editor.
              if (_isEdit) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _confirmRemove,
                  child: Text('Remove this debt',
                      style: bodyStyle(13, color: MysticColors.tertiary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove() async {
    final debt = widget.existing!;
    final svc  = widget.svc;
    final fmt  = NumberFormat('#,##0.00');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MysticColors.surfaceContainerLow,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete debt?',
            style: headlineStyle(20, italic: true, weight: FontWeight.w700)),
        content: Text(
          'Remove the record of ${debt.name} for '
          '${svc.baseCurrency} ${fmt.format(debt.amount)}? '
          'This cannot be undone.',
          style: bodyStyle(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: bodyStyle(14,
                    weight: FontWeight.w700, color: MysticColors.tertiary)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    // Captured before the pop — this sheet's context is gone by the time a
    // server rejection comes back.
    reportIfWriteFails(
        ScaffoldMessenger.maybeOf(context), svc.deleteDebt(debt.id));
    if (mounted) Navigator.of(context).pop();
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : MysticColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: labelStyle(10,
                letterSpacing: 1.2,
                color: selected
                    ? color
                    : MysticColors.onSurfaceVariant.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}
