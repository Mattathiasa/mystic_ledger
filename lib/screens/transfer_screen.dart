import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/app_theme.dart';
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

  String? _fromId;
  String? _toId;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_fromId == null || _toId == null) {
      _showError('Please select both accounts.');
      return;
    }
    if (_fromId == _toId) {
      _showError('From and To accounts must be different.');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      _showError('Enter a valid amount greater than zero.');
      return;
    }
    final fee = double.tryParse(_feeCtrl.text.replaceAll(',', '')) ?? 0.0;

    final svc = context.read<FinanceService>();
    final available = svc.accountBalance(_fromId!);
    if (amount + fee > available) {
      final fmt = NumberFormat('#,##0.00');
      _showError(
          'Insufficient balance. Available: ETB ${fmt.format(available)}');
      return;
    }

    svc.addTransfer(
      Transfer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromAccountId: _fromId!,
        toAccountId: _toId!,
        amount: amount,
        fee: fee,
        date: DateTime.now(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
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
                        _SectionLabel('AMOUNT'),
                        const SizedBox(height: 8),
                        _AmountRow(controller: _amountCtrl),
                        const SizedBox(height: 16),

                        // Fee (optional)
                        _SectionLabel('TRANSFER FEE (OPTIONAL)'),
                        const SizedBox(height: 8),
                        _FeeField(controller: _feeCtrl),
                        const SizedBox(height: 28),
                        _Divider(),

                        // From / To selectors
                        const SizedBox(height: 24),
                        _AccountFlowRow(
                          accounts: accounts,
                          fromId: _fromId,
                          toId: _toId,
                          onFromChanged: (id) => setState(() => _fromId = id),
                          onToChanged:   (id) => setState(() => _toId   = id),
                        ),
                        const SizedBox(height: 28),
                        _Divider(),

                        // Note
                        const SizedBox(height: 24),
                        _SectionLabel('NOTE (OPTIONAL)'),
                        const SizedBox(height: 8),
                        _NoteField(controller: _noteCtrl),
                        const SizedBox(height: 32),

                        // Save
                        _SaveButton(onTap: _save),
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
  const _AmountRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ETB',
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

  const _AccountFlowRow({
    required this.accounts,
    required this.fromId,
    required this.toId,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('FROM'),
        const SizedBox(height: 8),
        _AccountDropdown(
          accounts: accounts,
          selectedId: fromId,
          onChanged: onFromChanged,
        ),
        const SizedBox(height: 20),
        // Arrow connector
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MysticColors.primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward,
                color: MysticColors.primary, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        _SectionLabel('TO'),
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
  const _FeeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('ETB',
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
  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: MysticColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MysticColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
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
