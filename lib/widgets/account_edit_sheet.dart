import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';
import '../models/currency_model.dart';
import 'app_theme.dart';
import 'app_feedback.dart';

/// Opens the account editor as a modal sheet.
///
/// The sheet's presentation lives here rather than at each call site so the
/// Journal and the Finance Hub cannot drift apart on how it appears.
Future<void> showAccountEditSheet(
  BuildContext context,
  FinanceService svc,
  Account account,
) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AccountEditSheet(svc: svc, account: account),
    );

/// Rename an account, change its currency, or remove it.
///
/// Removing is a soft-delete: the account disappears from the home screen and
/// pickers but its history is preserved and it can be restored — which is what
/// makes it safe to offer on every account, savings vaults included.
class AccountEditSheet extends StatefulWidget {
  final FinanceService svc;
  final Account account;
  const AccountEditSheet({super.key, required this.svc, required this.account});

  @override
  State<AccountEditSheet> createState() => _AccountEditSheetState();
}

class _AccountEditSheetState extends State<AccountEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account.name);
    _currency = widget.account.currency;
    _targetCtrl = TextEditingController(
      text: widget.account.targetAmount == null
          ? ''
          : widget.account.targetAmount!.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acc      = widget.account;
    final svc      = widget.svc;
    final locked   = svc.accountHasActivity(acc.id);
    final bottom   = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: MysticColors.appBarBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MysticColors.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Edit Account',
              style: headlineStyle(26, italic: true, weight: FontWeight.w900)),
          const SizedBox(height: 24),

          Text('NAME',
              style: labelStyle(10,
                  letterSpacing: 1.5,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            style: bodyStyle(16, weight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: MysticColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 20),
          Text('CURRENCY',
              style: labelStyle(10,
                  letterSpacing: 1.5,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _currency,
            // Existing amounts are stored in this currency; switching now
            // would silently reinterpret every one of them.
            onChanged: locked
                ? null
                : (v) => setState(() => _currency = v ?? _currency),
            decoration: InputDecoration(
              filled: true,
              fillColor: MysticColors.surfaceContainerLow
                  .withOpacity(locked ? 0.5 : 1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          if (locked) ...[
            const SizedBox(height: 6),
            Text(
              'Currency is locked — this account already has entries recorded '
              'in $_currency. Create a new account for a different currency.',
              style: labelStyle(10,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
            ),
          ],

          // Savings vaults can carry a goal; the hero card shows progress.
          if (acc.type == AccountType.savings) ...[
            const SizedBox(height: 20),
            Text('SAVINGS GOAL (OPTIONAL)',
                style: labelStyle(10,
                    letterSpacing: 1.5,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$_currency ',
                    style: bodyStyle(16,
                        weight: FontWeight.w700,
                        color: MysticColors.primary.withOpacity(0.7))),
                Expanded(
                  child: TextField(
                    controller: _targetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    style: bodyStyle(16, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: MysticColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      hintText: 'Target amount',
                      hintStyle: bodyStyle(16,
                          color: MysticColors.onSurface.withOpacity(0.25)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'How much are you saving up to? Leave blank to remove the goal.',
              style: labelStyle(10,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
            ),
          ],

          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: MysticColors.primary,
              foregroundColor: MysticColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Save Changes',
                style: headlineStyle(16,
                    italic: false,
                    weight: FontWeight.w700,
                    color: MysticColors.onPrimary)),
          ),

          // Every account is removable, savings vaults included. They used to
          // be exempt because other screens addressed the vault by a fixed id;
          // savings is now found by account type, so nothing breaks when the
          // last one goes — the Savings screen just offers to open a new one.
          const SizedBox(height: 8),
          TextButton(
            onPressed: _confirmRemove,
            child: Text('Remove this account',
                style: bodyStyle(13, color: MysticColors.tertiary)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final svc       = widget.svc;
    final acc       = widget.account;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name      = _nameCtrl.text.trim();

    // These are not awaited: the local write applies instantly and awaiting
    // would stall the sheet for as long as the device is offline.
    if (name.isNotEmpty && name != acc.name) {
      reportIfWriteFails(messenger, svc.renameAccount(acc.id, name));
    }
    if (_currency != acc.currency) {
      // Rejects with a StateError when the account already has entries;
      // friendlyWriteError surfaces that message as-is.
      reportIfWriteFails(
          messenger, svc.changeAccountCurrency(acc.id, _currency));
    }
    if (acc.type == AccountType.savings) {
      final text = _targetCtrl.text.trim().replaceAll(',', '');
      final parsed = text.isEmpty ? null : double.tryParse(text);
      if (parsed == null && text.isNotEmpty) return; // invalid number: abort
      if (parsed != acc.targetAmount) {
        reportIfWriteFails(
            messenger, svc.setAccountTarget(acc.id, parsed));
      }
    }
    navigator.pop();
  }

  Future<void> _confirmRemove() async {
    final svc       = widget.svc;
    final acc       = widget.account;
    final balance   = svc.accountBalance(acc.id);
    final fmt       = NumberFormat('#,##0.00');
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MysticColors.surfaceContainerLow,
        title: Text('Remove ${acc.name}?',
            style: headlineStyle(18, italic: true, weight: FontWeight.w700)),
        content: Text(
          balance != 0
              // Removing an account holding money would make the total drop.
              ? 'This account still holds ${acc.currency} ${fmt.format(balance)}. '
                  'Removing it hides that balance from your totals. Its history '
                  'is preserved and you can restore it at any time.'
              : 'This hides "${acc.name}" from your home screen and pickers. '
                  'Its history is preserved and you can restore it at any time.',
          style: bodyStyle(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Remove',
                style: bodyStyle(14,
                    weight: FontWeight.w700, color: MysticColors.tertiary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    reportIfWriteFails(messenger, svc.deactivateAccount(acc.id));
    navigator.pop();
  }
}
