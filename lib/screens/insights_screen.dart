import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/mystic_app_bar.dart';
import '../services/finance_service.dart';
import '../services/l10n.dart';
import '../models/transaction.dart';

/// Categorical palette for charts.
///
/// Validated for colour-vision deficiency against the parchment surface
/// (#F5F5DC): every adjacent pair clears ΔE 8 under protan/deutan/tritan
/// simulation, every swatch clears 3:1 contrast, and none reads as grey.
/// Do not reorder or substitute without re-validating — the previous palette
/// put dark gold next to forest green, which are near-identical (ΔE 2.5) to a
/// red-blind reader.
class ChartPalette {
  static const red    = Color(0xFFA83232);
  static const blue   = Color(0xFF2F6BB8);
  static const amber  = Color(0xFFB87200);
  static const purple = Color(0xFF8E4FA8);
  static const green  = Color(0xFF12864C);
  static const indigo = Color(0xFF6B5BC4);
  static const orange = Color(0xFFB5561E);
  static const teal   = Color(0xFF0A9396);

  static const ordered = [red, blue, amber, purple, green, indigo, orange, teal];

  /// Colour is bound to the category itself, never to its rank in a sorted
  /// list — otherwise changing the period would repaint every slice.
  static Color forCategory(TransactionCategory c) =>
      ordered[c.index % ordered.length];
}

