import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/mystic_app_bar.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/account_edit_sheet.dart';
import '../services/finance_service.dart';
import '../models/account_model.dart';
import 'transfer_screen.dart';
import 'savings_screen.dart';
import 'debt_screen.dart';
import 'add_account_screen.dart';
import 'budget_screen.dart';
import 'transfer_history_screen.dart';

/// Tab 5 — Finance Hub.
/// Central gateway to Transfers, Savings, Debts, and Account management.
class FinanceHubScreen extends StatelessWidget {
  const FinanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: const MysticAppBar(),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          final fmt = NumberFormat('#,##0.00');

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────
                Text(
                  'FINANCIAL INSTRUMENTS',
                  style: labelStyle(10,
                      letterSpacing: 2.0,
                      color:
                          MysticColors.onSurfaceVariant.withOpacity(0.7)),
                ),
                const SizedBox(height: 8),
                Text('Finance',
                    style:
                        headlineStyle(48, italic: true, weight: FontWeight.w900)),
                const SizedBox(height: 32),

                // ── Quick action tiles ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Transfer',
                        subtitle: 'Move between vaults',
                        color: MysticColors.primary,
                        bgColor: MysticColors.surfaceContainerLow,
                        rotation: -0.012,
                        onTap: () => Navigator.of(context).push(
                          _slide(const TransferScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.savings_outlined,
                        label: 'Savings',
                        subtitle: 'Vault deposits',
                        color: MysticColors.secondary,
                        bgColor: MysticColors.surfaceContainerHigh,
                        rotation: 0.012,
                        onTap: () => Navigator.of(context).push(
                          _slide(const SavingsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.handshake_outlined,
                        label: 'Debts',
                        subtitle: 'Track obligations',
                        color: MysticColors.tertiary,
                        bgColor: MysticColors.surfaceContainer,
                        rotation: -0.008,
                        onTap: () => Navigator.of(context).push(
                          _slide(const DebtScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.add_card_outlined,
                        label: 'Add Account',
                        subtitle: 'Open new vault',
                        color: MysticColors.primary,
                        bgColor: MysticColors.surfaceContainerLow,
                        rotation: 0.008,
                        onTap: () => Navigator.of(context).push(
                          _slide(const AddAccountScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.assignment_outlined,
                        label: 'Budgets',
                        subtitle: 'Set spending limits',
                        color: MysticColors.secondary,
                        bgColor: MysticColors.surfaceContainerHigh,
                        rotation: 0.004,
                        onTap: () => Navigator.of(context).push(
                          _slide(const BudgetScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.history,
                        label: 'Transfer Record',
                        subtitle: 'History & reverse',
                        color: MysticColors.tertiary,
                        bgColor: MysticColors.surfaceContainer,
                        rotation: -0.006,
                        onTap: () => Navigator.of(context).push(
                          _slide(const TransferHistoryScreen()),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ── Savings snapshot ────────────────────────────────────
                _SavingsSnapshot(
                  summary: svc.savingsSummary,
                  fmt: fmt,
                  onTap: () => Navigator.of(context)
                      .push(_slide(const SavingsScreen())),
                ),

                const SizedBox(height: 32),

                // ── All accounts ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('All Accounts',
                        style: headlineStyle(24,
                            italic: true, weight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .push(_slide(const AddAccountScreen())),
                      child: Text('+ ADD',
                          style: labelStyle(10,
                              letterSpacing: 1.5,
                              color: MysticColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AccountsList(svc: svc, fmt: fmt),

                const SizedBox(height: 32),

                // ── Debt snapshot ───────────────────────────────────────
                _DebtSnapshot(
                  currency: svc.baseCurrency,
                  iOweCount: svc.iOwe.length,
                  owedToMeCount: svc.owedToMe.length,
                  iOweTotal:
                      svc.iOwe.fold(0.0, (s, d) => s + d.amount),
                  owedToMeTotal:
                      svc.owedToMe.fold(0.0, (s, d) => s + d.amount),
                  fmt: fmt,
                  onTap: () =>
                      Navigator.of(context).push(_slide(const DebtScreen())),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PageRoute _slide(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final double rotation;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.rotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: MysticColors.outlineVariant.withOpacity(0.15)),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(label,
                  style: headlineStyle(16,
                      italic: false, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: labelStyle(9,
                      letterSpacing: 0.5,
                      color: MysticColors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Savings snapshot card ─────────────────────────────────────────────────────

class _SavingsSnapshot extends StatelessWidget {
  final SavingsSummary summary;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _SavingsSnapshot({
    required this.summary,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.accounts.length > 1
                        ? 'SAVINGS VAULTS'
                        : 'SAVINGS VAULT',
                    style: labelStyle(9,
                        letterSpacing: 1.5,
                        color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    // ≈ when the vaults hold different currencies and the
                    // total had to be converted to get to one number.
                    '${summary.converted ? '≈ ' : ''}${summary.currency} '
                    '${fmt.format(summary.amount)}',
                    style: headlineStyle(32,
                        italic: false,
                        weight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.isEmpty
                        ? 'Tap to open your first vault →'
                        : 'Tap to view deposits →',
                    style: bodyStyle(12, color: Colors.white.withOpacity(0.6))
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const Opacity(
              opacity: 0.2,
              child: Icon(Icons.savings,
                  size: 72, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Accounts list ─────────────────────────────────────────────────────────────

class _AccountsList extends StatelessWidget {
  final FinanceService svc;
  final NumberFormat fmt;
  const _AccountsList({required this.svc, required this.fmt});

  static const _colors = [
    MysticColors.primary,
    MysticColors.secondary,
    MysticColors.tertiary,
  ];

  @override
  Widget build(BuildContext context) {
    final all      = svc.allAccounts;
    final active   = all.where((a) => a.isActive).toList();
    final inactive = all.where((a) => !a.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Active accounts
        Container(
          decoration: BoxDecoration(
            color: MysticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: MysticColors.onSurface.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: active.isEmpty
              ? const NoAccountsCard(
                  headline: 'No active accounts',
                  body: 'Add a vault to start recording against it.',
                )
              : Column(
                  children: active.asMap().entries.map((e) {
                    final idx    = e.key;
                    final acc    = e.value;
                    final isLast = idx == active.length - 1;
                    final color  = _colors[idx % _colors.length];
                    final bal    = svc.accountBalance(acc.id);

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
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(acc.icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(acc.name,
                                    style:
                                        bodyStyle(14, weight: FontWeight.w700)),
                                Text(acc.typeLabel,
                                    style: labelStyle(9, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                          Text('${acc.currency} ${fmt.format(bal)}',
                              style: bodyStyle(14,
                                  weight: FontWeight.w700, color: color)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _showEditSheet(context, svc, acc),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.more_horiz,
                                  size: 18,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.5)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        // Hidden accounts section
        if (inactive.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('HIDDEN ACCOUNTS',
              style: labelStyle(10,
                  letterSpacing: 2.0,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: MysticColors.surfaceContainerLow.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: MysticColors.outlineVariant.withOpacity(0.15),
                  style: BorderStyle.solid),
            ),
            child: Column(
              children: inactive.asMap().entries.map((e) {
                final acc    = e.value;
                final isLast = e.key == inactive.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: isLast
                      ? null
                      : BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: MysticColors.outlineVariant
                                    .withOpacity(0.15)),
                          ),
                        ),
                  child: Row(
                    children: [
                      Icon(acc.icon,
                          size: 20,
                          color:
                              MysticColors.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(acc.name,
                                style: bodyStyle(14,
                                    weight: FontWeight.w600,
                                    color: MysticColors.onSurfaceVariant
                                        .withOpacity(0.5))),
                            Text(acc.typeLabel,
                                style: labelStyle(9,
                                    letterSpacing: 0.5,
                                    color: MysticColors.onSurfaceVariant
                                        .withOpacity(0.4))),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => reportIfWriteFails(
                            ScaffoldMessenger.maybeOf(context),
                            svc.reactivateAccount(acc.id)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('RESTORE',
                            style: labelStyle(9,
                                letterSpacing: 1.2,
                                color: MysticColors.primary)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  void _showEditSheet(BuildContext context, FinanceService svc, Account acc) =>
      showAccountEditSheet(context, svc, acc);
}

// ── Debt snapshot ─────────────────────────────────────────────────────────────

class _DebtSnapshot extends StatelessWidget {
  final String currency;
  final int iOweCount;
  final int owedToMeCount;
  final double iOweTotal;
  final double owedToMeTotal;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _DebtSnapshot({
    required this.currency,
    required this.iOweCount,
    required this.owedToMeCount,
    required this.iOweTotal,
    required this.owedToMeTotal,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Debt Overview',
                style:
                    headlineStyle(24, italic: true, weight: FontWeight.w700)),
            TextButton(
              onPressed: onTap,
              child: Text('VIEW ALL',
                  style: labelStyle(10,
                      letterSpacing: 1.5, color: MysticColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DebtStat(
                label: 'I OWE',
                currency: currency,
                count: iOweCount,
                total: iOweTotal,
                color: MysticColors.tertiary,
                fmt: fmt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DebtStat(
                label: 'OWED TO ME',
                currency: currency,
                count: owedToMeCount,
                total: owedToMeTotal,
                color: MysticColors.secondary,
                fmt: fmt,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DebtStat extends StatelessWidget {
  final String label;
  final String currency;
  final int count;
  final double total;
  final Color color;
  final NumberFormat fmt;

  const _DebtStat({
    required this.label,
    required this.currency,
    required this.count,
    required this.total,
    required this.color,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: MysticColors.onSurface.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: labelStyle(9, letterSpacing: 1.5, color: color)),
          const SizedBox(height: 8),
          Text(
            '$currency ${fmt.format(total)}',
            style: headlineStyle(20,
                italic: false, weight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            '$count pending',
            style: labelStyle(9, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
