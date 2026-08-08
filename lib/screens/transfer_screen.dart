import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/empty_state_card.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';
import '../models/transfer_model.dart';

/// Screen to transfer money between two accounts.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _feeCtrl    = TextEditingController();
  final _noteCtrl   = TextEditingController();
  final _rateCtrl   = TextEditingController();

  String? _fromId;
  String? _toId;
  TransferCategory? _category;

  @override
  void initState() {
    super.initState();
    // Redraw the conversion preview as the user types.
    _amountCtrl.addListener(_onConversionInputChanged);
    _rateCtrl.addListener(_onConversionInputChanged);
  }

  void _onConversionInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onConversionInputChanged);
    _rateCtrl.removeListener(_onConversionInputChanged);
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
  double get _fee => double.tryParse(_feeCtrl.text.replaceAll(',', '')) ?? 0.0;
  double get _rate => double.tryParse(_rateCtrl.text.replaceAll(',', '')) ?? 0.0;

  /// Swaps the two selected accounts. The entered rate no longer applies once
  /// direction flips, so it is cleared rather than silently inverted.
  void _swap() {
    setState(() {
      final from = _fromId;
      _fromId = _toId;
      _toId   = from;
      _rateCtrl.clear();
    });
  }

  bool _saving = false;

  void _save() {
    // Guards against a double-tap recording the transfer twice.
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_fromId == null || _toId == null) {
      _showError('Please select both accounts.');
      return;
    }
    if (_fromId == _toId) {
      _showError('From and To accounts must be different.');
      return;
    }
    final amount = _amount;
    if (amount <= 0) {
      _showError('Enter a valid amount greater than zero.');
      return;
    }
    final fee = _fee;

    final svc  = context.read<FinanceService>();
    final from = svc.findAccount(_fromId!);
    final to   = svc.findAccount(_toId!);
    if (from == null || to == null) {
      _showError('That account is no longer available.');
      return;
    }

    final crossCurrency = from.currency != to.currency;
    final rate = crossCurrency ? _rate : 1.0;
    if (crossCurrency && rate <= 0) {
      _showError(
          'Enter the rate you got: 1 ${from.currency} = ? ${to.currency}');
      return;
    }

    final available = svc.accountBalance(_fromId!);
    if (amount + fee > available) {
      final fmt = NumberFormat('#,##0.00');
      _showError('Insufficient balance. Available: '
          '${from.currency} ${fmt.format(available)}');
      return;
    }

    setState(() => _saving = true);

    // Capture before the pop so no BuildContext is used afterwards.
    final messenger = ScaffoldMessenger.of(context);
    reportIfWriteFails(
      messenger,
      svc.addTransfer(
        Transfer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fromAccountId: _fromId!,
          toAccountId: _toId!,
          amount: amount,
          toAmount: amount * rate,
          fee: fee,
          currency: from.currency,
          toCurrency: to.currency,
          rate: rate,
          // Snapshot so fee reporting stays stable if rates change later.
          rateToBase: svc.settings.rateFor(from.currency),
          category: _category,
          date: DateTime.now(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        ),
      ),
    );

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Transfer recorded — gold moved between vaults.',
          style: bodyStyle(13, color: Colors.white),
        ),
        backgroundColor: MysticColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: bodyStyle(13, color: Colors.white)),
        backgroundColor: MysticColors.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc      = context.watch<FinanceService>();
    final accounts = svc.accounts; // all accounts including savings

    // Initialise defaults on first build
    if (_fromId == null && accounts.length >= 2) {
      _fromId = accounts[0].id;
      _toId   = accounts[1].id;
    }

    final from = _fromId == null ? null : svc.findAccount(_fromId!);
    final to   = _toId   == null ? null : svc.findAccount(_toId!);
    final fromCurrency = from?.currency ?? svc.baseCurrency;
    final toCurrency   = to?.currency   ?? svc.baseCurrency;
    final crossCurrency = fromCurrency != toCurrency;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
            'Transfer Funds',
            style: headlineStyle(22, italic: true, weight: FontWeight.w700),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.5),
            child: Container(
                height: 1.5,
                color: MysticColors.outlineVariant.withOpacity(0.5)),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Label ──────────────────────────────────────────────
                  Text(
                    'MOVE GOLD BETWEEN VAULTS',
                    style: labelStyle(10,
                        letterSpacing: 2.0,
                        color: MysticColors.onSurfaceVariant.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transfer',
                    style: headlineStyle(40, italic: true, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 32),

                  // A transfer needs somewhere to come from *and* go to. With
                  // fewer than two accounts the pickers cannot be satisfied and
                  // Save would only ever produce a validation snackbar.
                  if (accounts.length < 2)
                    NoAccountsCard(
                      headline: accounts.isEmpty
                          ? 'No vaults to move between'
                          : 'Only one vault so far',
                      body: 'A transfer moves gold from one account to another, '
                          'so it needs at least two. You have '
                          '${accounts.length}.',
                    )
                  else
                  // ── Form card ──────────────────────────────────────────
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
                        // Amount
                        const _SectionLabel('AMOUNT'),
                        const SizedBox(height: 8),
                        _AmountRow(
                          controller: _amountCtrl,
                          currency: fromCurrency,
                        ),
                        const SizedBox(height: 16),

                        // Exchange rate — only when the two sides differ
                        if (crossCurrency) ...[
                          _ExchangeRateRow(
                            controller: _rateCtrl,
                            fromCurrency: fromCurrency,
                            toCurrency: toCurrency,
                            amount: _amount,
                            rate: _rate,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Fee (optional)
                        const _SectionLabel(
                            'TRANSFER FEE / SERVICE CHARGE (OPTIONAL)'),
                        const SizedBox(height: 8),
                        _FeeField(
                          controller: _feeCtrl,
                          currency: fromCurrency,
                        ),
                        const SizedBox(height: 28),
                        const _Divider(),

                        // From / To selectors
                        const SizedBox(height: 24),
                        _AccountFlowRow(
                          accounts: accounts,
                          fromId: _fromId,
                          toId: _toId,
                          onFromChanged: (id) => setState(() => _fromId = id),
                          onToChanged:   (id) => setState(() => _toId   = id),
                          onSwap: _swap,
                        ),
                        const SizedBox(height: 28),
                        const _Divider(),

                        // Category
                        const SizedBox(height: 24),
                        const _SectionLabel('WHAT IS THIS FOR? (OPTIONAL)'),
                        const SizedBox(height: 12),
                        _CategoryPicker(
                          selected: _category,
                          onChanged: (c) => setState(
                              () => _category = _category == c ? null : c),
                        ),
                        const SizedBox(height: 28),
                        const _Divider(),

                        // Note
                        const SizedBox(height: 24),
                        const _SectionLabel('NOTE (OPTIONAL)'),
                        const SizedBox(height: 8),
                        _NoteField(controller: _noteCtrl),
                        const SizedBox(height: 32),

                        // Save
                        _SaveButton(onTap: _save, busy: _saving),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'CANCEL',
                        style: labelStyle(11,
                            letterSpacing: 1.5,
                            color: MysticColors.onSurfaceVariant
                                .withOpacity(0.5)),
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
}

// ── Amount row ────────────────────────────────────────────────────────────────

class _AmountRow extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  const _AmountRow({required this.controller, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            style: headlineStyle(44, italic: false, weight: FontWeight.w900),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0.00',
              hintStyle: headlineStyle(44, italic: false, weight: FontWeight.w900)
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
    );
  }
}

// ── From / To selector ────────────────────────────────────────────────────────

class _AccountFlowRow extends StatelessWidget {
  final List<Account> accounts;
  final String? fromId;
  final String? toId;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;
  final VoidCallback onSwap;

  const _AccountFlowRow({
    required this.accounts,
    required this.fromId,
    required this.toId,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('FROM'),
        const SizedBox(height: 8),
        _AccountDropdown(
          accounts: accounts,
          selectedId: fromId,
          onChanged: onFromChanged,
        ),
        const SizedBox(height: 20),
        // Arrow connector doubles as the swap control.
        Center(
          child: Tooltip(
            message: 'Swap From and To',
            child: GestureDetector(
              onTap: onSwap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MysticColors.primaryContainer.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: MysticColors.primary.withOpacity(0.25)),
                ),
                child: const Icon(Icons.swap_vert,
                    color: MysticColors.primary, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _SectionLabel('TO'),
        const SizedBox(height: 8),
        _AccountDropdown(
          accounts: accounts,
          selectedId: toId,
          onChanged: onToChanged,
        ),
      ],
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const _AccountDropdown({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: accounts.any((a) => a.id == selectedId) ? selectedId : null,
      onChanged: (v) { if (v != null) onChanged(v); },
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.only(bottom: 8),
        isDense: true,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: MysticColors.outlineVariant.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: MysticColors.primary, width: 1.5),
        ),
      ),
      style: bodyStyle(15, weight: FontWeight.w600),
      dropdownColor: MysticColors.surfaceContainerLow,
      items: accounts
          .map((a) => DropdownMenuItem(
                value: a.id,
                child: Row(
                  children: [
                    Icon(a.icon, size: 16, color: MysticColors.primary),
                    const SizedBox(width: 8),
                    Text(a.name),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ── Fee field ─────────────────────────────────────────────────────────────────

class _FeeField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  const _FeeField({required this.controller, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(currency,
            style: bodyStyle(16,
                weight: FontWeight.w600,
                color: MysticColors.tertiary.withOpacity(0.7))),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            style: bodyStyle(20, weight: FontWeight.w700,
                color: MysticColors.tertiary),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0.00  (bank/service fee)',
              hintStyle: bodyStyle(14, color: MysticColors.onSurface.withOpacity(0.2)),
              contentPadding: EdgeInsets.zero,
              isDense: true,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: MysticColors.outlineVariant.withOpacity(0.3), width: 1),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: MysticColors.tertiary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Exchange rate row ─────────────────────────────────────────────────────────

/// Shown only when the two accounts hold different currencies. The user types
/// the rate they actually got at that moment; it is stored on the transfer so
/// the record reflects reality rather than a later market rate.
class _ExchangeRateRow extends StatelessWidget {
  final TextEditingController controller;
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final double rate;

  const _ExchangeRateRow({
    required this.controller,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final converted = amount * rate;
    final ready = amount > 0 && rate > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MysticColors.primaryContainer.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: MysticColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange,
                  size: 14, color: MysticColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('RATE AT THIS TIME',
                    style: labelStyle(9,
                        letterSpacing: 1.5, color: MysticColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('1 $fromCurrency  =',
                  style: bodyStyle(14, weight: FontWeight.w600)),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  style: bodyStyle(18,
                      weight: FontWeight.w800, color: MysticColors.primary),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0.00',
                    hintStyle: bodyStyle(18,
                        weight: FontWeight.w800,
                        color: MysticColors.onSurface.withOpacity(0.2)),
                    contentPadding: const EdgeInsets.only(bottom: 6),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: MysticColors.primary.withOpacity(0.35)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: MysticColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(toCurrency, style: bodyStyle(14, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ready
                ? '≈ $toCurrency ${fmt.format(converted)} will arrive'
                : 'Enter the rate to see what arrives',
            style: bodyStyle(13,
                    weight: ready ? FontWeight.w700 : FontWeight.w400,
                    color: ready
                        ? MysticColors.secondary
                        : MysticColors.onSurfaceVariant.withOpacity(0.6))
                .copyWith(fontStyle: ready ? null : FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ── Category picker ───────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final TransferCategory? selected;
  final ValueChanged<TransferCategory> onChanged;

  const _CategoryPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TransferCategory.values.map((c) {
        final active = c == selected;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? MysticColors.primary
                  : MysticColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? MysticColors.primary
                    : MysticColors.outlineVariant.withOpacity(0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon,
                    size: 14,
                    color: active
                        ? MysticColors.onPrimary
                        : MysticColors.onSurfaceVariant.withOpacity(0.6)),
                const SizedBox(width: 6),
                Text(
                  c.label,
                  style: labelStyle(10,
                      letterSpacing: 0.4,
                      color: active
                          ? MysticColors.onPrimary
                          : MysticColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Note field ────────────────────────────────────────────────────────────────

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 2,
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
              color: MysticColors.outlineVariant.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: MysticColors.primary, width: 1.5),
        ),
      ),
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
                  'Execute Transfer',
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

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: labelStyle(9,
          letterSpacing: 1.5,
          color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: MysticColors.outlineVariant.withOpacity(0.2));
  }
}
