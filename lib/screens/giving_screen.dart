import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/mystic_app_bar.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';
import '../models/transaction.dart';
import 'add_account_screen.dart';

/// Tab 3 — Sacred Giving.
///
/// Tithe is calculated as income for the period × the configured rate, minus
/// what has already been given in that same period. Giving is recorded as a
/// real expense entry, which is what makes "already given" meaningful.
class GivingScreen extends StatefulWidget {
  const GivingScreen({super.key});

  @override
  State<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends State<GivingScreen> {
  LedgerPeriod _period = LedgerPeriod.all;

  /// Set when the user picks a custom date range; null otherwise. Takes
  /// precedence over [_period].
  DateTimeRange? _customRange;

  String get _periodLabel {
    if (_customRange != null) {
      final f = DateFormat('MMM d, yyyy').format(_customRange!.start);
      final t = DateFormat('MMM d, yyyy').format(_customRange!.end);
      return '$f – $t'.toUpperCase();
    }
    switch (_period) {
      case LedgerPeriod.week:  return 'THIS WEEK';
      case LedgerPeriod.month: return 'THIS MONTH';
      default:                 return 'ALL TIME';
    }
  }

  DateTime? get _from =>
      _customRange?.start ?? _period.startFrom(DateTime.now());
  DateTime? get _to => _customRange?.end;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange:
          _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      helpText: 'Select a giving period',
      saveText: 'Apply',
    );
    if (picked == null) return;
    setState(() => _customRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: const MysticAppBar(),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          if (svc.isLoading) {
            return Center(
                child: CircularProgressIndicator(color: MysticColors.primary));
          }

          final income     = svc.incomeInRange(from: _from, to: _to);
          final obligation = income * svc.titheRate;
          final given      = computeTitheGiven(
              svc.transactions, from: _from, to: _to);
          final status     = TitheStatus.of(
              income: income, given: given, rate: svc.titheRate);
          final remaining  = status.remaining;
          final progress   = status.progress;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _GivingHeader(),
                const SizedBox(height: 24),
                _PeriodToggle(
                  selected: _period,
                  customRange: _customRange,
                  onChanged: (p) => setState(() {
                    _period = p;
                    _customRange = null;
                  }),
                  onCustom: _pickCustomRange,
                ),
                const SizedBox(height: 24),
                _IncomeCard(
                  income: income,
                  currency: svc.baseCurrency,
                  periodLabel: _periodLabel,
                ),
                const SizedBox(height: 16),
                _TitheBreakdown(
                  obligation: obligation,
                  given: given,
                  remaining: remaining,
                  progress: progress,
                  rate: svc.titheRate,
                  currency: svc.baseCurrency,
                  period: _period,
                  onEditRate: () => _editRate(svc),
                  onGive: remaining > 0 ? () => _give(svc, remaining) : null,
                ),
                const SizedBox(height: 24),
                _GivingHistory(
                  svc: svc,
                  from: _from,
                  to: _to,
                ),
                const SizedBox(height: 24),
                _ArchivistNote(
                  given: given,
                  remaining: remaining,
                  currency: svc.baseCurrency,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Records the tithe as a real expense so it counts against the obligation.
  Future<void> _give(FinanceService svc, double suggested) async {
    final accounts = svc.spendableAccounts;
    if (accounts.isEmpty) {
      // Naming the problem isn't much use without a way to fix it — a new user
      // has no accounts at all and nothing here tells them where to go.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You need an account before you can record giving.',
            style: bodyStyle(13, color: Colors.white)),
        backgroundColor: MysticColors.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'ADD ACCOUNT',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddAccountScreen()),
          ),
        ),
      ));
      return;
    }

    // Captured before the sheet, so it survives the async gap.
    final messenger = ScaffoldMessenger.maybeOf(context);

    final result = await showModalBottomSheet<_GiveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GiveSheet(
        suggested: suggested,
        accounts: accounts,
        svc: svc,
      ),
    );
    if (result == null) return;

    final currency = svc.currencyOf(result.accountId);
    // Not awaited: with offline persistence the write applies locally at once
    // but its Future only resolves on server ack, so awaiting would stall the
    // screen for as long as the device is offline.
    reportIfWriteFails(
      messenger,
      svc.addTransaction(
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Tithe',
          amount: result.amount,
          type: TransactionType.expense,
          category: TransactionCategory.tithe,
          accountId: result.accountId,
          date: DateTime.now(),
          currency: currency,
          rateToBase: svc.settings.rateFor(currency),
        ),
      ),
    );
    if (!mounted) return;
    _snack('Recorded — your giving is now in the ledger.',
        MysticColors.secondary);
  }

  Future<void> _editRate(FinanceService svc) async {
    final rate = await showDialog<double>(
      context: context,
      builder: (_) => _RateDialog(current: svc.titheRate),
    );
    if (rate == null || !mounted) return;
    reportIfWriteFails(
        ScaffoldMessenger.maybeOf(context), svc.setTitheRate(rate));
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: bodyStyle(13, color: Colors.white)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

class _GiveResult {
  final double amount;
  final String accountId;
  const _GiveResult(this.amount, this.accountId);
}

// ── Period toggle ─────────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  final LedgerPeriod selected;
  final DateTimeRange? customRange;
  final ValueChanged<LedgerPeriod> onChanged;
  final VoidCallback onCustom;
  const _PeriodToggle({
    required this.selected,
    required this.customRange,
    required this.onChanged,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MysticColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'All Time',
            icon: Icons.all_inclusive,
            active: selected == LedgerPeriod.all && customRange == null,
            onTap: () => onChanged(LedgerPeriod.all),
          ),
          _Tab(
            label: 'Monthly',
            icon: Icons.calendar_month_outlined,
            active: selected == LedgerPeriod.month && customRange == null,
            onTap: () => onChanged(LedgerPeriod.month),
          ),
          _Tab(
            label: 'Weekly (Sunday)',
            icon: Icons.church_outlined,
            active: selected == LedgerPeriod.week && customRange == null,
            onTap: () => onChanged(LedgerPeriod.week),
          ),
          _Tab(
            label: customRange != null ? 'Custom' : 'Custom…',
            icon: Icons.date_range,
            active: customRange != null,
            onTap: onCustom,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? MysticColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? MysticColors.onPrimary : MysticColors.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label,
                style: labelStyle(9,
                    letterSpacing: 0.5,
                    color: active ? MysticColors.onPrimary : MysticColors.onSurfaceVariant),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _GivingHeader extends StatelessWidget {
  const _GivingHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.star_border,
            size: 28, color: MysticColors.primary.withOpacity(0.6)),
        const SizedBox(height: 12),
        Text('Sacred Giving',
            style: headlineStyle(38, italic: true, weight: FontWeight.w900),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          'SESSION: CURRENT CYCLE',
          style: labelStyle(11,
              letterSpacing: 2.0,
              color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Total income card ─────────────────────────────────────────────────────────

class _IncomeCard extends StatelessWidget {
  final double income;
  final String currency;
  final String periodLabel;
  const _IncomeCard({
    required this.income,
    required this.currency,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Transform.rotate(
      angle: -0.009,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: MysticColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: MysticColors.outlineVariant.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: MysticColors.onSurface.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: MysticColors.surfaceContainerLow,
              blurRadius: 0,
              offset: Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Opacity(
                opacity: 0.06,
                child: Icon(Icons.auto_awesome,
                    size: 100, color: MysticColors.onSurface),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$periodLabel HARVEST',
                    style: labelStyle(11,
                        letterSpacing: 2.0, color: MysticColors.secondary)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '$currency ${fmt.format(income)}',
                        style: headlineStyle(38,
                            italic: false, weight: FontWeight.w900),
                      ),
                    ),
                    Icon(Icons.north_east,
                        color: MysticColors.secondary, size: 24),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Income recorded for this period — the basis for your tithe.',
                  style: bodyStyle(13,
                          color: MysticColors.onSurfaceVariant)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tithe calculation card ────────────────────────────────────────────────────

class _TitheBreakdown extends StatelessWidget {
  final double obligation;
  final double given;
  final double remaining;
  final double progress;
  final double rate;
  final String currency;
  final LedgerPeriod period;
  final VoidCallback onEditRate;
  /// Null when nothing is outstanding.
  final VoidCallback? onGive;

  const _TitheBreakdown({
    required this.obligation,
    required this.given,
    required this.remaining,
    required this.progress,
    required this.rate,
    required this.currency,
    required this.period,
    required this.onEditRate,
    required this.onGive,
  });

  @override
  Widget build(BuildContext context) {
    final fmt        = NumberFormat('#,##0.00');
    final settled    = remaining <= 0;
    final ratePct    = (rate * 100);
    final rateLabel  = ratePct == ratePct.roundToDouble()
        ? '${ratePct.toStringAsFixed(0)}%'
        : '${ratePct.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: MysticColors.onSurface.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: MysticColors.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                transform: Matrix4.rotationZ(-0.052),
                transformAlignment: Alignment.center,
                child: Icon(Icons.volunteer_activism,
                    color: MysticColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  period == LedgerPeriod.week
                      ? 'Sunday Offering'
                      : 'Tithe',
                  style: headlineStyle(20,
                      italic: true, weight: FontWeight.w800),
                ),
              ),
              // Rate is editable — 10% is a default, not a rule.
              GestureDetector(
                onTap: onEditRate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: MysticColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(rateLabel,
                          style: labelStyle(9,
                              letterSpacing: 1.2,
                              color: MysticColors.onPrimary)),
                      const SizedBox(width: 4),
                      Icon(Icons.edit,
                          size: 10, color: MysticColors.onPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _Line(
            label: 'OBLIGATION',
            value: '$currency ${fmt.format(obligation)}',
            color: MysticColors.onSurface,
          ),
          const SizedBox(height: 10),
          _Line(
            label: 'ALREADY GIVEN',
            value: '− $currency ${fmt.format(given)}',
            color: MysticColors.secondary,
          ),
          const SizedBox(height: 12),
          Container(
              height: 1, color: MysticColors.outlineVariant.withOpacity(0.25)),
          const SizedBox(height: 12),
          _Line(
            label: 'REMAINING',
            value: '$currency ${fmt.format(remaining)}',
            color: settled ? MysticColors.secondary : MysticColors.primary,
            emphasise: true,
          ),

          const SizedBox(height: 20),

          // Progress
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: progress,
                    track: MysticColors.outlineVariant.withOpacity(0.3),
                    arc: settled
                        ? MysticColors.secondary
                        : MysticColors.primary,
                  ),
                  child: Center(
                    child: settled
                        ? Icon(Icons.check,
                            color: MysticColors.secondary, size: 22)
                        : Text('${(progress * 100).round()}%',
                            style: labelStyle(11,
                                letterSpacing: 0,
                                color: MysticColors.primary)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  settled
                      ? (obligation <= 0
                          ? 'No income recorded for this period yet.'
                          : 'Fulfilled for this period.')
                      : '${(progress * 100).round()}% fulfilled — '
                          '$currency ${fmt.format(remaining)} still owed.',
                  style: bodyStyle(13,
                      color: MysticColors.onSurfaceVariant),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGive,
              style: ElevatedButton.styleFrom(
                backgroundColor: MysticColors.primary,
                foregroundColor: MysticColors.onPrimary,
                disabledBackgroundColor:
                    MysticColors.onSurface.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: onGive == null ? 0 : 2,
                shadowColor: MysticColors.primary.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    settled ? 'Nothing outstanding' : 'Record Giving',
                    style: headlineStyle(14,
                        italic: false,
                        weight: FontWeight.w700,
                        color: onGive == null
                            ? MysticColors.onSurfaceVariant.withOpacity(0.5)
                            : MysticColors.onPrimary),
                  ),
                  if (onGive != null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool emphasise;
  const _Line({
    required this.label,
    required this.value,
    required this.color,
    this.emphasise = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.7))),
        Text(
          value,
          style: emphasise
              ? headlineStyle(24,
                  italic: false, weight: FontWeight.w900, color: color)
              : bodyStyle(16, weight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

/// Draws a circular progress arc on a semi-transparent background ring.
class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color track;
  final Color arc;

  const _ProgressRingPainter({
    required this.progress,
    required this.track,
    required this.arc,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;
    const strokeWidth = 7.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start at top
      2 * math.pi * progress,
      false,
      Paint()
        ..color = arc
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.arc != arc || old.track != track;
}

// ── Giving history ────────────────────────────────────────────────────────────

/// The individual tithe/giving expense entries for the selected period — "I
/// gave ETB 500 on July 3rd, ETB 300 on July 18th." The aggregate cards above
/// answer how much; this answers when and to what.
class _GivingHistory extends StatelessWidget {
  final FinanceService svc;
  final DateTime? from;
  final DateTime? to;
  const _GivingHistory({required this.svc, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    // Local copies: field promotion does not apply inside closures, and
    // `from`/`to` are fields.
    final fromL = from;
    final toL = to;
    final entries = svc.transactions
        .where((t) => t.type == TransactionType.expense)
        .where((t) => t.category == TransactionCategory.tithe)
        .where((t) =>
            (fromL == null || !t.date.isBefore(fromL)) &&
            (toL == null || t.date.isBefore(toL)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final fmt = NumberFormat('#,##0.00');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('HISTORY OF GIVING',
                style: labelStyle(10,
                    letterSpacing: 2.0,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.7))),
            if (entries.isNotEmpty)
              Text('${entries.length} ENTR${entries.length == 1 ? 'Y' : 'IES'}',
                  style: labelStyle(9,
                      letterSpacing: 1.2,
                      color: MysticColors.secondary)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: MysticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: MysticColors.outlineVariant.withOpacity(0.15)),
          ),
          child: entries.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.volunteer_activism_outlined,
                          size: 40, color: MysticColors.outlineVariant),
                      const SizedBox(height: 10),
                      Text(
                        'No giving recorded for this period.',
                        style: bodyStyle(12,
                                color: MysticColors.onSurfaceVariant
                                    .withOpacity(0.6))
                            .copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: entries.asMap().entries.map((e) {
                    final t = e.value;
                    final isLast = e.key == entries.length - 1;
                    final account =
                        svc.findAccount(t.accountId)?.name ?? t.accountId;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: isLast
                          ? null
                          : BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: MysticColors.outlineVariant
                                        .withOpacity(0.2)),
                              ),
                            ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: MysticColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.volunteer_activism,
                                size: 18, color: MysticColors.secondary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.title.isEmpty ? 'Giving' : t.title,
                                  style: bodyStyle(14, weight: FontWeight.w700),
                                ),
                                Text(
                                  '${DateFormat('MMM d, yyyy · h:mm a').format(t.date)}'
                                  ' · $account'
                                  '${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}',
                                  style: labelStyle(9,
                                      letterSpacing: 0.3,
                                      color: MysticColors.onSurfaceVariant
                                          .withOpacity(0.6)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '-${t.currency} ${fmt.format(t.amount)}'
                            '${t.fee > 0 ? ' +${fmt.format(t.fee)} fee' : ''}',
                            style: bodyStyle(14,
                                weight: FontWeight.w800,
                                color: MysticColors.secondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

// ── Give sheet ────────────────────────────────────────────────────────────────

/// Collects the amount and the account it comes from, then the caller records
/// it as a real tithe expense.
class _GiveSheet extends StatefulWidget {
  final double suggested;
  final List<Account> accounts;
  final FinanceService svc;

  const _GiveSheet({
    required this.suggested,
    required this.accounts,
    required this.svc,
  });

  @override
  State<_GiveSheet> createState() => _GiveSheetState();
}

class _GiveSheetState extends State<_GiveSheet> {
  late final TextEditingController _amountCtrl;
  late String _accountId;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.suggested.toStringAsFixed(2));
    _accountId = widget.accounts.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom   = MediaQuery.of(context).viewInsets.bottom;
    final currency = widget.svc.currencyOf(_accountId);
    final fmt      = NumberFormat('#,##0.00');
    final available = widget.svc.accountBalance(_accountId);

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
          Text('Record Giving',
              style: headlineStyle(26, italic: true, weight: FontWeight.w900)),
          const SizedBox(height: 20),

          Text('AMOUNT',
              style: labelStyle(10,
                  letterSpacing: 1.5,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(currency,
                  style: headlineStyle(20,
                      italic: false,
                      weight: FontWeight.w700,
                      color: MysticColors.primary.withOpacity(0.7))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  style:
                      headlineStyle(34, italic: false, weight: FontWeight.w900),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          Container(
              height: 1.5,
              color: MysticColors.outlineVariant.withOpacity(0.3)),

          const SizedBox(height: 20),
          Text('FROM',
              style: labelStyle(10,
                  letterSpacing: 1.5,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          DropdownButtonFormField<String>(
            value: _accountId,
            onChanged: (v) => setState(() => _accountId = v ?? _accountId),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.only(bottom: 8),
            ),
            style: bodyStyle(15, weight: FontWeight.w600),
            dropdownColor: MysticColors.surfaceContainerLow,
            items: widget.accounts
                .map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(a.icon, size: 16, color: MysticColors.primary),
                          const SizedBox(width: 8),
                          Text('${a.name} · ${a.currency}'),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          Text('Available: $currency ${fmt.format(available)}',
              style: labelStyle(10,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MysticColors.primary,
              foregroundColor: MysticColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Record',
                style: headlineStyle(16,
                    italic: false,
                    weight: FontWeight.w700,
                    color: MysticColors.onPrimary)),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;
    Navigator.of(context).pop(_GiveResult(amount, _accountId));
  }
}

// ── Tithe rate dialog ─────────────────────────────────────────────────────────

class _RateDialog extends StatefulWidget {
  final double current;
  const _RateDialog({required this.current});

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: (widget.current * 100).toStringAsFixed(
            (widget.current * 100) % 1 == 0 ? 0 : 1));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MysticColors.surfaceContainerLow,
      title: Text('Giving rate',
          style: headlineStyle(20, italic: true, weight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What share of your income do you set aside?',
              style: bodyStyle(14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style:
                      headlineStyle(30, italic: false, weight: FontWeight.w900),
                  decoration: InputDecoration(
                    isDense: true,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              MysticColors.outlineVariant.withOpacity(0.4)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: MysticColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('%',
                  style: headlineStyle(24,
                      italic: false, weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: () {
            final pct = double.tryParse(_ctrl.text);
            // A rate outside 0–100% is a typo, not an intention.
            if (pct == null || pct < 0 || pct > 100) return;
            Navigator.pop(context, pct / 100);
          },
          child: Text('Save',
              style: bodyStyle(14,
                  weight: FontWeight.w700, color: MysticColors.primary)),
        ),
      ],
    );
  }
}

// ── Archivist note ────────────────────────────────────────────────────────────

class _ArchivistNote extends StatelessWidget {
  final double given;
  final double remaining;
  final String currency;

  const _ArchivistNote({
    required this.given,
    required this.remaining,
    required this.currency,
  });

  String _message(NumberFormat fmt) {
    if (given <= 0 && remaining <= 0) {
      return 'Record income to see what you have set aside for giving. '
          'Anything you give is logged as a Tithe entry in your ledger.';
    }
    if (given <= 0) {
      return 'Nothing recorded yet for this period. '
          '$currency ${fmt.format(remaining)} is set aside as owed — '
          'tap Record Giving once you have given it.';
    }
    if (remaining <= 0) {
      return 'You have recorded $currency ${fmt.format(given)} in giving for '
          'this period, meeting your commitment in full.';
    }
    return 'You have given $currency ${fmt.format(given)} so far this period, '
        'with $currency ${fmt.format(remaining)} still outstanding.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: MysticColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_edu,
              size: 40, color: MysticColors.primaryContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Archivist's Note",
                    style: headlineStyle(17,
                        italic: false, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                // Reflects the user's actual recorded giving — no invented
                // statistics.
                Text(
                  _message(NumberFormat('#,##0.00')),
                  style: bodyStyle(13, color: MysticColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
