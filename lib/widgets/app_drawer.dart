import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../services/user_service.dart';
import '../services/l10n.dart';
import '../models/user_model.dart';
import '../widgets/app_theme.dart';
import '../screens/profile_screen.dart';
import '../screens/transfer_screen.dart';
import '../screens/savings_screen.dart';
import '../screens/debt_screen.dart';
import '../screens/add_account_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/currency_settings_screen.dart';
import '../screens/recurring_screen.dart';

/// Side drawer opened by the hamburger icon in the app bar.
/// Shows user profile summary, quick nav, and settings.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark mode or the language flips: the palette and strings
    // live in mutable statics, so const widget instances would skip us.
    Theme.of(context);
    Localizations.localeOf(context);

    final auth    = AuthService();
    final uid     = auth.currentUser?.uid ?? '';
    final svc     = context.watch<FinanceService>();
    final fmt     = NumberFormat('#,##0.00');

    return Drawer(
      backgroundColor: MysticColors.background,
      child: StreamBuilder<UserModel?>(
        stream: UserService().userStream(uid),
        builder: (context, snap) {
          final user = snap.data;
          final initials = user != null && user.name.trim().isNotEmpty
              ? user.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase()
              : '?';

          return Column(
            children: [
              // ── Profile header ──────────────────────────────────────
              _DrawerHeader(
                initials: initials,
                name: user?.name ?? '—',
                email: user?.email ?? auth.currentUser?.email ?? '—',
                balance: svc.totalBalance,
                currency: svc.baseCurrency,
                hidden: svc.totalHidden,
                fmt: fmt,
                onProfileTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()));
                },
              ),

              // ── Nav items ────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _SectionLabel(L10n.t('FINANCIAL TOOLS')),
                    _DrawerTile(
                      icon: Icons.swap_horiz_rounded,
                      label: L10n.t('Transfer Funds'),
                      onTap: () => _push(context, const TransferScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.savings_outlined,
                      label: L10n.t('Savings Vault'),
                      onTap: () => _push(context, const SavingsScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.handshake_outlined,
                      label: L10n.t('Debt Ledger'),
                      onTap: () => _push(context, const DebtScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.add_card_outlined,
                      label: L10n.t('Add Account'),
                      onTap: () => _push(context, const AddAccountScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.assignment_outlined,
                      label: L10n.t('Budget Scrolls'),
                      onTap: () => _push(context, const BudgetScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.repeat,
                      label: L10n.t('Recurring'),
                      onTap: () => _push(context, const RecurringScreen()),
                    ),

                    const SizedBox(height: 8),
                    _Divider(),
                    const SizedBox(height: 8),

                    _SectionLabel(L10n.t('SETTINGS')),
                    _DrawerTile(
                      icon: Icons.account_circle_outlined,
                      label: L10n.t('My Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()));
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.currency_exchange,
                      label: L10n.t('Currency & rates'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MysticColors.primaryContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                            context.watch<FinanceService>().baseCurrency,
                            style: labelStyle(8, letterSpacing: 1.0,
                                color: MysticColors.primary)),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CurrencySettingsScreen()));
                      },
                    ),

                    const SizedBox(height: 8),
                    _Divider(),
                    const SizedBox(height: 8),

                    // Sign out
                    _DrawerTile(
                      icon: Icons.logout,
                      label: L10n.t('Sign Out'),
                      labelColor: MysticColors.tertiary,
                      iconColor: MysticColors.tertiary,
                      onTap: () async {
                        Navigator.pop(context);
                        await auth.signOut();
                      },
                    ),
                  ],
                ),
              ),

              // ── App version footer ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: MysticColors.primaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      L10n.t("Mystic Ledger  v1.1.0  ·  The Archivist's Grimoire"),
                      style: labelStyle(8,
                          letterSpacing: 0.8,
                          color: MysticColors.onSurfaceVariant.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _push(BuildContext ctx, Widget screen) {
    Navigator.pop(ctx);
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
  }
}

// ── Drawer header ─────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final double balance;
  final String currency;
  final bool hidden;
  final NumberFormat fmt;
  final VoidCallback onProfileTap;

  const _DrawerHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.balance,
    required this.currency,
    required this.hidden,
    required this.fmt,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 20, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF292520), // journal cover dark
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: MysticColors.primaryContainer.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                    color: MysticColors.primaryContainer.withOpacity(0.4),
                    width: 1.5),
              ),
              child: Center(
                child: Text(
                  initials.toUpperCase(),
                  style: headlineStyle(20,
                      italic: false,
                      weight: FontWeight.w900,
                      color: MysticColors.primaryContainer),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(name,
                style: headlineStyle(18,
                    italic: false,
                    weight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(email,
                style: bodyStyle(12,
                    color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  hidden ? '••••••' : '$currency ${fmt.format(balance)}',
                  style: bodyStyle(15,
                      weight: FontWeight.w700,
                      color: MysticColors.primaryContainer),
                ),
                const SizedBox(width: 6),
                Text(L10n.t('total balance'),
                    style: bodyStyle(11,
                        color: Colors.white.withOpacity(0.4))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared drawer components ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(text,
          style: labelStyle(9,
              letterSpacing: 2.0,
              color: MysticColors.onSurfaceVariant.withOpacity(0.5))),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          size: 20,
          color: iconColor ?? MysticColors.onSurfaceVariant.withOpacity(0.6)),
      title: Text(
        label,
        style: bodyStyle(14,
            weight: FontWeight.w600,
            color: labelColor ?? MysticColors.onSurface),
      ),
      trailing: trailing,
      dense: true,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
            height: 1,
            color: MysticColors.outlineVariant.withOpacity(0.2)),
      );
}
