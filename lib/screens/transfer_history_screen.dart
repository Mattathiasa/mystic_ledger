import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../services/l10n.dart';
import '../services/finance_service.dart';
import '../models/transfer_model.dart';

/// Full record of every transfer, with the ability to undo one.
///
/// Reversing does not delete anything: it records a matching transfer in the
/// opposite direction, so the archive shows both the original movement and the
/// correction.
class TransferHistoryScreen extends StatelessWidget {
  const TransferHistoryScreen({super.key});

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
        title: Text(L10n.t('Transfer Record'),
            style: headlineStyle(22, italic: true, weight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
              height: 1.5,
              color: MysticColors.outlineVariant.withOpacity(0.5)),
        ),
      ),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          if (svc.isLoading) {
            return Center(
                child: CircularProgressIndicator(color: MysticColors.primary));
          }
          final transfers = svc.transfers;
          // Non-const on purpose: must rebuild on theme/locale change.
          // ignore: prefer_const_constructors
          if (transfers.isEmpty) return _EmptyState();

          final totalFees = transfers.fold<double>(0, (s, t) => s + t.feeInBase);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            itemCount: transfers.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _FeeSummary(
                  total: totalFees,
                  currency: svc.baseCurrency,
                  count: transfers.length,
                );
              }
              final t = transfers[i - 1];
              return _TransferRow(
                transfer: t,
                svc: svc,
                reversed: svc.isReversed(t.id),
                canReverse: svc.canReverse(t.id),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Fee summary ───────────────────────────────────────────────────────────────

class _FeeSummary extends StatelessWidget {
  final double total;
  final String currency;
  final int count;
  const _FeeSummary({
    required this.total,
    required this.currency,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MysticColors.tertiary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MysticColors.tertiary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.percent,
                color: MysticColors.tertiary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.t('LOST TO TRANSFER FEES'),
                    style: labelStyle(9,
                        letterSpacing: 1.5, color: MysticColors.tertiary)),
                const SizedBox(height: 4),
                Text('$currency ${fmt.format(total)}',
                    style: headlineStyle(24,
                        italic: false,
                        weight: FontWeight.w900,
                        color: MysticColors.tertiary)),
                Text(
                    count == 1
                        ? '${L10n.t('across')} 1 ${L10n.t('transfer')}'
                        : '${L10n.t('across')} $count ${L10n.t('transfers')}',
                    style: labelStyle(9,
                        letterSpacing: 0.5,
                        color:
                            MysticColors.onSurfaceVariant.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transfer row ──────────────────────────────────────────────────────────────

class _TransferRow extends StatelessWidget {
  final Transfer transfer;
  final FinanceService svc;
  final bool reversed;
  final bool canReverse;

  const _TransferRow({
    required this.transfer,
    required this.svc,
    required this.reversed,
    required this.canReverse,
  });

  @override
  Widget build(BuildContext context) {
    final fmt      = NumberFormat('#,##0.00');
    final fromName =
        svc.findAccount(transfer.fromAccountId)?.name ?? L10n.t('Unknown');
    final toName = svc.findAccount(transfer.toAccountId)?.name ?? L10n.t('Unknown');
    final isReversal = transfer.isReversal;

    // A reversed original is struck through so the record reads honestly.
    final struck = reversed ? TextDecoration.lineThrough : null;
    final dim = reversed || isReversal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isReversal
            ? MysticColors.surfaceContainerHigh
            : MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isReversal
              ? MysticColors.secondary.withOpacity(0.3)
              : MysticColors.outlineVariant.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReversal ? Icons.undo : Icons.swap_horiz,
                size: 18,
                color: isReversal
                    ? MysticColors.secondary
                    : MysticColors.primary.withOpacity(dim ? 0.4 : 1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$fromName  →  $toName',
                  style: bodyStyle(14,
                          weight: FontWeight.w700,
                          color: MysticColors.onSurface
                              .withOpacity(dim ? 0.5 : 1))
                      .copyWith(decoration: struck),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (reversed) _Badge(text: L10n.t('REVERSED')),
              if (isReversal) _Badge(text: L10n.t('REVERSAL')),
            ],
          ),
          const SizedBox(height: 10),

          // Amount — both sides shown when currencies differ
          Text(
            transfer.isCrossCurrency
                ? '${transfer.currency} ${fmt.format(transfer.amount)}'
                    '   →   ${transfer.toCurrency} ${fmt.format(transfer.toAmount)}'
                : '${transfer.currency} ${fmt.format(transfer.amount)}',
            style: headlineStyle(20,
                    italic: false,
                    weight: FontWeight.w900,
                    color: MysticColors.onSurface.withOpacity(dim ? 0.5 : 1))
                .copyWith(decoration: struck),
          ),
          if (transfer.isCrossCurrency) ...[
            const SizedBox(height: 2),
            Text(
              'rate 1 ${transfer.currency} = ${fmt.format(transfer.rate)} ${transfer.toCurrency}',
              style: labelStyle(9,
                  letterSpacing: 0.5,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                DateFormat('MMM d, yyyy · HH:mm',
                        L10n.instance.isAmharic ? 'am' : null)
                    .format(transfer.date),
                style: labelStyle(9,
                    letterSpacing: 0.5,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
              ),
              if (transfer.fee > 0) ...[
                const SizedBox(width: 10),
                Text(
                  '${L10n.t('fee')} ${transfer.currency} ${fmt.format(transfer.fee)}',
                  style: labelStyle(9,
                      letterSpacing: 0.5, color: MysticColors.tertiary),
                ),
              ],
              if (transfer.category != null) ...[
                const SizedBox(width: 10),
                Icon(transfer.category!.icon,
                    size: 11,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.5)),
                const SizedBox(width: 3),
                Text(
                  transfer.category!.label,
                  style: labelStyle(9,
                      letterSpacing: 0.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
                ),
              ],
            ],
          ),

          if (transfer.note != null && transfer.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              transfer.note!,
              style: bodyStyle(12,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.7))
                  .copyWith(fontStyle: FontStyle.italic),
            ),
          ],

          if (canReverse) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmReverse(context),
                icon: const Icon(Icons.undo, size: 15),
                style: TextButton.styleFrom(
                  foregroundColor: MysticColors.tertiary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                label: Text(L10n.t('REVERSE'),
                    style: labelStyle(10,
                        letterSpacing: 1.2, color: MysticColors.tertiary)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReverse(BuildContext context) async {
    final fmt = NumberFormat('#,##0.00');
    final messenger = ScaffoldMessenger.of(context);
    var refundFee = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          backgroundColor: MysticColors.surfaceContainerLow,
          title: Text(L10n.t('Reverse this transfer?'),
              style:
                  headlineStyle(19, italic: true, weight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L10n.t('A matching transfer in the opposite direction will be '
                    'recorded. Both entries stay in your archive.'),
                style: bodyStyle(14),
              ),
              if (transfer.fee > 0) ...[
                const SizedBox(height: 16),
                CheckboxActivated(
                  value: refundFee,
                  onChanged: (v) => setLocal(() => refundFee = v),
                  label: '${L10n.t('Also refund the')} '
                      '${transfer.currency} ${fmt.format(transfer.fee)} '
                      '${L10n.t('fee')}',
                  hint: L10n.t('Leave off if the bank kept it.'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(L10n.t('Cancel'),
                  style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(L10n.t('Reverse'),
                  style: bodyStyle(14,
                      weight: FontWeight.w700,
                      color: MysticColors.tertiary)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await svc.reverseTransfer(transfer.id, refundFee: refundFee);
      messenger.showSnackBar(_snack(
        L10n.t('Transfer reversed — the ledger has been corrected.'),
        MysticColors.secondary,
      ));
    } catch (e) {
      // StateError covers the guards (already reversed, reversing a reversal);
      // anything else is a Firestore failure and gets a friendly message.
      messenger
          .showSnackBar(_snack(friendlyWriteError(e), MysticColors.tertiary));
    }
  }

  SnackBar _snack(String msg, Color bg) => SnackBar(
        content: Text(msg, style: bodyStyle(13, color: readableOn(bg))),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

/// Small labelled checkbox used inside the reverse dialog.
class CheckboxActivated extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final String hint;

  const CheckboxActivated({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: MysticColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: bodyStyle(13, weight: FontWeight.w600)),
                  Text(hint,
                      style: labelStyle(9,
                          letterSpacing: 0.3,
                          color: MysticColors.onSurfaceVariant
                              .withOpacity(0.6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge & empty state ───────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MysticColors.onSurface.withOpacity(0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: labelStyle(8,
              letterSpacing: 1.0,
              color: MysticColors.onSurfaceVariant.withOpacity(0.7))),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz,
                size: 56, color: MysticColors.outlineVariant),
            const SizedBox(height: 12),
            Text(L10n.t('No transfers recorded yet'),
                style: headlineStyle(16,
                    italic: true,
                    weight: FontWeight.w600,
                    color: MysticColors.outline),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
