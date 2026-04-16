import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_theme.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';

/// Screen to add a new bank account.
/// Telebirr, Cash and Savings are fixed — users can only add bank accounts here.
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  AccountType _type = AccountType.bank;

  // Common Ethiopian banks for quick selection
  static const _suggestions = [
    'CBE', 'Awash Bank', 'Dashen Bank', 'Abyssinia Bank',
    'Hibret Bank', 'Zemen Bank', 'Nib Bank', 'Oromia Bank',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final id = '${_type.name}_${DateTime.now().millisecondsSinceEpoch}';
    context.read<FinanceService>().addAccount(
          Account(
            id: id,
            name: _nameCtrl.text.trim(),
            type: _type,
          ),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_nameCtrl.text.trim()} added to your vaults.',
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
          backgroundColor: const Color(0xFFFDFCF0),
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
                            focusedBorder: const UnderlineInputBorder(
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
    (AccountType.bank,   'Bank',         Icons.account_balance_outlined),
    (AccountType.mobile, 'Mobile',       Icons.account_balance_wallet_outlined),
    (AccountType.cash,   'Cash',         Icons.payments_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (type, label, icon) = opt;
        final active = selected == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: opt == _options.last ? 0 : 8,
            ),
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
                              : MysticColors.onSurfaceVariant.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
