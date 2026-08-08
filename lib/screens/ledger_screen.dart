import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/mystic_app_bar.dart';
import '../services/finance_service.dart';
import 'journal_screen.dart' show entrySlideUpRoute;
import 'new_entry_screen.dart';
import 'transfer_history_screen.dart';

const _pageSize = 20;

/// Tab 2 — All Entries.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

enum _LedgerFilter { all, income, expense, transfer }

class _LedgerScreenState extends State<LedgerScreen> {
  _LedgerFilter _filter = _LedgerFilter.all;
  int _visibleCount = _pageSize;

  List<LedgerEntry> _applyFilter(List<LedgerEntry> all) {
    switch (_filter) {
      case _LedgerFilter.all:      return all;
      case _LedgerFilter.income:   return all.where((e) => e.kind == LedgerEntryKind.income).toList();
      case _LedgerFilter.expense:  return all.where((e) => e.kind == LedgerEntryKind.expense).toList();
      case _LedgerFilter.transfer: return all.where((e) => e.kind == LedgerEntryKind.transfer).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: const MysticAppBar(),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          if (svc.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: MysticColors.primary),
            );
          }

          final all     = _applyFilter(svc.allLedgerEntries);
          final list    = all.take(_visibleCount).toList();
          final hasMore = all.length > _visibleCount;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All Entries',
                          style: headlineStyle(44,
                              italic: true, weight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        'ARCHIVE: ${all.length} ENTRIES',
                        style: labelStyle(11,
                            letterSpacing: 2.0,
                            color: MysticColors.onSurfaceVariant
                                .withOpacity(0.7)),
                      ),
                      const SizedBox(height: 24),
                      _FilterRow(
                        current: _filter,
                        onChanged: (f) => setState(() {
                          _filter = f;
                          _visibleCount = _pageSize;
                        }),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _LedgerBook(entries: list, svc: svc),
                ),
              ),
              if (hasMore)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 24, 0, 100),
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _visibleCount += _pageSize),
                        icon: const Icon(Icons.expand_more),
                        label: Text(
                          'Load ${(all.length - _visibleCount).clamp(0, _pageSize)} more  (${all.length - _visibleCount} remaining)',
                          style: headlineStyle(14,
                              italic: true, weight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MysticColors.primary,
                          side: const BorderSide(
                              color: MysticColors.outlineVariant),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final _LedgerFilter current;
  final ValueChanged<_LedgerFilter> onChanged;
  const _FilterRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(label: 'All',      active: current == _LedgerFilter.all,      rotation: -0.017, onTap: () => onChanged(_LedgerFilter.all)),
          const SizedBox(width: 12),
          _Chip(label: 'Income',   active: current == _LedgerFilter.income,   rotation:  0.017, onTap: () => onChanged(_LedgerFilter.income)),
          const SizedBox(width: 12),
          _Chip(label: 'Expense',  active: current == _LedgerFilter.expense,  rotation: -0.009, onTap: () => onChanged(_LedgerFilter.expense)),
          const SizedBox(width: 12),
          _Chip(label: 'Transfer', active: current == _LedgerFilter.transfer, rotation:  0.011, onTap: () => onChanged(_LedgerFilter.transfer)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final double rotation;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.rotation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: active ? rotation : 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: active ? MysticColors.primary : MysticColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label.toUpperCase(),
            style: labelStyle(11,
                letterSpacing: 1.5,
                color: active
                    ? MysticColors.onPrimary
                    : MysticColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

// ── Ledger book container ─────────────────────────────────────────────────────

class _LedgerBook extends StatelessWidget {
  final List<LedgerEntry> entries;
  final FinanceService svc;
  const _LedgerBook({required this.entries, required this.svc});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: MysticColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.auto_stories_outlined,
                  size: 48, color: MysticColors.outlineVariant),
              const SizedBox(height: 12),
              Text('No entries found',
                  style: headlineStyle(16,
                      italic: true,
                      weight: FontWeight.w600,
                      color: MysticColors.outline)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MysticColors.onSurface.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Binding rings
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            child: Column(
              children: List.generate(
                6,
                (_) => Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MysticColors.outlineVariant.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: entries.asMap().entries.map((e) {
                final entry = e.value;
                final isLast = e.key == entries.length - 1;

                // Transfers are corrected by reversal, never by deletion or
                // editing: the archive keeps both the original and the
                // correction. Tapping one opens the history, where reversing
                // is the only mutation on offer.
                if (entry.kind == LedgerEntryKind.transfer) {
                  return _LedgerRow(
                    entry: entry,
                    svc: svc,
                    isLast: isLast,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const TransferHistoryScreen()),
                    ),
                  );
                }

                return Dismissible(
                  // Scoped by kind: transaction and transfer ids are minted
                  // from the clock in separate collections, so they are only
                  // unique within a kind.
                  key: ValueKey('${entry.kind.name}_${entry.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: MysticColors.tertiary.withOpacity(0.15),
                    child: const Icon(Icons.delete_outline,
                        color: MysticColors.tertiary, size: 24),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: MysticColors.surfaceContainerLow,
                        title: Text('Delete entry?',
                            style: headlineStyle(18,
                                italic: true, weight: FontWeight.w700)),
                        content: Text('Remove "${entry.title}"?',
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
                    );
                  },
                  onDismissed: (_) => reportIfWriteFails(
                      ScaffoldMessenger.maybeOf(context),
                      svc.deleteTransaction(entry.id)),
                  child: _LedgerRow(
                    entry: entry,
                    svc: svc,
                    isLast: isLast,
                    // A LedgerEntry is lossy — no category, no rate snapshot —
                    // so the edit has to start from the stored transaction.
                    onTap: () {
                      final tx = svc.findTransaction(entry.id);
                      if (tx == null) return;
                      Navigator.of(context)
                          .push(entrySlideUpRoute(NewEntryScreen(existing: tx)));
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final LedgerEntry entry;
  final FinanceService svc;
  final bool isLast;

  /// Transactions open for amendment; transfers open the reversal history.
  final VoidCallback? onTap;

  const _LedgerRow({
    required this.entry,
    required this.svc,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt     = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, yyyy · h:mm a');
    final isTransfer = entry.kind == LedgerEntryKind.transfer;
    final isIncome   = entry.kind == LedgerEntryKind.income;

    final Color entryColor = isTransfer
        ? MysticColors.primary
        : isIncome
            ? MysticColors.secondary
            : MysticColors.tertiary;

    final cur = entry.currency;

    final String subtitle = isTransfer
        ? () {
            final from = svc.findAccount(entry.fromAccountId ?? '')?.name ?? entry.fromAccountId ?? '?';
            final to   = svc.findAccount(entry.toAccountId   ?? '')?.name ?? entry.toAccountId   ?? '?';
            final fee  = entry.fee > 0
                ? '  (fee: $cur ${fmt.format(entry.fee)})'
                : '';
            return '$from → $to$fee';
          }()
        : svc.findAccount(entry.accountId ?? '')?.name ?? entry.accountId ?? '?';

    final String amountText = isTransfer
        // Cross-currency transfers show both sides, since one number alone
        // would misrepresent what actually moved.
        ? (entry.isCrossCurrency
            ? '$cur ${fmt.format(entry.amount)} → '
                '${entry.toCurrency} ${fmt.format(entry.toAmount)}'
            : '$cur ${fmt.format(entry.amount)}')
        : '${isIncome ? '+' : '-'}$cur ${fmt.format(entry.amount)}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
          // Icon badge
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: entryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isTransfer ? Icons.swap_horiz_rounded
                  : isIncome ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: entryColor,
              size: 18,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateFmt.format(entry.date).toUpperCase(),
                  style: labelStyle(9,
                      letterSpacing: 0.8,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
                ),
                const SizedBox(height: 2),
                Text(entry.title,
                    style: bodyStyle(15, weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  subtitle,
                  style: labelStyle(10,
                      letterSpacing: 0.5, color: entryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: bodyStyle(15, weight: FontWeight.w800, color: entryColor),
          ),
        ],
      ),
      ),
    );
  }
}
