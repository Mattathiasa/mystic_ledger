import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';
import '../models/currency_model.dart';

/// Screen to add an account of any kind — bank, mobile money, cash or savings.
///
/// Nothing is created for the user at sign-up, so this is the only way an
/// account comes into existence. [initialType] lets a caller land the selector
/// on the kind it is asking for (the Savings screen's empty state wants a
/// vault, not a bank).
class AddAccountScreen extends StatefulWidget {
  final AccountType initialType;

  const AddAccountScreen({super.key, this.initialType = AccountType.bank});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  late AccountType _type = widget.initialType;
  // Defaults to the user's base currency; changeable here because after the
  // account has any entries the currency is locked (amounts are stored in it).
  String? _pickedCurrency;
  String get _currency =>
      _pickedCurrency ?? context.read<FinanceService>().baseCurrency;

  // Common Ethiopian banks for quick selection
  static const _suggestions = [
    'CBE', 'Awash Bank', 'Dashen Bank', 'Abyssinia Bank',
    'Hibret Bank', 'Zemen Bank', 'Nib Bank', 'Oromia Bank',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final svc  = context.read<FinanceService>();
    final id   = '${_type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final name = _nameCtrl.text.trim();

    // Optional savings goal; only collected for savings vaults.
    final targetText = _targetCtrl.text.trim().replaceAll(',', '');
    final target =
        targetText.isEmpty ? null : double.tryParse(targetText);

    // Captured before the pop — this screen is gone by the time a rejection
    // comes back from the server.
    final messenger = ScaffoldMessenger.of(context);
    reportIfWriteFails(
      messenger,
      svc.addAccount(
        Account(
          id: id,
          name: name,
          type: _type,
          currency: _currency,
          targetAmount: _type == AccountType.savings ? target : null,
        ),
      ),
    );

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$name added to your vaults.',
          style: bodyStyle(13, color: Colors.white),
        ),
        backgroundColor: MysticColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
            'Add Account',
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
                  Text(
                    'OPEN NEW VAULT',
                    style: labelStyle(10,
                        letterSpacing: 2.0,
                        color: MysticColors.onSurfaceVariant.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 8),
                  Text('New Account',
                      style: headlineStyle(40,
                          italic: true, weight: FontWeight.w900)),
                  const SizedBox(height: 32),

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
                        // Account type selector
                        Text('ACCOUNT TYPE',
                            style: labelStyle(9,
                                letterSpacing: 1.5,
                                color: MysticColors.onSurfaceVariant
                                    .withOpacity(0.6))),
                        const SizedBox(height: 12),
                        _TypeSelector(
                          selected: _type,
                          onChanged: (t) => setState(() => _type = t),
                        ),
                        const SizedBox(height: 28),
                        Container(
                            height: 1,
                            color: MysticColors.outlineVariant.withOpacity(0.2)),
                        const SizedBox(height: 24),

                        // Currency — set here because it is locked once the
                        // account has any entries recorded against it.
                        Text('CURRENCY',
                            style: labelStyle(9,
                                letterSpacing: 1.5,
                                color: MysticColors.onSurfaceVariant
                                    .withOpacity(0.6))),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _currency,
                          onChanged: (v) =>
                              setState(() => _pickedCurrency = v),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.only(bottom: 8),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: MysticColors.outlineVariant
                                      .withOpacity(0.3),
                                  width: 1.5),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: MysticColors.primary, width: 1.5),
                            ),
                          ),
                          style: bodyStyle(16, weight: FontWeight.w600),
                          dropdownColor: MysticColors.surfaceContainerLow,
                          items: Currency.registry
                              .map((c) => DropdownMenuItem(
                                    value: c.code,
                                    child: Text('${c.code} · ${c.name}'),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 28),
                        Container(
                            height: 1,
                            color: MysticColors.outlineVariant.withOpacity(0.2)),
                        const SizedBox(height: 24),

                        // Savings goal
                        if (_type == AccountType.savings) ...[
                          Text('SAVINGS GOAL (OPTIONAL)',
                              style: labelStyle(9,
                                  letterSpacing: 1.5,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.6))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('$_currency ',
                                  style: bodyStyle(18,
                                      weight: FontWeight.w700,
                                      color: MysticColors.primary
                                          .withOpacity(0.7))),
                              Expanded(
                                child: TextFormField(
                                  controller: _targetCtrl,
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d,.]')),
                                  ],
                                  style: bodyStyle(16, weight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'e.g. 50000 for a laptop',
                                    hintStyle:
                                        bodyStyle(16, weight: FontWeight.w600)
                                            .copyWith(
                                                color: MysticColors.onSurface
                                                    .withOpacity(0.25)),
                                    contentPadding:
                                        const EdgeInsets.only(bottom: 8),
                                    isDense: true,
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MysticColors.outlineVariant
                                              .withOpacity(0.3),
                                          width: 1.5),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MysticColors.primary,
                                          width: 1.5),
                                    ),
                                  ),
                                  validator: (v) {
                                    final t = v?.trim().replaceAll(',', '');
                                    if (t == null || t.isEmpty) return null;
                                    final p = double.tryParse(t);
                                    if (p == null || p <= 0) {
                                      return 'Enter a valid goal';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                              height: 1,
                              color: MysticColors.outlineVariant
                                  .withOpacity(0.2)),
                          const SizedBox(height: 24),
                        ],

                        // Account name
                        Text('ACCOUNT NAME',
                            style: labelStyle(9,
                                letterSpacing: 1.5,
                                color: MysticColors.onSurfaceVariant
                                    .withOpacity(0.6))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameCtrl,
                          style: bodyStyle(20, weight: FontWeight.w600),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'e.g. CBE, Awash Bank...',
                            hintStyle: bodyStyle(20, weight: FontWeight.w600)
                                .copyWith(
                                    color: MysticColors.onSurface
                                        .withOpacity(0.25)),
                            contentPadding: const EdgeInsets.only(bottom: 8),
                            isDense: true,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: MysticColors.outlineVariant
                                      .withOpacity(0.3),
                                  width: 1.5),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: MysticColors.primary, width: 1.5),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter an account name'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Quick-pick suggestions
                        if (_type == AccountType.bank) ...[
                          Text('QUICK PICK',
                              style: labelStyle(9,
                                  letterSpacing: 1.5,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.5))),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _suggestions.map((s) {
                              return GestureDetector(
                                onTap: () {
                                  _nameCtrl.text = s;
                                  _nameCtrl.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(offset: s.length),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: MysticColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: MysticColors.outlineVariant
                                            .withOpacity(0.2)),
                                  ),
                                  child: Text(s,
                                      style: labelStyle(10,
                                          letterSpacing: 0.5)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 28),
                          Container(
                              height: 1,
                              color: MysticColors.outlineVariant
                                  .withOpacity(0.2)),
                          const SizedBox(height: 24),
                        ],

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
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Open Vault',
                                style: headlineStyle(20,
                                    italic: true,
                                    weight: FontWeight.w900,
                                    color: MysticColors.onPrimary),
                              ),
                            ),
                          ),
                        ),
                      ],
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

// ── Type selector ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final AccountType selected;
  final ValueChanged<AccountType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  static const _options = [
    (AccountType.bank,    'Bank',    Icons.account_balance_outlined),
    (AccountType.mobile,  'Mobile',  Icons.account_balance_wallet_outlined),
    (AccountType.cash,    'Cash',    Icons.payments_outlined),
    (AccountType.savings, 'Savings', Icons.savings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    // 2×2 rather than a single row: four tiles across a 360dp screen leaves
    // ~58dp each, and "SAVINGS" overflows that below about 340dp.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((opt) {
            final (type, label, icon) = opt;
            final active = selected == type;
            return SizedBox(
              width: tileWidth,
              child: GestureDetector(
                onTap: () => onChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: active
                        ? MysticColors.primaryContainer.withOpacity(0.25)
                        : MysticColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? MysticColors.primaryContainer.withOpacity(0.6)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(icon,
                          size: 22,
                          color: active
                              ? MysticColors.primary
                              : MysticColors.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(height: 6),
                      Text(
                        label.toUpperCase(),
                        style: labelStyle(9,
                            letterSpacing: 1.0,
                            color: active
                                ? MysticColors.primary
                                : MysticColors.onSurfaceVariant
                                    .withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