/// Tab 4 — Insights / Reports.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  LedgerPeriod _period = LedgerPeriod.month;

  /// Set when the user picks a custom date range; null otherwise. A non-null
  /// value takes precedence over [_period].
  DateTimeRange? _customRange;

  /// The effective window: from the custom range when set, else the period.
  DateTime? get _from =>
      _customRange?.start ?? _period.startFrom(DateTime.now());
  DateTime? get _to => _customRange?.end;

  String get _windowLabel {
    if (_customRange != null) {
      final f = DateFormat('MMM d, yyyy').format(_customRange!.start);
      final t = DateFormat('MMM d, yyyy').format(_customRange!.end);
      return '$f – $t';
    }
    return _period.label;
  }

  /// The full range passed to the chart widgets, so they can render a custom
  /// window instead of the preset one.
  ({DateTime? from, DateTime? to}) get _range =>
      (from: _from, to: _to);

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      helpText: L10n.t('Select a custom period'),
      saveText: L10n.t('Apply'),
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _period = LedgerPeriod.month; // custom now drives the cards
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark mode or the language flips: the palette and strings
    // live in mutable statics, so const widget instances would skip us.
    Theme.of(context);
    Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: const MysticAppBar(),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          if (svc.isLoading) {
            return Center(
                child: CircularProgressIndicator(color: MysticColors.primary));
          }

          final from = _from;
          final to = _to;
          final byCategory = svc.expensesByCategoryInRange(from: from, to: to);
          final hasAnything = svc.transactions.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.t('OBSERVATIONS'),
                    style: labelStyle(10,
                        letterSpacing: 2.0,
                        color:
                            MysticColors.onSurfaceVariant.withOpacity(0.7))),
                const SizedBox(height: 8),
                Text(L10n.t('Insights'),
                    style:
                        headlineStyle(48, italic: true, weight: FontWeight.w900)),
                const SizedBox(height: 20),

                // One control drives every card below it.
                _PeriodSelector(
                  selected: _period,
                  customRange: _customRange,
                  onChanged: (p) => setState(() {
                    _period = p;
                    _customRange = null;
                  }),
                  onCustom: _pickCustomRange,
                ),
                const SizedBox(height: 24),

                if (!hasAnything)
                  _EmptyState(
                    icon: Icons.insights_outlined,
                    message: L10n.t('No entries yet.\n'
                        'Add income or an expense and your reports appear '
                        'here.'),
                  )
                else ...[
                  _SummaryGrid(svc: svc, range: _range),
                  const SizedBox(height: 28),
                  _TrendChart(
                    svc: svc,
                    range: _range,
                    label: _windowLabel,
                  ),
                  const SizedBox(height: 28),
                  _BalanceLine(
                    svc: svc,
                    range: _range,
                    label: _windowLabel,
                  ),
                  const SizedBox(height: 28),
                  _CategoryDonut(
                    svc: svc,
                    range: _range,
                    data: byCategory,
                  ),
                  const SizedBox(height: 28),
                  _FeesCard(
                    svc: svc,
                    range: _range,
                    label: _windowLabel,
                  ),
                  const SizedBox(height: 28),
                  _AccountDistribution(svc: svc),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final LedgerPeriod selected;
  final DateTimeRange? customRange;
  final ValueChanged<LedgerPeriod> onChanged;
  final VoidCallback onCustom;
  const _PeriodSelector({
    required this.selected,
    required this.customRange,
    required this.onChanged,
    required this.onCustom,
  });

  static Map<LedgerPeriod, String> get _short => {
        LedgerPeriod.week:      L10n.t('Week'),
        LedgerPeriod.month:     L10n.t('Month'),
        LedgerPeriod.sixMonths: L10n.t('6 Months'),
        LedgerPeriod.year:      L10n.t('Year'),
        LedgerPeriod.all:       L10n.t('All'),
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...LedgerPeriod.values.map((p) {
            final active = p == selected && customRange == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: active
                        ? MysticColors.primary
                        : MysticColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? MysticColors.primary
                          : MysticColors.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _short[p]!,
                    style: labelStyle(10,
                        letterSpacing: 1.0,
                        color: active
                            ? MysticColors.onPrimary
                            : MysticColors.onSurfaceVariant),
                  ),
                ),
              ),
            );
          }),
          // Custom period — the only option that opens a picker.
          GestureDetector(
            onTap: onCustom,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: customRange != null
                    ? MysticColors.primary
                    : MysticColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: customRange != null
                      ? MysticColors.primary
                      : MysticColors.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 13,
                    color: customRange != null
                        ? MysticColors.onPrimary
                        : MysticColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    customRange != null
                        ? L10n.t('Custom')
                        : L10n.t('Custom…'),
                    style: labelStyle(10,
                        letterSpacing: 1.0,
                        color: customRange != null
                            ? MysticColors.onPrimary
                            : MysticColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary tiles ─────────────────────────────────────────────────────────────

/// All four figures read from the same date range — previously income was
/// monthly while expenses and balance were all-time.
class _SummaryGrid extends StatelessWidget {
  final FinanceService svc;
  final ({DateTime? from, DateTime? to}) range;
  const _SummaryGrid({required this.svc, required this.range});

  @override
  Widget build(BuildContext context) {
    final income   = svc.incomeInRange(from: range.from, to: range.to);
    final expenses = svc.expensesInRange(from: range.from, to: range.to);
    final fees     = svc.feesInRange(from: range.from, to: range.to);
    final net      = income - expenses - fees;
    final cur      = svc.baseCurrency;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: L10n.t('INCOME'),
                value: _money(cur, income),
                mark: ChartPalette.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: L10n.t('EXPENSES'),
                value: _money(cur, expenses),
                mark: ChartPalette.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: L10n.t('NET'),
                value: _money(cur, net),
                mark: net >= 0 ? ChartPalette.green : ChartPalette.red,
                emphasise: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: L10n.t('FEES PAID'),
                value: _money(cur, fees),
                mark: ChartPalette.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _money(String currency, double v) =>
    '$currency ${NumberFormat('#,##0.00').format(v)}';

/// Value text stays in ink; the small colour chip carries identity. Colouring
/// the number itself makes it harder to read and doubles the colour load.
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color mark;
  final bool emphasise;

  const _StatTile({
    required this.label,
    required this.value,
    required this.mark,
    this.emphasise = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emphasise
            ? MysticColors.surfaceContainerHighest
            : MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: mark, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: labelStyle(9,
                        letterSpacing: 1.2,
                        color:
                            MysticColors.onSurfaceVariant.withOpacity(0.8))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: bodyStyle(emphasise ? 18 : 16,
                  weight: FontWeight.w800, color: MysticColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trend chart ───────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final FinanceService svc;
  final ({DateTime? from, DateTime? to}) range;
  final String label;
  const _TrendChart({required this.svc, required this.range, required this.label});

  @override
  Widget build(BuildContext context) {
    // A custom window buckets by calendar month; a preset period keeps its
    // native granularity (days for a week, weeks for a month).
    final buckets = (range.from != null && range.to != null)
        ? svc.trendBetween(range.from!, range.to!)
        : svc.trendFor(_periodFromRange());
    final maxV = buckets.fold<double>(
        0, (m, b) => [m, b.income, b.expenses].reduce((a, c) => a > c ? a : c));
    final yMax = maxV > 0 ? maxV * 1.25 : 1000.0;

    return _ChartCard(
      icon: Icons.bar_chart_rounded,
      title: L10n.t('Income vs Expenses'),
      subtitle: label,
      legend: [
        _LegendDot(color: ChartPalette.green, label: L10n.t('Income')),
        _LegendDot(color: ChartPalette.red, label: L10n.t('Expenses')),
      ],
      child: maxV == 0
          ? _InlineEmpty(message: L10n.t('Nothing recorded in this period.'))
          : SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  maxY: yMax,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yMax / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: MysticColors.onSurface.withOpacity(0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: yMax / 4,
                        getTitlesWidget: (val, meta) {
                          if (val == 0 || val >= meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Text(_compact(val),
                              style: labelStyle(9,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.6)));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (val, _) {
                          final i = val.toInt();
                          if (i < 0 || i >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(buckets[i].label,
                                style: labelStyle(9,
                                    color: MysticColors.onSurfaceVariant
                                        .withOpacity(0.7))),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: buckets.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      // 2px gap between the paired bars keeps the fills from
                      // reading as one shape.
                      barsSpace: 2,
                      barRods: [
                        _rod(e.value.income, ChartPalette.green),
                        _rod(e.value.expenses, ChartPalette.red),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          MysticColors.surfaceContainerHighest,
                      tooltipRoundedRadius: 10,
                      getTooltipItem: (group, _, rod, rodIdx) {
                        final b = buckets[group.x];
                        final label =
                            rodIdx == 0 ? L10n.t('Income') : L10n.t('Expenses');
                        return BarTooltipItem(
                          '${b.label} · $label\n'
                          '${_money(svc.baseCurrency, rod.toY)}',
                          bodyStyle(12,
                              weight: FontWeight.w600,
                              color: MysticColors.onSurface),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  BarChartRodData _rod(double v, Color c) => BarChartRodData(
        toY: v,
        color: c,
        width: 9,
        // Rounded data-end only; the base stays anchored to the axis.
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      );

  /// Backs the preset period out of the range: a custom range is the only
  /// path where both bounds are set, so a lone `from` always maps back to a
  /// period for bucketing.
  LedgerPeriod _periodFromRange() {
    final now = DateTime.now();
    final from = range.from;
    if (from == null) return LedgerPeriod.all;
    // Match the exact period start so the label is honest.
    for (final p in LedgerPeriod.values) {
      final start = p.startFrom(now);
      if (start != null && start.isAtSameMomentAs(from)) return p;
    }
    return LedgerPeriod.all;
  }
}

String _compact(double v) {
  if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
  return v.toStringAsFixed(0);
}

// ── Cumulative balance line ───────────────────────────────────────────────────

class _BalanceLine extends StatelessWidget {
  final FinanceService svc;
  final ({DateTime? from, DateTime? to}) range;
  final String label;
  const _BalanceLine(
      {required this.svc, required this.range, required this.label});

  @override
  Widget build(BuildContext context) {
    final series = svc.balanceSeries(from: range.from, to: range.to);

    return _ChartCard(
      icon: Icons.show_chart_rounded,
      title: L10n.t('Running Balance'),
      subtitle: '${L10n.t('Cumulative net position')} · $label',
      child: series.length < 2
          ? _InlineEmpty(
              message:
                  L10n.t('At least two entries are needed to draw a trend.'))
          : SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: MysticColors.onSurface.withOpacity(0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (val, meta) {
                          if (val == meta.min || val == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Text(_compact(val),
                              style: labelStyle(9,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.6)));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: series
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.value))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: ChartPalette.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: ChartPalette.blue.withOpacity(0.10),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          MysticColors.surfaceContainerHighest,
                      tooltipRoundedRadius: 10,
                      getTooltipItems: (spots) => spots.map((s) {
                        final p = series[s.x.toInt()];
                        return LineTooltipItem(
                          '${L10n.date(p.date, 'MMM d')}\n'
                          '${_money(svc.baseCurrency, p.value)}',
                          bodyStyle(12,
                              weight: FontWeight.w600,
                              color: MysticColors.onSurface),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

}

// ── Category donut ────────────────────────────────────────────────────────────

class _CategoryDonut extends StatefulWidget {
  final FinanceService svc;
  final ({DateTime? from, DateTime? to}) range;
  final Map<TransactionCategory, double> data;
  const _CategoryDonut({
    required this.svc,
    required this.range,
    required this.data,
  });

  @override
  State<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<_CategoryDonut> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final sorted = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0.0, (s, e) => s + e.value);

    return _ChartCard(
      icon: Icons.donut_large_rounded,
      title: L10n.t('Spending by Category'),
      subtitle: L10n.t('Tap a slice to see the entries'),
      child: sorted.isEmpty
          ? _InlineEmpty(message: L10n.t('No expenses in this period.'))
          : Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 132,
                      height: 132,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              final idx = response
                                  ?.touchedSection?.touchedSectionIndex;
                              if (event is FlTapUpEvent &&
                                  idx != null &&
                                  idx >= 0 &&
                                  idx < sorted.length) {
                                _openDrilldown(sorted[idx].key);
                              }
                              setState(() {
                                _touched = (!event.isInterestedForInteractions ||
                                        idx == null)
                                    ? -1
                                    : idx;
                              });
                            },
                          ),
                          // 2px gap so adjacent fills stay distinct.
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          sections: sorted.asMap().entries.map((e) {
                            final isTouched = e.key == _touched;
                            final pct =
                                total > 0 ? e.value.value / total : 0.0;
                            return PieChartSectionData(
                              value: e.value.value,
                              color: ChartPalette.forCategory(e.value.key),
                              radius: isTouched ? 40 : 32,
                              // Only label slices with room for the text.
                              title: pct > 0.08
                                  ? '${(pct * 100).round()}%'
                                  : '',
                              titleStyle: labelStyle(9,
                                  color: Colors.white, letterSpacing: 0.3),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Names in the legend mean identity is never colour-alone.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: sorted.map((e) {
                          final pct = total > 0
                              ? (e.value / total * 100).round()
                              : 0;
                          return InkWell(
                            onTap: () => _openDrilldown(e.key),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color:
                                          ChartPalette.forCategory(e.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_label(e.key),
                                        style: bodyStyle(12,
                                            weight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text('$pct%',
                                      style: labelStyle(10,
                                          letterSpacing: 0.3,
                                          color: MysticColors
                                              .onSurfaceVariant)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                    height: 1,
                    color: MysticColors.outlineVariant.withOpacity(0.2)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(L10n.t('TOTAL'),
                        style: labelStyle(10,
                            letterSpacing: 1.5,
                            color: MysticColors.onSurfaceVariant
                                .withOpacity(0.7))),
                    Text(_money(widget.svc.baseCurrency, total),
                        style: bodyStyle(15,
                            weight: FontWeight.w800,
                            color: MysticColors.onSurface)),
                  ],
                ),
              ],
            ),
    );
  }

  void _openDrilldown(TransactionCategory category) {
    final from = widget.range.from;
    final to = widget.range.to;
    final entries = widget.svc.transactions
        .where((t) => t.type == TransactionType.expense)
        .where((t) => t.category == category)
        .where((t) =>
            (from == null || !t.date.isBefore(from)) &&
            (to == null || t.date.isBefore(to)))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DrilldownSheet(
        title: _label(category),
        color: ChartPalette.forCategory(category),
        entries: entries,
        svc: widget.svc,
      ),
    );
  }
}

String _label(TransactionCategory cat) => cat.label;

// ── Drill-down sheet ──────────────────────────────────────────────────────────

class _DrilldownSheet extends StatelessWidget {
  final String title;
  final Color color;
  final List<Transaction> entries;
  final FinanceService svc;

  const _DrilldownSheet({
    required this.title,
    required this.color,
    required this.entries,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (s, t) => s + t.amountInBase);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: MysticColors.appBarBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MysticColors.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: headlineStyle(24,
                            italic: true, weight: FontWeight.w900)),
                  ),
                  Text(_money(svc.baseCurrency, total),
                      style: bodyStyle(15, weight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(child: _InlineEmpty(message: L10n.t('No entries.')))
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 18,
                        color: MysticColors.outlineVariant.withOpacity(0.25),
                      ),
                      itemBuilder: (context, i) {
                        final t = entries[i];
                        final account = svc.findAccount(t.accountId)?.name;
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title.isEmpty
                                        ? L10n.t('Untitled')
                                        : t.title,
                                    style: bodyStyle(14,
                                        weight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${L10n.date(t.date, 'MMM d, yyyy')}'
                                    '${account == null ? '' : ' · $account'}',
                                    style: labelStyle(9,
                                        letterSpacing: 0.3,
                                        color: MysticColors.onSurfaceVariant
                                            .withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${t.currency} '
                                    '${NumberFormat('#,##0.00').format(t.amount)}',
                                    style: bodyStyle(14,
                                        weight: FontWeight.w700)),
                                if (t.fee > 0)
                                  Text(
                                    '+ ${L10n.t('fee')} '
                                    '${NumberFormat('#,##0.00').format(t.fee)}',
                                    style: labelStyle(9,
                                        letterSpacing: 0.3,
                                        color: ChartPalette.orange),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fees card ─────────────────────────────────────────────────────────────────

class _FeesCard extends StatelessWidget {
  final FinanceService svc;
  final ({DateTime? from, DateTime? to}) range;
  final String label;
  const _FeesCard(
      {required this.svc, required this.range, required this.label});

  @override
  Widget build(BuildContext context) {
    final fees     = svc.feesInRange(from: range.from, to: range.to);
    final expenses = svc.expensesInRange(from: range.from, to: range.to);
    final share    = expenses > 0 ? (fees / (expenses + fees)) : 0.0;

    return _ChartCard(
      icon: Icons.percent_rounded,
      title: L10n.t('Lost to Fees'),
      subtitle: '${L10n.t('Bank and service charges')} · $label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_money(svc.baseCurrency, fees),
              style: headlineStyle(32,
                  italic: false,
                  weight: FontWeight.w900,
                  color: MysticColors.onSurface)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: MysticColors.outlineVariant.withOpacity(0.25),
              color: ChartPalette.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fees == 0
                ? L10n.t('No fees recorded in this period.')
                : '${(share * 100).toStringAsFixed(1)}% '
                    '${L10n.t('of everything you spent went to charges rather '
                        'than to what you bought.')}',
            style: bodyStyle(12, color: MysticColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Account distribution ──────────────────────────────────────────────────────

class _AccountDistribution extends StatelessWidget {
  final FinanceService svc;
  const _AccountDistribution({required this.svc});

  @override
  Widget build(BuildContext context) {
    final shares = svc.accountDistribution;
    final byCurrency = svc.balanceByCurrency;
    final maxV = shares.fold<double>(
        0, (m, s) => s.inBase.abs() > m ? s.inBase.abs() : m);

    // Colour is keyed to the account's stable position in the account list, so
    // re-sorting the bars by balance never repaints them.
    final order = {
      for (final (i, a) in svc.allAccounts.indexed) a.id: i,
    };

    return _ChartCard(
      icon: Icons.account_balance_wallet_outlined,
      title: L10n.t('Where Your Money Sits'),
      subtitle: '${L10n.t('Converted to')} ${svc.baseCurrency}',
      child: shares.isEmpty
          ? _InlineEmpty(
              message: svc.hasSavingsAccount
                  ? L10n.t('Spendable accounts hold nothing — '
                      'savings vaults are on the Savings screen.')
                  : L10n.t('No account holds a balance yet.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...shares.map((s) {
                  final frac = maxV > 0 ? (s.inBase.abs() / maxV) : 0.0;
                  final color = ChartPalette
                      .ordered[(order[s.account.id] ?? 0) % 8];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.account.name,
                                  style: bodyStyle(13,
                                      weight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              // Native amount first — that's what the user
                              // actually holds.
                              '${s.account.currency} '
                              '${NumberFormat('#,##0.00').format(s.native)}',
                              style: bodyStyle(13, weight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: frac,
                            minHeight: 6,
                            backgroundColor:
                                MysticColors.outlineVariant.withOpacity(0.22),
                            color: color,
                          ),
                        ),
                        if (s.account.currency != svc.baseCurrency) ...[
                          const SizedBox(height: 3),
                          Text(
                            '≈ ${_money(svc.baseCurrency, s.inBase)}',
                            style: labelStyle(9,
                                letterSpacing: 0.3,
                                color: MysticColors.onSurfaceVariant
                                    .withOpacity(0.6)),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (byCurrency.length > 1) ...[
                  const SizedBox(height: 4),
                  Container(
                      height: 1,
                      color: MysticColors.outlineVariant.withOpacity(0.2)),
                  const SizedBox(height: 10),
                  Text(L10n.t('HOLDINGS BY CURRENCY'),
                      style: labelStyle(9,
                          letterSpacing: 1.5,
                          color: MysticColors.onSurfaceVariant
                              .withOpacity(0.7))),
                  const SizedBox(height: 8),
                  ...byCurrency.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key,
                                style:
                                    bodyStyle(12, weight: FontWeight.w700)),
                            Text(
                              NumberFormat('#,##0.00').format(e.value),
                              style: bodyStyle(12,
                                  color: MysticColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}

// ── Shared chrome ─────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget>? legend;
  final Widget child;

  const _ChartCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: MysticColors.primary, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: headlineStyle(18,
                        italic: false, weight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: labelStyle(10,
                  letterSpacing: 1.0,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.65))),
          if (legend != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < legend!.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  legend![i],
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: labelStyle(10,
                letterSpacing: 0.5, color: MysticColors.onSurfaceVariant)),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final String message;
  const _InlineEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: bodyStyle(12,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.7))
              .copyWith(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 56, color: MysticColors.outlineVariant),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: headlineStyle(15,
                  italic: true,
                  weight: FontWeight.w600,
                  color: MysticColors.outline),
            ),
          ],
        ),
      ),
    );
  }
}
