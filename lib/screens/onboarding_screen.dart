import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account_model.dart';
import '../models/currency_model.dart';
import '../services/finance_service.dart';
import '../services/onboarding_service.dart';
import '../services/sms_capture_service.dart';
import '../services/l10n.dart';
import '../widgets/app_theme.dart';

/// One-time wizard shown after first sign-up, before MainScaffold.
///
/// A new ledger is empty by design (see `UserService.createUserProfile`), so
/// this is the guided start: pick the base currency, seal the first account,
/// and — on Android — decide whether bank alerts should auto-capture. On the
/// final step the wizard writes its choices and hands over to the app.
class OnboardingScreen extends StatefulWidget {
  final String userId;
  const OnboardingScreen({super.key, required this.userId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  // Step 1: base currency
  String _currency = Currency.defaultCode;

  // Step 2: first account
  final _accountNameCtrl = TextEditingController();
  AccountType _accountType = AccountType.cash;

  // Step 3: SMS capture
  bool _smsEnabled = false;

  bool _saving = false;
  bool _smsBusy = false;

  static const int _totalSteps = 3;

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return true; // a currency is always preselected
      case 1:
        return _accountNameCtrl.text.trim().isNotEmpty;
      case 2:
        return true;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    if (_step == 2) {
      await _finish();
      return;
    }
    if (!_canAdvance) return;
    setState(() => _step++);
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final svc = context.read<FinanceService>();

      // Step 1 choices are applied only at the end, so a user who backs out
      // mid-wizard leaves no half-created state behind.
      await svc.setBaseCurrency(_currency);

      // Step 2: the first account. Empty ledgers have no accounts at all, and
      // this one is the first entry in the vaults list.
      final now = DateTime.now();
      await svc.addAccount(Account(
        id: 'acc_${now.millisecondsSinceEpoch}',
        name: _accountNameCtrl.text.trim(),
        type: _accountType,
        currency: _currency,
      ));

      // Step 3: optional SMS capture. Only meaningful on Android; elsewhere
      // the toggle is never offered.
      if (_smsEnabled && SmsCaptureService.instance.supported) {
        setState(() => _smsBusy = true);
        final granted = await SmsCaptureService.instance.requestPermission();
        if (granted) {
          await SmsCaptureService.instance.setEnabled(true);
        }
      }

      await OnboardingService.instance.markComplete(widget.userId);
    } catch (_) {
      // A failed write must not leave the wizard spinning forever with no
      // way out — reset the button and let the user retry.
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              L10n.t('Could not save. Check your connection and try again.'),
              style: bodyStyle(13, color: MysticColors.onTertiary)),
          backgroundColor: MysticColors.tertiary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
      return;
    }
    if (mounted) setState(() => _saving = false);
    // No navigation needed — AuthGate rebuilds on the service flag.
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark mode or the language flips: the palette and strings
    // live in mutable statics, so const widget instances would skip us.
    Theme.of(context);
    Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: MysticColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(),
                    const SizedBox(height: 36),
                    _StepDots(step: _step, total: _totalSteps),
                    const SizedBox(height: 36),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _buildStep(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Footer(
              step: _step,
              total: _totalSteps,
              saving: _saving,
              smsBusy: _smsBusy,
              canAdvance: _canAdvance,
              onBack: _step > 0
                  ? () => setState(() => _step--)
                  : null,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _CurrencyStep(
          selected: _currency,
          onChanged: (c) => setState(() => _currency = c),
        );
      case 1:
        return _AccountStep(
          nameCtrl: _accountNameCtrl,
          type: _accountType,
          onTypeChanged: (t) => setState(() => _accountType = t),
        );
      default:
        return _SmsStep(
          enabled: _smsEnabled,
          supported: SmsCaptureService.instance.supported,
          onChanged: (v) => setState(() => _smsEnabled = v),
        );
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.auto_awesome,
            size: 34, color: MysticColors.primary.withOpacity(0.7)),
        const SizedBox(height: 14),
        Text(L10n.t('First Steps'),
            style: headlineStyle(36, italic: true, weight: FontWeight.w900),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(L10n.t('SET UP YOUR LEDGER'),
            style: labelStyle(11,
                letterSpacing: 2.0,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ── Step indicator ───────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int step;
  final int total;
  const _StepDots({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? MysticColors.primary : MysticColors.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Step 1: base currency ────────────────────────────────────────────────────

class _CurrencyStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _CurrencyStep({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.t('Base Currency'),
            style: headlineStyle(24, italic: true, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          L10n.t('Every total and report is shown in this currency. You can '
              'still hold money in others and convert between them.'),
          style: bodyStyle(14, color: MysticColors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: MysticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: MysticColors.outlineVariant.withOpacity(0.15)),
          ),
          child: Column(
            children: Currency.registry.map((c) {
              final active = c.code == selected;
              return InkWell(
                onTap: () => onChanged(c.code),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: active
                      ? BoxDecoration(
                          color: MysticColors.primaryContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        )
                      : null,
                  child: Row(
                    children: [
                      Text(c.symbol,
                          style: headlineStyle(20,
                              italic: false, weight: FontWeight.w800)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.code,
                                style: bodyStyle(15, weight: FontWeight.w700)),
                            Text(c.name,
                                style: bodyStyle(12,
                                    color: MysticColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (active)
                        Icon(Icons.check_circle,
                            color: MysticColors.primary, size: 22),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Step 2: first account ────────────────────────────────────────────────────

class _AccountStep extends StatelessWidget {
  final TextEditingController nameCtrl;
  final AccountType type;
  final ValueChanged<AccountType> onTypeChanged;
  const _AccountStep({
    required this.nameCtrl,
    required this.type,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.t('Your First Account'),
            style: headlineStyle(24, italic: true, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          L10n.t('Where does your money live? A bank, mobile money, or cash '
              'in hand. You can add more vaults later.'),
          style: bodyStyle(14, color: MysticColors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: bodyStyle(16, weight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: L10n.t('e.g. CBE Bank, Telebirr, Cash'),
            hintStyle: bodyStyle(16)
                .copyWith(color: MysticColors.onSurface.withOpacity(0.25)),
            contentPadding: const EdgeInsets.only(bottom: 8),
            isDense: true,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: MysticColors.outlineVariant.withOpacity(0.3),
                  width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: MysticColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AccountType.values.map((t) {
            final active = t == type;
            return GestureDetector(
              onTap: () => onTypeChanged(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: active
                      ? MysticColors.primary
                      : MysticColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active
                        ? MysticColors.primary
                        : MysticColors.outlineVariant.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_accountTypeIcon(t),
                        size: 16,
                        color: active
                            ? MysticColors.onPrimary
                            : MysticColors.primary),
                    const SizedBox(width: 6),
                    Text(_accountTypeLabel(t),
                        style: bodyStyle(13,
                            weight: FontWeight.w600,
                            color: active
                                ? MysticColors.onPrimary
                                : MysticColors.onSurface)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // The enum is plain data; the display helpers live here to avoid importing
  // Account just for two getters.
  static IconData _accountTypeIcon(AccountType t) {
    switch (t) {
      case AccountType.bank:    return Icons.account_balance_outlined;
      case AccountType.mobile:  return Icons.account_balance_wallet_outlined;
      case AccountType.cash:    return Icons.payments_outlined;
      case AccountType.savings: return Icons.savings_outlined;
    }
  }

  static String _accountTypeLabel(AccountType t) {
    switch (t) {
      case AccountType.bank:    return L10n.t('Bank');
      case AccountType.mobile:  return L10n.t('Mobile Money');
      case AccountType.cash:    return L10n.t('Cash');
      case AccountType.savings: return L10n.t('Savings Vault');
    }
  }
}

// ── Step 3: SMS capture ──────────────────────────────────────────────────────

class _SmsStep extends StatelessWidget {
  final bool enabled;
  final bool supported;
  final ValueChanged<bool> onChanged;
  const _SmsStep({
    required this.enabled,
    required this.supported,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Non-Android: the feature cannot work, so the step becomes a brief
    // privacy note instead of a dead toggle.
    if (!supported) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.t('You are ready'),
              style: headlineStyle(24, italic: true, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            L10n.t('Your ledger is open. Add entries, set a giving rate, and '
                'seal your first savings vault whenever you are ready.'),
            style: bodyStyle(14, color: MysticColors.onSurfaceVariant),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.t('Auto-capture bank alerts'),
            style: headlineStyle(24, italic: true, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          L10n.t('On Android, Mystic Ledger can watch for Telebirr, CBE and '
              'Awash alerts in your messages and turn them into reviewable '
              'draft entries. You approve each one before it enters the '
              'ledger — nothing is recorded automatically.'),
          style: bodyStyle(14, color: MysticColors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => onChanged(!enabled),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: MysticColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: enabled
                      ? MysticColors.secondary.withOpacity(0.5)
                      : MysticColors.outlineVariant.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  enabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none,
                  color: enabled
                      ? MysticColors.secondary
                      : MysticColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L10n.t('Enable SMS capture'),
                          style: bodyStyle(15, weight: FontWeight.w700)),
                      Text(
                        L10n.t('Permission is asked before anything is read.'),
                        style: bodyStyle(12,
                            color: MysticColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onChanged,
                  activeTrackColor: MysticColors.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final int step;
  final int total;
  final bool saving;
  final bool smsBusy;
  final bool canAdvance;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _Footer({
    required this.step,
    required this.total,
    required this.saving,
    required this.smsBusy,
    required this.canAdvance,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: MysticColors.appBarBackground,
        border: Border(
          top: BorderSide(
              color: MysticColors.outlineVariant.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (onBack != null) ...[
              TextButton(
                onPressed: onBack,
                child: Text(L10n.t('Back'),
                    style:
                        bodyStyle(14, color: MysticColors.onSurfaceVariant)),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: GestureDetector(
                onTap: (saving || smsBusy || !canAdvance) ? null : onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: (saving || smsBusy || !canAdvance)
                        ? MysticColors.onSurface.withOpacity(0.15)
                        : MysticColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: saving || smsBusy
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: MysticColors.onPrimary, strokeWidth: 2),
                          )
                        : Text(
                            isLast
                                ? L10n.t('Open the Ledger')
                                : L10n.t('Continue'),
                            style: headlineStyle(17,
                                italic: true,
                                weight: FontWeight.w900,
                                color: (saving || smsBusy || !canAdvance)
                                    ? MysticColors.onSurfaceVariant
                                        .withOpacity(0.5)
                                    : MysticColors.onPrimary),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
