import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/mystic_app_bar.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state_card.dart';
import '../services/finance_service.dart';
import '../services/sms_capture_service.dart';
import '../services/l10n.dart';
import '../models/account_model.dart';
import 'main_scaffold.dart';
import 'new_entry_screen.dart';
import 'captured_screen.dart';
import 'account_detail_screen.dart';

/// The entry form's slide-up transition.
///
/// Shared so that opening an entry to amend it feels like the same surface as
/// writing one — the two used to differ because the FAB built its route inline.
Route<T> entrySlideUpRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 400),
    );

/// Tab 1 — Dashboard.
/// Shows total balance, per-account cards, and the 5 most recent transactions.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

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
              child: CircularProgressIndicator(color: MysticColors.primary),
            );
          }
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Non-const on purpose: must rebuild on theme/locale change.
                    // ignore: prefer_const_constructors
                    _CaptureBanner(),
                    _BalanceHero(svc: svc),
                    const SizedBox(height: 40),
                    _AccountSection(svc: svc),
                    const SizedBox(height: 40),
                    _RecentSection(svc: svc),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: _AddFab(
                  onTap: () => Navigator.of(context)
                      .push(entrySlideUpRoute(const NewEntryScreen())),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── SMS capture banner ────────────────────────────────────────────────────────

/// Shown only while captured Telebirr messages are waiting to be reviewed.
/// Tapping it opens the review queue.
class _CaptureBanner extends StatelessWidget {
  const _CaptureBanner();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SmsCaptureService.instance,
      builder: (context, _) {
        final count = SmsCaptureService.instance.pendingCount;
        if (count == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CapturedScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: MysticColors.primaryContainer.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: MysticColors.primary.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MysticColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.mark_email_unread_outlined,
                        color: MysticColors.primary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count == 1
                              ? L10n.t('A transaction waits to be recorded')
                              : '$count ${L10n.t('transactions wait to be recorded')}',
                          style: headlineStyle(15,
                              italic: false, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          L10n.t('Captured from Telebirr, CBE & Awash — review '
                              'before they enter the ledger'),
                          style: bodyStyle(12,
                              color: MysticColors.onSurfaceVariant
                                  .withOpacity(0.75)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: MysticColors.primary, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Balance hero ──────────────────────────────────────────────────────────────

class _BalanceHero extends StatelessWidget {
  final FinanceService svc;
  const _BalanceHero({required this.svc});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final hidden = svc.totalHidden;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              L10n.t('CURRENT OBSERVATIONS'),
              style: labelStyle(10,
                  letterSpacing: 2.0,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.7)),
            ),
            // Hiding masks the total AND every account at once; each account
            // card's own eye reveals that one balance alone.
            Tooltip(
              message: L10n.t('Tap to hide or show every amount — each '
                  'account\'s eye reveals it alone.'),
              child: GestureDetector(
                // Hiding masks everything; a tap while the total is still
                // hidden restores all of it in one go (accounts revealed
                // individually stay revealed until then).
                onTap: () =>
                    svc.totalHidden ? svc.showAll() : svc.hideAll(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.6),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(L10n.t('My Ledger'),
            style: headlineStyle(48, italic: true, weight: FontWeight.w900)),
        const SizedBox(height: 16),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Transform.rotate(
                angle: -0.008,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: MysticColors.primaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '${svc.baseCurrency} ',
                  style: bodyStyle(28,
                      weight: FontWeight.w700,
                      color: MysticColors.primary.withOpacity(0.6)),
                ),
                TextSpan(
                  text: hidden ? '••••••' : fmt.format(svc.totalBalance),
                  style: bodyStyle(42, weight: FontWeight.w700),
                ),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: MysticColors.primaryContainer, width: 2),
            ),
          ),
          child: Text(
            L10n.t('"The ledger reflects what the season has given, and what '
                'it has taken."'),
            style: bodyStyle(13, color: MysticColors.onSurfaceVariant)
                .copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

// ── Account cards (dynamic) ───────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  final FinanceService svc;
  const _AccountSection({required this.svc});

  // Colour palette cycling for dynamic bank accounts
  static List<Color> get _iconColors => [
        MysticColors.primary,
        MysticColors.secondary,
        MysticColors.tertiary,
      ];
  static List<Color> get _bgColors => [
        MysticColors.surfaceContainerLow,
        MysticColors.surfaceContainerHigh,
        MysticColors.surfaceContainer,
      ];
  static const _rotations = [-0.009, 0.014, -0.005, 0.008];

  @override
  Widget build(BuildContext context) {
    // Show all non-savings accounts
    final visible = svc.accounts
        .where((a) => a.type != AccountType.savings)
        .toList();

    final cards = visible.asMap().entries.map((e) {
      final idx  = e.key;
      final acc  = e.value;
      final rot  = _rotations[idx % _rotations.length];
      final ic   = _iconColors[idx % _iconColors.length];
      final bg   = _bgColors[idx % _bgColors.length];
      final bal  = svc.accountBalance(acc.id);
      final fmt  = NumberFormat('#,##0.00');
      // Each account masks independently of the others and of the total.
      final hidden = svc.isAccountHidden(acc.id);

      return _AccountCard(
        label: acc.name,
        badge: acc.typeLabel,
        balance: bal,
        balanceText:
            hidden ? '••••••' : '${acc.currency} ${fmt.format(bal)}',
        hidden: hidden,
        onToggleHide: () => svc.toggleAccountVisibility(acc.id),
        icon: acc.icon,
        iconColor: ic,
        bgColor: bg,
        rotation: rot,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AccountDetailScreen(account: acc)),
        ),
      );
    }).toList();

    // The ledger starts genuinely empty — nothing is created at sign-up — so
    // this is the app's front door, not a rare edge case. A blank gap here
    // leaves a new user with nowhere to go.
    if (cards.isEmpty) {
      return NoAccountsCard(
        headline: L10n.t('No vaults yet'),
        body: L10n.t('Add the accounts you actually keep money in — a bank, '
            'mobile money, cash in hand — and the ledger fills itself from '
            'there.'),
      );
    }

    // Layout: pairs in rows, last card full-width if odd count
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += 2) {
      if (i + 1 < cards.length) {
        rows.add(Row(children: [
          Expanded(child: cards[i]),
          const SizedBox(width: 12),
          Expanded(child: cards[i + 1]),
        ]));
      } else {
        rows.add(cards[i]);
      }
      if (i + 2 < cards.length) rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }
}

class _AccountCard extends StatelessWidget {
  final String label;
  final String badge;
  final double balance;
  final String balanceText;
  final bool hidden;
  final VoidCallback onToggleHide;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double rotation;

  /// Opens the account editor. The eye icon keeps its own handler, so tapping
  /// it hides the balance rather than opening the sheet.
  final VoidCallback onTap;

  const _AccountCard({
    required this.label,
    required this.badge,
    required this.balance,
    required this.balanceText,
    required this.hidden,
    required this.onToggleHide,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.rotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: MysticColors.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(badge,
                          style: labelStyle(9, letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 6),
                    // Each account hides independently of the rest.
                    // Padded out to a usable target: at all(2) this was ~19dp,
                    // and it now sits inside a card that is itself tappable, so
                    // a near-miss would change screens instead of toggling.
                    GestureDetector(
                      onTap: onToggleHide,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          hidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 15,
                          color: MysticColors.onSurfaceVariant
                              .withOpacity(hidden ? 0.75 : 0.35),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(label,
                style:
                    headlineStyle(16, italic: false, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(balanceText,
                style: bodyStyle(20,
                    weight: FontWeight.w700, color: iconColor)),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Recent entries ────────────────────────────────────────────────────────────

class _RecentSection extends StatelessWidget {
  final FinanceService svc;
  const _RecentSection({required this.svc});

  @override
  Widget build(BuildContext context) {
    final recent = svc.recentTransactions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(L10n.t('Recent Entries'),
                style:
                    headlineStyle(28, italic: true, weight: FontWeight.w700)),
            TextButton(
              onPressed: () =>
                  MainShell.maybeOf(context)?.goToTab(MainScaffold.tabLedger),
              child: Text(
                L10n.t('VIEW ARCHIVES'),
                style:
                    labelStyle(10, letterSpacing: 1.5, color: MysticColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.auto_stories_outlined,
                      size: 56, color: MysticColors.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    L10n.t('Your ledger awaits its first entry'),
                    style: headlineStyle(15,
                        italic: true,
                        weight: FontWeight.w600,
                        color: MysticColors.outline),
                  ),
                ],
              ),
            ),
          )
        else
          ...recent.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Builder(
                  builder: (context) => TransactionTile(
                    transaction: t,
                    accountName: svc.findAccount(t.accountId)?.name,
                    onTap: () => Navigator.of(context)
                        .push(entrySlideUpRoute(NewEntryScreen(existing: t))),
                  ),
                ),
              )),
      ],
    );
  }
}

// ── Floating action button ────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: MysticColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: MysticColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: MysticColors.onPrimary, size: 22),
            const SizedBox(width: 8),
            Text(L10n.t('ADD ENTRY'),
                style:
                    labelStyle(11, letterSpacing: 1.5, color: MysticColors.onPrimary)),
          ],
        ),
      ),
    );
  }
}
