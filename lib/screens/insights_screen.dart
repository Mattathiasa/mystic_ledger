import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/mystic_app_bar.dart';
import '../services/finance_service.dart';
import '../models/transaction.dart';

/// Tab 4 — Insights / Reports.
/// Visual charts: monthly bar chart, category donut, top expenditures.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: const MysticAppBar(),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          if (svc.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: MysticColors.primary));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InsightsHeader(svc: svc),
                const SizedBox(height: 32),
                _MonthlyBarChart(svc: svc),
                const SizedBox(height: 32),
                _CategoryDonut(svc: svc),
                const SizedBox(height: 32),
                _TopExpenditures(svc: svc),
                const SizedBox(height: 32),
                _InsightFooter(svc: svc),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Header summary ────────────────────────────────────────────────────────────

class _InsightsHeader extends StatelessWidget {
  final FinanceService svc;
  const _InsightsHeader({required this.svc});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MONTHLY OBSERVATIONS',
            style: labelStyle(10,
                letterSpacing: 2.0,
                color: MysticColors.onSurfaceVariant.withOpacity(0.7))),
        const SizedBox(height: 8),
        Text('Insights',
            style: headlineStyle(48, italic: true, weight: FontWeight.w900)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'INCOME',
                value: 'ETB ${fmt.format(svc.monthlyIncome)}',
                color: MysticColors.secondary,
                rotation: 0.005,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'EXPENSES',
                value: 'ETB ${fmt.format(svc.totalExpenses)}',
                color: MysticColors.tertiary,
                rotation: -0.009,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'BALANCE',
                value: 'ETB ${fmt.format(svc.balance)}',
                color: MysticColors.primary,
                rotation: 0.004,
                highlight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double rotation;
  final bool highlight;
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.rotation,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight
              ? MysticColors.surfaceContainerHighest
              : MysticColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: MysticColors.onSurface.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: labelStyle(8,
                    letterSpacing: 1.2,
                    color: MysticColors.onSurface.withOpacity(0.6))),
            const SizedBox(height: 6),
            Text(value,
                style: bodyStyle(14, weight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Monthly bar chart (income vs expense, last 6 months) ─────────────────────

class _MonthlyBarChart extends StatelessWidget {
  final FinanceService svc;
  const _MonthlyBarChart({required this.svc});

  @override
  Widget build(BuildContext context) {
    final months = svc.lastNMonths(6);
    double maxY = 0.0;
    for (final s in months) {
      if (s.income > maxY) maxY = s.income;
      if (s.expenses > maxY) maxY = s.expenses;
    }
    final double yMax = maxY > 0 ? (maxY * 1.25).ceilToDouble() : 1000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: MysticColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Income vs Expenses',
                  style: headlineStyle(18, italic: false, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Last 6 months',
              style: labelStyle(10,
                  letterSpacing: 1.2,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          const SizedBox(height: 20),
          // Legend
          Row(
            children: [
              _LegendDot(color: MysticColors.secondary, label: 'Income'),
              const SizedBox(width: 16),
              _LegendDot(color: MysticColors.tertiary, label: 'Expenses'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: yMax,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: MysticColors.onSurface.withOpacity(0.07),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: yMax / 4,
                      getTitlesWidget: (val, meta) {
                        if (val == 0 || val == meta.max) return const SizedBox.shrink();
                        final label = val >= 1000
                            ? '${(val / 1000).toStringAsFixed(0)}k'
                            : val.toStringAsFixed(0);
                        return Text(label,
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
                        final idx = val.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM').format(months[idx].month),
                            style: labelStyle(9,
                                color: MysticColors.onSurfaceVariant
                                    .withOpacity(0.7)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: months.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.income,
                        color: MysticColors.secondary,
                        width: 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: e.value.expenses,
                        color: MysticColors.tertiary,
                        width: 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        MysticColors.surfaceContainerHighest.withOpacity(0.95),
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, _, rod, rodIdx) {
                      final label = rodIdx == 0 ? 'Income' : 'Expenses';
                      return BarTooltipItem(
                        '$label\nETB ${NumberFormat('#,##0').format(rod.toY)}',
                        bodyStyle(12,
                            weight: FontWeight.w600,
                            color: rodIdx == 0
                                ? MysticColors.secondary
                                : MysticColors.tertiary),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
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
          width: 10,
          height: 10,
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

// ── Category donut chart ──────────────────────────────────────────────────────

class _CategoryDonut extends StatefulWidget {
  final FinanceService svc;
  const _CategoryDonut({required this.svc});

  @override
  State<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<_CategoryDonut> {
  int _touchedIndex = -1;

  static const _palette = [
    MysticColors.primary,
    MysticColors.secondary,
    MysticColors.tertiary,
    Color(0xFF8D6E63),
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF9A9A),
    Color(0xFFFFA726),
  ];

  @override
  Widget build(BuildContext context) {
    final data = widget.svc.expensesByCategory;
    if (data.isEmpty) return const SizedBox.shrink();

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0.0, (s, e) => s + e.value);
    final fmt = NumberFormat('#,##0.00');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.donut_large_rounded,
                  color: MysticColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Spending by Category',
                  style: headlineStyle(18,
                      italic: false, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Where did your money go?',
              style: labelStyle(10,
                  letterSpacing: 1.2,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response?.touchedSection == null) {
                            _touchedIndex = -1;
                          } else {
                            _touchedIndex =
                                response!.touchedSection!.touchedSectionIndex;
                          }
                        });
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 38,
                    sections: sorted.asMap().entries.map((e) {
                      final isTouched = e.key == _touchedIndex;
                      final pct = total > 0 ? e.value.value / total : 0;
                      final color = _palette[e.key % _palette.length];
                      return PieChartSectionData(
                        value: e.value.value,
                        color: color,
                        radius: isTouched ? 38 : 30,
                        title: pct > 0.08
                            ? '${(pct * 100).toStringAsFixed(0)}%'
                            : '',
                        titleStyle: labelStyle(9,
                            color: Colors.white, letterSpacing: 0.3),
                        badgeWidget: null,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sorted.asMap().entries.map((e) {
                    final color = _palette[e.key % _palette.length];
                    final pct = total > 0
                        ? (e.value.value / total * 100).toStringAsFixed(0)
                        : '0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _catLabel(e.value.key),
                              style: bodyStyle(12,
                                  weight: FontWeight.w600,
                                  color: MysticColors.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: labelStyle(10,
                                letterSpacing: 0.3,
                                color: MysticColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
              height: 1,
              color: MysticColors.outlineVariant.withOpacity(0.15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL EXPENSES',
                  style: labelStyle(10,
                      letterSpacing: 1.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              Text('ETB ${fmt.format(total)}',
                  style: bodyStyle(15,
                      weight: FontWeight.w700, color: MysticColors.tertiary)),
            ],
          ),
        ],
      ),
    );
  }

  String _catLabel(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:          return 'Food';
      case TransactionCategory.transport:     return 'Transport';
      case TransactionCategory.utilities:     return 'Utilities';
      case TransactionCategory.entertainment: return 'Entertainment';
      case TransactionCategory.tithe:         return 'Tithe';
      case TransactionCategory.salary:        return 'Salary';
      case TransactionCategory.freelance:     return 'Freelance';
      case TransactionCategory.other:         return 'Other';
    }
  }
}

// ── Top expenditures ──────────────────────────────────────────────────────────

class _TopExpenditures extends StatelessWidget {
  final FinanceService svc;
  const _TopExpenditures({required this.svc});

  @override
  Widget build(BuildContext context) {
    final byCategory = svc.expensesByCategory;
    if (byCategory.isEmpty) return const SizedBox.shrink();

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final total = svc.totalExpenses;
    final fmt = NumberFormat('#,##0.00');

    final counts = <TransactionCategory, int>{};
    for (final t in svc.transactions) {
      if (t.type == TransactionType.expense) {
        counts[t.category] = (counts[t.category] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TOP EXPENDITURES',
            style: labelStyle(10,
                letterSpacing: 2.0,
                color: MysticColors.onSurface.withOpacity(0.5))),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: MysticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: MysticColors.outlineVariant.withOpacity(0.12)),
          ),
          child: Column(
            children: top.asMap().entries.map((e) {
              final cat = e.value.key;
              final amount = e.value.value;
              final pct = total > 0
                  ? ((amount / total) * 100).toStringAsFixed(0)
                  : '0';
              final count = counts[cat] ?? 0;
              final isLast = e.key == top.length - 1;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color:
                                  MysticColors.outlineVariant.withOpacity(0.15)),
                        ),
                      ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MysticColors.primaryContainer.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_catIcon(cat),
                          color: MysticColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_catLabel(cat),
                              style: bodyStyle(14, weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? amount / total : 0,
                              minHeight: 4,
                              backgroundColor:
                                  MysticColors.outlineVariant.withOpacity(0.2),
                              color: MysticColors.tertiary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count transaction${count != 1 ? 's' : ''}',
                            style: labelStyle(9,
                                color: MysticColors.onSurfaceVariant
                                    .withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('ETB ${fmt.format(amount)}',
                            style: bodyStyle(14,
                                weight: FontWeight.w700,
                                color: MysticColors.tertiary)),
                        Text('$pct%',
                            style: labelStyle(10,
                                letterSpacing: 0.5,
                                color:
                                    MysticColors.onSurface.withOpacity(0.4))),
                      ],
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

  String _catLabel(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:          return 'Daily Sustenance';
      case TransactionCategory.transport:     return 'Carriage & Stable';
      case TransactionCategory.utilities:     return 'The Hearth';
      case TransactionCategory.entertainment: return 'Vices & Joy';
      case TransactionCategory.tithe:         return 'Sacred Tithe';
      case TransactionCategory.salary:        return 'Salary';
      case TransactionCategory.freelance:     return 'Grimoire Sales';
      case TransactionCategory.other:         return 'Miscellany';
    }
  }

  IconData _catIcon(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:          return Icons.restaurant_outlined;
      case TransactionCategory.transport:     return Icons.directions_car_outlined;
      case TransactionCategory.utilities:     return Icons.home_outlined;
      case TransactionCategory.entertainment: return Icons.celebration_outlined;
      case TransactionCategory.tithe:         return Icons.volunteer_activism;
      case TransactionCategory.salary:        return Icons.work_outline;
      case TransactionCategory.freelance:     return Icons.auto_stories_outlined;
      case TransactionCategory.other:         return Icons.category_outlined;
    }
  }
}

// ── Insight footer ────────────────────────────────────────────────────────────

class _InsightFooter extends StatelessWidget {
  final FinanceService svc;
  const _InsightFooter({required this.svc});

  @override
  Widget build(BuildContext context) {
    final byCategory = svc.expensesByCategory;
    if (byCategory.isEmpty) return const SizedBox.shrink();

    final topCat = (byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;

    final label = switch (topCat) {
      TransactionCategory.food          => 'Sustenance',
      TransactionCategory.transport     => 'Carriage',
      TransactionCategory.utilities     => 'The Hearth',
      TransactionCategory.entertainment => 'Vices & Joy',
      _                                 => 'Tithe',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -8,
              left: -8,
              child: Transform.rotate(
                angle: -0.26,
                child: Icon(Icons.star,
                    color: MysticColors.primary.withOpacity(0.4), size: 20),
              ),
            ),
            Text(
              '"The stars suggest your gold flows most freely toward $label this moon."',
              textAlign: TextAlign.center,
              style: bodyStyle(13, color: MysticColors.onSurface.withOpacity(0.7))
                  .copyWith(fontStyle: FontStyle.italic),
            ),
            Positioned(
              bottom: -8,
              right: -8,
              child: Transform.rotate(
                angle: 0.26,
                child: Icon(Icons.auto_awesome,
                    color: MysticColors.primary.withOpacity(0.4), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
