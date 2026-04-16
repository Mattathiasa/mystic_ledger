import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/mystic_app_bar.dart';
import '../services/finance_service.dart';

enum GivingPeriod { total, monthly, weekly }

/// Tab 3 — Sacred Giving.
/// Shows income and the 10% tithe for the selected period,
/// with options for all-time, monthly, or weekly (Sunday church).
class GivingScreen extends StatefulWidget {
  const GivingScreen({super.key});

  @override
  State<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends State<GivingScreen> {
  GivingPeriod _period = GivingPeriod.total;

  String get _periodLabel {
    switch (_period) {
      case GivingPeriod.total:   return 'ALL TIME';
      case GivingPeriod.monthly: return 'THIS MONTH';
      case GivingPeriod.weekly:  return 'THIS WEEK';
    }
  }

  double _income(FinanceService svc) {
    switch (_period) {
      case GivingPeriod.total:   return svc.totalIncome;
      case GivingPeriod.monthly: return svc.monthlyIncome;
      case GivingPeriod.weekly:  return svc.weeklyIncome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: const MysticAppBar(),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          final income = _income(svc);
          final tithe = income * 0.1;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _GivingHeader(),
                const SizedBox(height: 24),
                _PeriodToggle(
                  selected: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
                const SizedBox(height: 24),
                _IncomeCard(income: income, periodLabel: _periodLabel),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _TitheCard(tithe: tithe, period: _period)),
                      const SizedBox(width: 16),
                      const Expanded(child: _CommitmentCard()),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _ArchivistNote(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Period toggle ─────────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  final GivingPeriod selected;
  final ValueChanged<GivingPeriod> onChanged;
  const _PeriodToggle({required this.selected, required this.onChanged});

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
            active: selected == GivingPeriod.total,
            onTap: () => onChanged(GivingPeriod.total),
          ),
          _Tab(
            label: 'Monthly',
            icon: Icons.calendar_month_outlined,
            active: selected == GivingPeriod.monthly,
            onTap: () => onChanged(GivingPeriod.monthly),
          ),
          _Tab(
            label: 'Weekly (Sunday)',
            icon: Icons.church_outlined,
            active: selected == GivingPeriod.weekly,
            onTap: () => onChanged(GivingPeriod.weekly),
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
  final String periodLabel;
  const _IncomeCard({required this.income, required this.periodLabel});

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
              offset: const Offset(0, 10),
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
                        'ETB ${fmt.format(income)}',
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
                  '"The ledger reflects a prosperous season. All ink points toward abundance."',
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

class _TitheCard extends StatelessWidget {
  final double tithe;
  final GivingPeriod period;
  const _TitheCard({required this.tithe, required this.period});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: MysticColors.outlineVariant.withOpacity(0.2)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: MysticColors.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                transform: Matrix4.rotationZ(-0.052), // -3 deg
                transformAlignment: Alignment.center,
                child: const Icon(Icons.volunteer_activism,
                    color: MysticColors.primary, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MysticColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    period == GivingPeriod.weekly ? 'SUNDAY OFFERING' : '10% TITHE',
                    style: labelStyle(9,
                        letterSpacing: 1.5,
                        color: MysticColors.onPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('CALCULATED PORTION',
              style: labelStyle(9,
                  letterSpacing: 1.5,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.7))),
          const SizedBox(height: 4),
          Text(
            'ETB ${fmt.format(tithe)}',
            style: headlineStyle(28,
                italic: false,
                weight: FontWeight.w900,
                color: MysticColors.primary),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: MysticColors.outlineVariant.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Tithe transfer recorded — Blessings upon the archive!',
                      style: bodyStyle(13, color: Colors.white),
                    ),
                    backgroundColor: MysticColors.secondary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MysticColors.primary,
                foregroundColor: MysticColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                shadowColor: MysticColors.primary.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Initiate Transfer',
                      style: headlineStyle(14,
                          italic: false, weight: FontWeight.w700,
                          color: MysticColors.onPrimary)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Commitment / progress card ────────────────────────────────────────────────

class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.009, // +0.5 deg
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: MysticColors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            // Decorative bubble icon bottom-right
            Positioned(
              bottom: -12,
              right: -12,
              child: Opacity(
                opacity: 0.15,
                child: Icon(Icons.bubble_chart,
                    size: 140, color: Colors.white),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commitment',
                        style: headlineStyle(18,
                            italic: true,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      'COMPLETION STATUS',
                      style: labelStyle(9,
                          letterSpacing: 1.2,
                          color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Progress ring
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CustomPaint(
                        painter: _ProgressRingPainter(progress: 1.0),
                        child: const Center(
                          child: Icon(Icons.check,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Done',
                              style: headlineStyle(26,
                                  italic: false,
                                  weight: FontWeight.w900,
                                  color: Colors.white)),
                          Text(
                            'Balanced & fulfilled for this cycle.',
                            style: bodyStyle(11,
                                    color: Colors.white.withOpacity(0.8))
                                .copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a circular progress arc on a semi-transparent background ring.
class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0

  const _ProgressRingPainter({required this.progress});

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
        ..color = Colors.white.withOpacity(0.2)
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
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}

// ── Archivist note ────────────────────────────────────────────────────────────

class _ArchivistNote extends StatelessWidget {
  const _ArchivistNote();

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
                RichText(
                  text: TextSpan(
                    style: bodyStyle(13,
                        color: MysticColors.onSurfaceVariant),
                    children: [
                      const TextSpan(
                          text: 'Historically, your '),
                      WidgetSpan(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: MysticColors.primaryContainer
                                    .withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text('sacred giving',
                              style: bodyStyle(13,
                                      weight: FontWeight.w700,
                                      color: MysticColors.onSurface)
                                  .copyWith(fontStyle: FontStyle.italic)),
                        ),
                      ),
                      const TextSpan(
                          text:
                              ' has increased the flow of secondary assets by 12% in subsequent moons. This selfless ledger entry maintains the harmony of your personal estate.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
