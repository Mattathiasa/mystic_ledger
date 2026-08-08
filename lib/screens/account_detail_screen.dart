import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/account_edit_sheet.dart';
import '../widgets/app_feedback.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';
import '../models/transaction.dart';
import 'journal_screen.dart'; // entrySlideUpRoute
import 'new_entry_screen.dart';
import 'transfer_history_screen.dart';

/// A single account's full record: running balance, every transaction and
/// transfer that touched it, and the account editor behind its own button.
///
/// Previously tapping an account card opened the edit sheet directly, so there
/// was no way to see what had happened to one account without scanning the
/// whole ledger. The card now lands here; editing stays one tap away.
class AccountDetailScreen extends StatelessWidget {
  final Account account;
  const AccountDetailScreen({super.key, required this.account});

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
        title: Text(account.name,
            style: headlineStyle(22, italic: true, weight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Edit account',
            icon: const Icon(Icons.more_horiz),
            color: MysticColors.onSurface,
            onPressed: () => showAccountEditSheet(
                context, context.read<FinanceService>(), account),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
              height: 1.5, color: MysticColors.outlineVariant.withOpacity(0.5)),
        ),
      ),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          if (svc.isLoading) {
            return Center(
                child: CircularProgressIndicator(color: MysticColors.primary));
          }

          final fmt = NumberFormat('#,##0.00');
          final hidden = svc.isAccountHidden(account.id);
          final balance = svc.accountBalance(account.id);
          final txns = svc.transactions
              .where((t) => t.accountId == account.id)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final transfers = svc.transfersForAccount(account.id)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
            children: [
              // ── Balance hero ─────────────────────────────────────────
              Transform.rotate(
                angle: -0.009,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: MysticColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: MysticColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(account.icon,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.typeLabel.toUpperCase(),
                                style: labelStyle(9,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withOpacity(0.7))),
                            const SizedBox(height: 4),
                            Text(
                              hidden
                                  ? '••••••'
                                  : '${account.currency} ${fmt.format(balance)}',
                              style: headlineStyle(30,
                                  italic: false,
                                  weight: FontWeight.w900,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => svc.toggleAccountVisibility(account.id),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!account.isActive) ...[
                const SizedBox(height: 12),
                Text(
                  'This account is hidden from the home screen and pickers. '
                  'Edit it above to restore it.',
                  style: bodyStyle(12, color: MysticColors.tertiary)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ],

              const SizedBox(height: 28),
              _SectionHeader(
                title: 'TRANSACTIONS',
                count: txns.length,
                color: MysticColors.primary,
              ),
              const SizedBox(height: 12),
              if (txns.isEmpty)
                _EmptyRow(message: 'No entries recorded against this vault.')
              else
                Container(
                  decoration: BoxDecoration(
                    color: MysticColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: MysticColors.outlineVariant.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: txns.asMap().entries.map((e) {
                      final t = e.value;
                      final isLast = e.key == txns.length - 1;
                      return Dismissible(
                        key: ValueKey('tx_${t.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: MysticColors.tertiary.withOpacity(0.15),
                          child: Icon(Icons.delete_outline,
                              color: MysticColors.tertiary, size: 24),
                        ),
                        confirmDismiss: (_) async =>
                            await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: MysticColors.surfaceContainerLow,
                            title: Text('Delete entry?',
                                style: headlineStyle(18,
                                    italic: true, weight: FontWeight.w700)),
                            content: Text('Remove "${t.title}"?',
                                style: bodyStyle(14)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel',
                                    style: bodyStyle(14,
                                        color: MysticColors.onSurfaceVariant)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete',
                                    style: bodyStyle(14,
                                        weight: FontWeight.w700,
                                        color: MysticColors.tertiary)),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (_) => reportIfWriteFails(
                            ScaffoldMessenger.maybeOf(context),
                            svc.deleteTransaction(t.id)),
                        child: _EntryRow(
                          title: t.title,
                          subtitle:
                              '${DateFormat('MMM d, yyyy · h:mm a').format(t.date)}'
                              '${t.fee > 0 ? ' · fee ${fmt.format(t.fee)}' : ''}'
                              '${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}',
                          amount: t.amount,
                          currency: t.currency,
                          isIncome: t.type == TransactionType.income,
                          onTap: () => Navigator.of(context).push(
                            entrySlideUpRoute(NewEntryScreen(existing: t)),
                          ),
                          isLast: isLast,
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 28),
              _SectionHeader(
                title: 'TRANSFERS',
                count: transfers.length,
                color: MysticColors.secondary,
              ),
              const SizedBox(height: 12),
              if (transfers.isEmpty)
                _EmptyRow(message: 'No money moved in or out of this vault.')
              else
                Container(
                  decoration: BoxDecoration(
                    color: MysticColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: MysticColors.outlineVariant.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: transfers.asMap().entries.map((e) {
                      final t = e.value;
                      final isLast = e.key == transfers.length - 1;
                      final isIn = t.toAccountId == account.id;
                      final otherId = isIn ? t.fromAccountId : t.toAccountId;
                      final other = svc.findAccount(otherId)?.name ?? otherId;
                      final amount = isIn ? t.toAmount : t.amount;
                      final cur = isIn ? t.toCurrency : t.currency;

                      return _EntryRow(
                        title: isIn ? 'Received from $other' : 'Sent to $other',
                        subtitle:
                            '${DateFormat('MMM d, yyyy · h:mm a').format(t.date)}'
                            '${t.fee > 0 ? ' · fee ${fmt.format(t.fee)}' : ''}'
                            '${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}',
                        amount: amount,
                        currency: cur,
                        isIncome: isIn,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const TransferHistoryScreen()),
                        ),
                        isLast: isLast,
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Shared bits ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: labelStyle(10,
                letterSpacing: 2.0, color: color)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$count',
              style: labelStyle(9,
                  letterSpacing: 0.8, color: color, weight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final bool isIncome;
  final VoidCallback onTap;
  final bool isLast;

  const _EntryRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.isIncome,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final color =
        isIncome ? MysticColors.secondary : MysticColors.tertiary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 16,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: bodyStyle(14, weight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(subtitle,
                      style: labelStyle(9,
                          letterSpacing: 0.3,
                          color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}$currency ${fmt.format(amount)}',
              style: bodyStyle(14, weight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(message,
          style: bodyStyle(12,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))
              .copyWith(fontStyle: FontStyle.italic)),
    );
  }
}
