import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/l10n.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/empty_state_card.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';
import '../models/transfer_model.dart';
import 'add_account_screen.dart';

/// Screen for the Savings Vault.
/// Shows total saved, history of deposits, and a button to deposit more.
class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark mode or the language flips: the palette and strings
    // live in mutable statics, so const widget instances would skip us.
    Theme.of(context);
    Localizations.localeOf(context);

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
        title: Text(
          L10n.t('Savings Vault'),
          style: headlineStyle(22, italic: true, weight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
              height: 1.5,
              color: MysticColors.outlineVariant.withOpacity(0.5)),
        ),
      ),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          final fmt = NumberFormat('#,##0.00');
          final summary = svc.savingsSummary;

          // Nothing is created at sign-up, so there may be no vault at all.
          // Offer the way to make one rather than a 0.00 hero above an empty
          // list with a deposit button that has nowhere to deposit to.
          if (summary.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: NoAccountsCard(
                headline: L10n.t('No vault sealed yet'),
                body: L10n.t('A savings vault is kept apart from your spending '
                    'accounts, so what you set aside stays set aside. Open one '
                    'to start.'),
                presetType: AccountType.savings,
                ctaLabel: L10n.t('Open a vault'),
              ),
            );
          }

          final savingsTransfers = svc.savingsTransfers;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Hero card ──────────────────────────────────────────
                    _SavingsHeroCard(
                      summary: summary,
                      svc: svc,
                      hidden: svc.savingsHidden,
                      fmt: fmt,
                    ),

                    // With one vault the hero already says everything; the
                    // breakdown only earns its space once there are several,
                    // where each holds its own (possibly foreign) currency.
                    if (summary.accounts.length > 1) ...[
                      const SizedBox(height: 20),
                      _VaultBreakdown(summary: summary, svc: svc, fmt: fmt),
                    ],

                    const SizedBox(height: 32),

                    // ── History ────────────────────────────────────────────
                    Text(
                      L10n.t('DEPOSIT HISTORY'),
                      style: labelStyle(10,
                          letterSpacing: 2.0,
                          color: MysticColors.onSurfaceVariant.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 16),
                    if (savingsTransfers.isEmpty)
                      _EmptyHistory()
                    else
                      _HistoryList(
                        transfers: savingsTransfers,
                        svc: svc,
                        fmt: fmt,
                      ),
                  ],
                ),
              ),

              // ── FAB: Deposit ───────────────────────────────────────────
              Positioned(
                bottom: 24,
                right: 24,
                child: _DepositFab(
                  onTap: () => _showDepositSheet(context, svc),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDepositSheet(BuildContext context, FinanceService svc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DepositSheet(svc: svc),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _SavingsHeroCard extends StatelessWidget {
  final SavingsSummary summary;
  final FinanceService svc;
  final bool hidden;
  final NumberFormat fmt;
  const _SavingsHeroCard({
    required this.summary,
    required this.svc,
    required this.hidden,
    required this.fmt,
  });

  /// The savings goal shown on the hero: summed across every vault that has
  /// one, in the vault currency (or the base currency when a conversion is in
  /// play). Null when no vault defines a target.
  ({double amount, String currency})? get _goal {
    final withTargets =
        summary.accounts.where((a) => a.targetAmount != null).toList();
    if (withTargets.isEmpty) return null;
    return (
      amount: withTargets.map((a) => a.targetAmount!).reduce((a, b) => a + b),
      currency: summary.converted
          ? svc.baseCurrency
          : withTargets.first.currency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    return Transform.rotate(
      angle: -0.009,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: MysticColors.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: MysticColors.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Opacity(
                opacity: 0.12,
                child: Icon(Icons.savings,
                    size: 130, color: MysticColors.onPrimary),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MysticColors.onPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    summary.accounts.length > 1
                        ? '${summary.accounts.length} ${L10n.t('SAVINGS VAULTS')}'
                        : L10n.t('SAVINGS VAULT'),
                    style: labelStyle(9,
                        letterSpacing: 1.5,
                        color: MysticColors.onPrimary.withOpacity(0.9)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  L10n.t('Total Saved'),
                  style: bodyStyle(14,
                          color: MysticColors.onPrimary.withOpacity(0.7))
                      .copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                Text(
                  hidden
                      ? '••••••'
                      : '${summary.converted ? '≈ ' : ''}${summary.currency} '
                          '${fmt.format(summary.amount)}',
                  style: headlineStyle(40,
                      italic: false,
                      weight: FontWeight.w900,
                      color: MysticColors.onPrimary),
                ),
                // A sum across currencies is an estimate at today's rates, and
                // it should say so rather than read as an exact figure.
                if (summary.converted && !hidden) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${L10n.t('Converted from')} '
                    '${summary.accounts.map((a) => a.currency).toSet().length} '
                    '${L10n.t("currencies at today's rates.")}',
                    style: labelStyle(9,
                        letterSpacing: 0.5,
                        color: Colors.white.withOpacity(0.75)),
                  ),
                ],
                if (goal != null) ...[
                  const SizedBox(height: 18),
                  _GoalProgress(
                    saved: summary.amount,
                    target: goal.amount,
                    hidden: hidden,
                    fmt: fmt,
                    currency: goal.currency,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  L10n.t('"Every coin sealed in the vault is a stone in the fortress of your future."'),
                  style: bodyStyle(12, color: Colors.white.withOpacity(0.7))
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Per-vault breakdown ───────────────────────────────────────────────────────

/// Shown only when there is more than one vault.
///
/// The hero converts everything to one number; this is where each vault's own
/// currency and exact balance stay visible, so the converted total never hides
/// what is actually held where.
// ── Goal progress bar ────────────────────────────────────────────────────────

class _GoalProgress extends StatelessWidget {
  final double saved;
  final double target;
  final bool hidden;
  final NumberFormat fmt;
  final String currency;
  const _GoalProgress({
    required this.saved,
    required this.target,
    required this.hidden,
    required this.fmt,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target <= 0 ? 1.0 : (saved / target).clamp(0.0, 1.0);
    final achieved = saved >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              L10n.t('GOAL'),
              style: labelStyle(9,
                  letterSpacing: 1.5, color: Colors.white.withOpacity(0.8)),
            ),
            Text(
              hidden
                  ? '••••'
                  : '${(pct * 100).toStringAsFixed(0)}% · '
                      '$currency ${fmt.format(target)}',
              style: labelStyle(9,
                  letterSpacing: 0.8, color: Colors.white.withOpacity(0.9)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hidden ? 0 : pct,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.18),
            valueColor: AlwaysStoppedAnimation(achieved
                ? const Color(0xFFB7E4C7)
                : Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          achieved
              ? L10n.t('Goal reached — the vault is sealed.')
              : hidden
                  ? ''
                  : '$currency ${fmt.format(saved)} ${L10n.t('of')} '
                      '${fmt.format(target)} ${L10n.t('saved')}',
          style: labelStyle(9,
              letterSpacing: 0.5, color: Colors.white.withOpacity(0.75)),
        ),
      ],
    );
  }
}

// ── Per-vault breakdown ───────────────────────────────────────────────────────

class _VaultBreakdown extends StatelessWidget {
  final SavingsSummary summary;
  final FinanceService svc;
  final NumberFormat fmt;
  const _VaultBreakdown({
    required this.summary,
    required this.svc,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MysticColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        children: summary.accounts.asMap().entries.map((e) {
          final acc    = e.value;
          final isLast = e.key == summary.accounts.length - 1;
          final hidden = svc.isAccountHidden(acc.id);
          final bal    = svc.accountBalance(acc.id);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: isLast
                ? null
                : BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: MysticColors.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                  ),
            child: Row(
              children: [
                Icon(acc.icon, size: 18, color: MysticColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    acc.name,
                    style: bodyStyle(14, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  hidden ? '••••••' : '${acc.currency} ${fmt.format(bal)}',
                  style: bodyStyle(14,
                      weight: FontWeight.w700, color: MysticColors.primary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── History list ──────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  final List<Transfer> transfers;
  final FinanceService svc;
  final NumberFormat fmt;
  const _HistoryList({
    required this.transfers,
    required this.svc,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MysticColors.onSurface.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: transfers.asMap().entries.map((e) {
          final t      = e.value;
          final isLast = e.key == transfers.length - 1;
          final isDeposit = svc.isSavingsAccount(t.toAccountId);
          final fromName = svc.findAccount(t.fromAccountId)?.name ?? t.fromAccountId;
          final toName   = svc.findAccount(t.toAccountId)?.name   ?? t.toAccountId;
          final dateFmt  = DateFormat('MMM d, yyyy · h:mm a',
              L10n.instance.isAmharic ? 'am' : null);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: isLast
                ? null
                : BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: MysticColors.outlineVariant.withOpacity(0.2)),
                    ),
                  ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDeposit
                        ? MysticColors.secondary.withOpacity(0.1)
                        : MysticColors.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDeposit
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 18,
                    color: isDeposit
                        ? MysticColors.secondary
                        : MysticColors.tertiary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDeposit
                            ? '${L10n.t('Deposit from')} $fromName'
                            : '${L10n.t('Withdrawal to')} $toName',
                        style: bodyStyle(14, weight: FontWeight.w600),
                      ),
                      Text(
                        dateFmt.format(t.date),
                        style: labelStyle(9, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  // Deposits arrive in the vault's currency; withdrawals
                  // leave in it.
                  '${isDeposit ? '+' : '-'}'
                  '${isDeposit ? t.toCurrency : t.currency} '
                  '${fmt.format(isDeposit ? t.toAmount : t.amount)}',
                  style: bodyStyle(14,
                      weight: FontWeight.w700,
                      color: isDeposit
                          ? MysticColors.secondary
                          : MysticColors.tertiary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.savings_outlined,
                size: 52, color: MysticColors.outlineVariant),
            const SizedBox(height: 12),
            Text(
              L10n.t('No deposits yet'),
              style: headlineStyle(15,
                  italic: true,
                  weight: FontWeight.w600,
                  color: MysticColors.outline),
            ),
            const SizedBox(height: 6),
            Text(
              L10n.t('Tap the button below to make your first deposit.'),
              style:
                  bodyStyle(12, color: MysticColors.onSurfaceVariant.withOpacity(0.6))
                      .copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Deposit FAB ───────────────────────────────────────────────────────────────

class _DepositFab extends StatelessWidget {
  final VoidCallback onTap;
  const _DepositFab({required this.onTap});

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
            Icon(Icons.add, color: MysticColors.onPrimary, size: 22),
            const SizedBox(width: 8),
            Text(L10n.t('DEPOSIT'),
                style: labelStyle(11,
                    letterSpacing: 1.5, color: MysticColors.onPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Deposit sheet ─────────────────────────────────────────────────────────────

class _DepositSheet extends StatefulWidget {
  final FinanceService svc;
  const _DepositSheet({required this.svc});

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _feeCtrl    = TextEditingController();
  String? _fromId;
  String? _toId;

  @override
  void initState() {
    super.initState();
    // Default: first spendable account
    final spendable = widget.svc.spendableAccounts;
    if (spendable.isNotEmpty) _fromId = spendable.first.id;
    // The sheet is only reachable when a vault exists (the FAB is hidden
    // otherwise), so `first` is safe here.
    final vaults = widget.svc.savingsAccounts;
    if (vaults.isNotEmpty) _toId = vaults.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_fromId == null || _toId == null) return;
    // Firestore rules reject a self-transfer, and with offline persistence that
    // rejection surfaces long after the sheet has closed, as a snackbar with no
    // obvious cause. Cheaper to refuse it here.
    if (_fromId == _toId) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;
    final fee = double.tryParse(_feeCtrl.text.replaceAll(',', '')) ?? 0.0;
    if (fee < 0) return;

    final svc          = widget.svc;
    final fromCurrency = svc.currencyOf(_fromId!);
    final toCurrency   = svc.currencyOf(_toId!);
    // Deposits are usually same-currency; when they aren't, fall back to the
    // user's own maintained rate. The Transfer screen is where a specific
    // one-off rate can be entered.
    final rate = svc.conversionRate(fromCurrency, toCurrency);

    reportIfWriteFails(
      ScaffoldMessenger.maybeOf(context),
      svc.addTransfer(
        Transfer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fromAccountId: _fromId!,
          toAccountId: _toId!,
          amount: amount,
          toAmount: amount * rate,
          fee: fee,
          currency: fromCurrency,
          toCurrency: toCurrency,
          rate: rate,
          rateToBase: svc.settings.rateFor(fromCurrency),
          category: TransferCategory.savings,
          date: DateTime.now(),
          note: 'Savings deposit',
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final spendable = widget.svc.spendableAccounts;
    final vaults    = widget.svc.savingsAccounts;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        decoration: BoxDecoration(
          color: MysticColors.surfaceContainerLow,
          borderRadius: const BorderRadius.only(
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
              // Handle
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
              Text(L10n.t('Deposit to Savings'),
                  style: headlineStyle(24, italic: true, weight: FontWeight.w900)),
              const SizedBox(height: 24),

              // A deposit moves money *into* the vault, so it needs a spending
              // account to come from. With only vaults there is nothing to
              // pick, and the picker plus Save would both be inert.
              if (spendable.isEmpty) ...[
                Text(
                  L10n.t('A deposit has to come from somewhere. Add a spending '
                      'account — bank, mobile money or cash — and it will show up '
                      'here.'),
                  style: bodyStyle(13,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.8)),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AddAccountScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: MysticColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(L10n.t('ADD AN ACCOUNT'),
                        style: labelStyle(11,
                            letterSpacing: 1.5,
                            color: MysticColors.onPrimary)),
                  ),
                ),
              ] else ...[

              // From account
              Text(L10n.t('FROM ACCOUNT'),
                  style: labelStyle(9,
                      letterSpacing: 1.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: spendable.any((a) => a.id == _fromId) ? _fromId : null,
                onChanged: (v) { if (v != null) setState(() => _fromId = v); },
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
                items: spendable
                    .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Which vault the money lands in. Only a real choice once there
              // is more than one — otherwise it's a dropdown with one option.
              if (vaults.length > 1) ...[
                Text(L10n.t('TO VAULT'),
                    style: labelStyle(9,
                        letterSpacing: 1.5,
                        color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: vaults.any((a) => a.id == _toId) ? _toId : null,
                  onChanged: (v) { if (v != null) setState(() => _toId = v); },
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
                  items: vaults
                      .map((a) => DropdownMenuItem(
                          value: a.id, child: Text('${a.name} · ${a.currency}')))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Amount
              Text(L10n.t('AMOUNT'),
                  style: labelStyle(9,
                      letterSpacing: 1.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Deposits are entered in the source account's currency.
                  Text(
                      _fromId == null
                          ? widget.svc.baseCurrency
                          : widget.svc.currencyOf(_fromId!),
                      style: headlineStyle(22,
                          italic: false,
                          weight: FontWeight.w700,
                          color: MysticColors.primary.withOpacity(0.7))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                      style: headlineStyle(36,
                          italic: false, weight: FontWeight.w900),
                      autofocus: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: headlineStyle(36,
                                italic: false, weight: FontWeight.w900)
                            .copyWith(
                                color: MysticColors.onSurface.withOpacity(0.15)),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return L10n.t('Enter an amount');
                        }
                        final p = double.tryParse(v.replaceAll(',', ''));
                        if (p == null || p <= 0) {
                          return L10n.t('Enter a valid amount');
                        }
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

              // Fee (optional) — mirror of the Transfer screen's fee field.
              // A deposit can carry a bank/service charge just like any other
              // transfer; leaving it out would understate what left the source.
              Text(L10n.t('TRANSFER FEE / SERVICE CHARGE (OPTIONAL)'),
                  style: labelStyle(9,
                      letterSpacing: 1.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _fromId == null
                        ? widget.svc.baseCurrency
                        : widget.svc.currencyOf(_fromId!),
                    style: bodyStyle(16,
                        weight: FontWeight.w600,
                        color: MysticColors.tertiary.withOpacity(0.7)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _feeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                      style: bodyStyle(20,
                          weight: FontWeight.w700,
                          color: MysticColors.tertiary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: L10n.t('0.00  (bank/service fee)'),
                        hintStyle: bodyStyle(14,
                            color: MysticColors.onSurface.withOpacity(0.2)),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  MysticColors.outlineVariant.withOpacity(0.3),
                              width: 1),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: MysticColors.tertiary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Save
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
                      L10n.t('Seal in Vault'),
                      style: headlineStyle(18,
                          italic: true,
                          weight: FontWeight.w900,
                          color: MysticColors.onPrimary),
                    ),
                  ),
                ),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
