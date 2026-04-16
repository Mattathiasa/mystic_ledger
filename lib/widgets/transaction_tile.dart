import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'app_theme.dart';

/// A single transaction row used in both the Journal dashboard
/// and the Ledger screen.
///
/// Pass [accountName] from the calling screen (looked up via FinanceService)
/// so the tile stays stateless and independent.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String? accountName; // display name for the account

  const TransactionTile({
    super.key,
    required this.transaction,
    this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amtFmt   = NumberFormat('#,##0.00');
    final timeFmt  = DateFormat('h:mm a');
    final dateFmt  = DateFormat('MMM d');

    final diff = DateTime.now().difference(transaction.date);
    final String timeLabel;
    if (diff.inHours < 24) {
      timeLabel = timeFmt.format(transaction.date);
    } else if (diff.inDays < 2) {
      timeLabel = 'Yesterday · ${timeFmt.format(transaction.date)}';
    } else {
      timeLabel = '${dateFmt.format(transaction.date)} · ${timeFmt.format(transaction.date)}';
    }

    // Use provided name or fall back to the accountId (e.g. 'cash', 'cbe')
    final acctDisplay =
        (accountName ?? transaction.accountId).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MysticColors.outlineVariant.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: MysticColors.onSurface.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category icon chip
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              transaction.categoryIcon,
              size: 22,
              color: isIncome ? MysticColors.secondary : MysticColors.tertiary,
            ),
          ),
          const SizedBox(width: 12),
          // Title + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: headlineStyle(15, italic: false, weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeLabel • ${transaction.categoryLabel.toUpperCase()}',
                  style: labelStyle(9, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount + account
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}ETB ${amtFmt.format(transaction.amount)}',
                style: bodyStyle(
                  14,
                  weight: FontWeight.w700,
                  color: isIncome ? MysticColors.secondary : MysticColors.tertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(acctDisplay, style: labelStyle(9, letterSpacing: 0.8)),
            ],
          ),
        ],
      ),
    );
  }
}
