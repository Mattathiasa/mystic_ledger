import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/l10n.dart';
import 'app_theme.dart';

/// A single transaction row used in both the Journal dashboard
/// and the Ledger screen.
///
/// Pass [accountName] from the calling screen (looked up via FinanceService)
/// so the tile stays stateless and independent.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String? accountName; // display name for the account

  /// Opens the entry for amendment. Leave null to render the tile inert.
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.accountName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark mode or the language flips: the palette and strings
    // live in mutable statics, so const widget instances would skip us.
    Theme.of(context);
    Localizations.localeOf(context);

    final isIncome = transaction.type == TransactionType.income;
    final amtFmt   = NumberFormat('#,##0.00');
    final timeFmt  = DateFormat('h:mm a',
        L10n.instance.isAmharic ? 'am' : null);

    final diff = DateTime.now().difference(transaction.date);
    final String timeLabel;
    if (diff.inHours < 24) {
      timeLabel = timeFmt.format(transaction.date);
    } else if (diff.inDays < 2) {
      timeLabel = '${L10n.t('Yesterday')} · ${timeFmt.format(transaction.date)}';
    } else {
      timeLabel = '${L10n.date(transaction.date, 'MMM d')} · ${timeFmt.format(transaction.date)}';
    }

    // Use provided name or fall back to the accountId (e.g. 'cash', 'cbe')
    final acctDisplay =
        (accountName ?? transaction.accountId).toUpperCase();

    return GestureDetector(
      // Opaque so the whole card is a target, not just the painted glyphs.
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
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
              color: MysticColors.primaryContainer.withOpacity(0.14),
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
                '${isIncome ? '+' : '-'}${transaction.currency} '
                '${amtFmt.format(transaction.amount)}',
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
      ),
    );
  }
}
