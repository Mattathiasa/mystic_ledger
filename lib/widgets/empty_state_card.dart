import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../screens/add_account_screen.dart';
import '../services/l10n.dart';
import 'app_theme.dart';

/// The shared "there is nothing here yet" card.
///
/// Every screen used to carry its own private `_EmptyState`, so the parchment
/// card was redrawn five slightly different ways. This is the one to reach for.
///
/// Pass [ctaLabel] and [onCta] when the emptiness is *actionable* — an empty
/// state that names the fix is the difference between a dead end and an
/// onboarding step. Leave them off when the screen fills itself as a
/// side-effect of work done elsewhere.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.headline,
    required this.body,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark mode or the language flips: the palette and strings
    // live in mutable statics, so const widget instances would skip us.
    Theme.of(context);
    Localizations.localeOf(context);

    final muted = MysticColors.onSurfaceVariant.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MysticColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 48, color: MysticColors.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: headlineStyle(20,
                italic: true, weight: FontWeight.w700, color: muted),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: bodyStyle(13, color: muted),
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCta,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: MysticColors.primaryContainer.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MysticColors.primaryContainer.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  ctaLabel!.toUpperCase(),
                  style: labelStyle(11,
                      letterSpacing: 1.5,
                      weight: FontWeight.w600,
                      color: MysticColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The first-run case: no accounts exist yet, so the screen cannot do its job.
///
/// New sign-ups start with a genuinely empty ledger — nothing is seeded — so
/// this is the front door to the app, not a rare edge case. [presetType] lands
/// the user on the right tab of the account-type selector, which matters most
/// for savings: a vault is what the Savings screen is *for*, and defaulting to
/// "Bank" would make the user guess.
class NoAccountsCard extends StatelessWidget {
  final String headline;
  final String body;
  final AccountType presetType;
  final String ctaLabel;

  const NoAccountsCard({
    super.key,
    required this.headline,
    required this.body,
    this.presetType = AccountType.bank,
    this.ctaLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: presetType == AccountType.savings
          ? Icons.savings_outlined
          : Icons.account_balance_wallet_outlined,
      headline: headline,
      body: body,
      ctaLabel: ctaLabel.isEmpty ? L10n.t('Add an account') : ctaLabel,
      onCta: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddAccountScreen(initialType: presetType),
        ),
      ),
    );
  }
}
