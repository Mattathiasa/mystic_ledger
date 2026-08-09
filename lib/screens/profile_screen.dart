import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../services/user_service.dart';
import '../services/sms_capture_service.dart';
import '../services/data_exporter.dart';
import '../services/backup_service.dart';
import '../services/csv_importer.dart';
import '../services/lock_service.dart';
import '../services/security_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../services/l10n.dart';
import '../widgets/app_theme.dart';
import 'captured_screen.dart';
import 'recurring_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Full-screen profile page — accessible from the drawer.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userSvc = UserService();
  final _auth    = AuthService();

  Future<void> _showEditSheet(UserModel? user) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: user,
        onSave: (name) async {
          if (name.trim().isNotEmpty) {
            await _userSvc.updateName(uid, name.trim());
          }
        },
      ),
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteAccount() async {
    // High-risk: re-verify the owner before anything destructive is offered.
    if (!await LockService.instance.requireAuth()) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MysticColors.surfaceContainerLow,
        title: Text(L10n.t('Delete Account?'),
            style: headlineStyle(20,
                italic: true,
                weight: FontWeight.w700,
                color: MysticColors.tertiary)),
        content: Text(
          L10n.t('This will permanently delete all your transactions, accounts, debts, budgets, and your profile. This cannot be undone.'),
          style: bodyStyle(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(L10n.t('Cancel'),
                style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(L10n.t('Delete Everything'),
                style: bodyStyle(14,
                    weight: FontWeight.w700, color: MysticColors.tertiary)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final svc = context.read<FinanceService>();
      await svc.deleteAllUserData();
      await _auth.deleteAccount();
      // AuthGate automatically navigates to AuthScreen after deletion
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthService.friendlyError(e),
              style: bodyStyle(13, color: MysticColors.onTertiary)),
          backgroundColor: MysticColors.tertiary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark mode or the language flips: the palette and strings
    // live in mutable statics, so const widget instances would skip us.
    Theme.of(context);
    Localizations.localeOf(context);

    final uid = _auth.currentUser?.uid ?? '';
    final svc = context.watch<FinanceService>();
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: AppBar(
        backgroundColor: MysticColors.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: MysticColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(L10n.t('Profile'),
            style: headlineStyle(22, italic: true, weight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
              height: 1.5,
              color: MysticColors.outlineVariant.withOpacity(0.5)),
        ),
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userSvc.userStream(uid),
        builder: (context, snap) {
          final user = snap.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Avatar + name ─────────────────────────────────────
                _AvatarCard(
                  user: user,
                  svc: svc,
                  fmt: fmt,
                  onEditTap: () => _showEditSheet(user),
                ),

                const SizedBox(height: 28),

                // ── Account stats ─────────────────────────────────────
                _StatsRow(svc: svc, fmt: fmt),

                const SizedBox(height: 28),

                // ── SMS auto-capture ───────────────────────────────────
                // Non-const on purpose: must rebuild on theme/locale change.
                // ignore: prefer_const_constructors
                _CaptureCard(),

                const SizedBox(height: 28),

                // ── Data tools ─────────────────────────────────────────
                _ToolsCard(svc: svc),

                const SizedBox(height: 28),

                // ── Encrypted backup ───────────────────────────────────
                _BackupCard(svc: svc),

                const SizedBox(height: 28),

                // ── Appearance ────────────────────────────────────────
                // Non-const on purpose: must rebuild on theme/locale change.
                // ignore: prefer_const_constructors
                _AppearanceCard(),

                const SizedBox(height: 28),

                // ── Language ───────────────────────────────────────────
                // Non-const on purpose: must rebuild on theme/locale change.
                // ignore: prefer_const_constructors
                _LanguageCard(),

                const SizedBox(height: 28),

                // ── App lock ───────────────────────────────────────────
                // Non-const on purpose: must rebuild on theme/locale change.
                // ignore: prefer_const_constructors
                _SecurityCard(),

                const SizedBox(height: 28),

                // ── Notifications ──────────────────────────────────────
                // Non-const on purpose: must rebuild on theme/locale change.
                // ignore: prefer_const_constructors
                _NotificationsCard(),

                const SizedBox(height: 28),

                // ── Info rows ─────────────────────────────────────────
                _InfoCard(
                  rows: [
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: L10n.t('EMAIL'),
                      value: user?.email ?? _auth.currentUser?.email ?? '—',
                    ),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: L10n.t('MEMBER SINCE'),
                      value: user != null
                          ? DateFormat('MMMM d, yyyy',
                                  L10n.instance.isAmharic ? 'am' : null)
                              .format(user.createdAt)
                          : '—',
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Sign out button ───────────────────────────────────
                GestureDetector(
                  onTap: _signOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: MysticColors.tertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: MysticColors.tertiary.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout,
                            color: MysticColors.tertiary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          L10n.t('Sign Out'),
                          style: headlineStyle(17,
                              italic: true,
                              weight: FontWeight.w700,
                              color: MysticColors.tertiary),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Delete account ────────────────────────────────────
                GestureDetector(
                  onTap: _deleteAccount,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_forever_outlined,
                            size: 16,
                            color: MysticColors.onSurfaceVariant
                                .withOpacity(0.4)),
                        const SizedBox(width: 6),
                        Text(
                          L10n.t('Delete Account & All Data'),
                          style: bodyStyle(13,
                              color: MysticColors.onSurfaceVariant
                                  .withOpacity(0.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Avatar card ───────────────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  final UserModel? user;
  final FinanceService svc;
  final NumberFormat fmt;
  final VoidCallback onEditTap;

  const _AvatarCard({
    required this.user,
    required this.svc,
    required this.fmt,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user != null && user!.name.trim().isNotEmpty
        ? user!.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: MysticColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: MysticColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Initials circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: MysticColors.onPrimary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: MysticColors.onPrimary.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: headlineStyle(28,
                    italic: false,
                    weight: FontWeight.w900,
                    color: MysticColors.onPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? '—',
            style: headlineStyle(24,
                italic: false,
                weight: FontWeight.w700,
                color: MysticColors.onPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '—',
            style: bodyStyle(13, color: MysticColors.onPrimary.withOpacity(0.65)),
          ),
          const SizedBox(height: 20),
          // Edit Profile button
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: MysticColors.onPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: MysticColors.onPrimary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined,
                      size: 16, color: MysticColors.onPrimary),
                  const SizedBox(width: 8),
                  Text(L10n.t('Edit Profile'),
                      style: labelStyle(11,
                          letterSpacing: 0.5, color: MysticColors.onPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Total balance divider + value
          Container(height: 1, color: MysticColors.onPrimary.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            L10n.t('TOTAL BALANCE'),
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onPrimary.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            svc.totalHidden
                ? '••••••'
                : '${svc.baseCurrency} ${fmt.format(svc.totalBalance)}',
            style: headlineStyle(32,
                italic: false,
                weight: FontWeight.w900,
                color: MysticColors.onPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Edit profile bottom sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final UserModel? user;
  final Future<void> Function(String name) onSave;

  const _EditProfileSheet({required this.user, required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_nameCtrl.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
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
          // Handle bar
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
          Text(L10n.t('Edit Profile'),
              style: headlineStyle(26, italic: true, weight: FontWeight.w900)),
          const SizedBox(height: 24),
          // Display name field
          Text(L10n.t('DISPLAY NAME'),
              style: labelStyle(10,
                  letterSpacing: 1.5,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: bodyStyle(16, weight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: L10n.t('Your name'),
              hintStyle: bodyStyle(16, color: MysticColors.outlineVariant),
              filled: true,
              fillColor: MysticColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          // Email (read-only)
          Text(L10n.t('EMAIL'),
              style: labelStyle(10,
                  letterSpacing: 1.5,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: MysticColors.surfaceContainerLow.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.user?.email ?? '—',
                    style: bodyStyle(16,
                        color: MysticColors.onSurfaceVariant.withOpacity(0.5)),
                  ),
                ),
                Icon(Icons.lock_outline,
                    size: 16,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.4)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(L10n.t('Email cannot be changed here.'),
              style: labelStyle(10,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.4))),
          const SizedBox(height: 28),
          // Save button
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: MysticColors.primary,
              foregroundColor: MysticColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              shadowColor: MysticColors.primary.withOpacity(0.3),
            ),
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: MysticColors.onPrimary, strokeWidth: 2),
                  )
                : Text(L10n.t('Save Changes'),
                    style: headlineStyle(16,
                        italic: false,
                        weight: FontWeight.w700,
                        color: MysticColors.onPrimary)),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final FinanceService svc;
  final NumberFormat fmt;
  const _StatsRow({required this.svc, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: L10n.t('INCOME'),
            value: '${svc.baseCurrency} ${fmt.format(svc.totalIncome)}',
            color: MysticColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: L10n.t('EXPENSES'),
            value: '${svc.baseCurrency} ${fmt.format(svc.totalExpenses)}',
            color: MysticColors.tertiary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Builder(builder: (_) {
            // Vaults hold their own currencies; across several the total has to
            // be converted, and the ≈ says the figure is an estimate.
            final s = svc.savingsSummary;
            return _StatCard(
              label: L10n.t('SAVINGS'),
              value: '${s.converted ? '≈ ' : ''}${s.currency} '
                  '${fmt.format(s.amount)}',
              color: MysticColors.primary,
            );
          }),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle(8, letterSpacing: 1.2, color: color)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  bodyStyle(13, weight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── SMS auto-capture ──────────────────────────────────────────────────────────

/// Lets the app read bank alerts (with explicit permission), parse them on
/// this device, and queue them for review. Approved entries go to the ledger;
/// raw messages never leave the phone.
class _CaptureCard extends StatelessWidget {
  const _CaptureCard();

  Future<void> _requestPermission(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final granted = await SmsCaptureService.instance.requestPermission();
    messenger.showSnackBar(SnackBar(
      content: Text(
        granted
            ? L10n.t('SMS access granted — Telebirr, CBE and Awash alerts will be captured.')
            : L10n.t('SMS access was denied. Auto-capture needs it to read alerts.'),
        style: bodyStyle(
            13,
            color: granted ? MysticColors.onSecondary : MysticColors.onTertiary),
      ),
      backgroundColor: granted ? MysticColors.secondary : MysticColors.tertiary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _backfill(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await SmsCaptureService.instance.backfillInbox();
    final (message, color) = added == -1
        ? (L10n.t('Could not scan the inbox — make sure SMS access is allowed.'),
            MysticColors.tertiary)
        : added == 0
            ? (L10n.t('No bank transaction messages found in the inbox.'),
                MysticColors.onSurfaceVariant)
            : ('$added ${L10n.t('captured message(s) queued for review.')}',
                MysticColors.secondary);
    messenger.showSnackBar(SnackBar(
      content: Text(message, style: bodyStyle(13, color: readableOn(color))),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SmsCaptureService.instance,
      builder: (context, _) {
        final svc = SmsCaptureService.instance;

        return Container(
          decoration: BoxDecoration(
            color: MysticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: MysticColors.outlineVariant.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header + toggle ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MysticColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.mark_email_unread_outlined,
                          size: 18, color: MysticColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(L10n.t('AUTO-CAPTURE'),
                              style: labelStyle(9,
                                  letterSpacing: 1.5,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.6))),
                          const SizedBox(height: 2),
                          Text(L10n.t('Telebirr, CBE & Awash alerts'),
                              style: bodyStyle(14, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Switch(
                      value: svc.isEnabled,
                      activeTrackColor: MysticColors.primary.withOpacity(0.5),
                      activeColor: MysticColors.primary,
                      onChanged: (v) async {
                        await svc.setEnabled(v);
                        if (!context.mounted) return;
                        // First-time grant happens right here, so the toggle is
                        // a single gesture for the user.
                        if (v && svc.supported) {
                          await _requestPermission(context);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // ── Body copy ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  svc.supported
                      ? L10n.t('Incoming Telebirr, CBE and Awash alerts are read '
                          'on this phone, parsed, and queued for your review — '
                          'nothing is recorded without you, and raw messages '
                          'never leave the device.')
                      : L10n.t('SMS auto-capture is available on Android only.'),
                  style: bodyStyle(12,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.75)),
                ),
              ),

              // ── Banks watched ────────────────────────────────────────
              if (svc.supported)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(L10n.t('Banks watched'),
                          style: labelStyle(9,
                              letterSpacing: 1.2,
                              color: MysticColors.onSurfaceVariant
                                  .withOpacity(0.6))),
                      for (final name in const [
                        'Telebirr',
                        'CBE',
                        'Awash Bank',
                      ])
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: MysticColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(name,
                              style: labelStyle(9,
                                  letterSpacing: 0.3,
                                  color: MysticColors.primary)),
                        ),
                    ],
                  ),
                ),

              // ── Actions ─────────────────────────────────────────────
              if (svc.isEnabled && svc.supported) ...[
                Divider(
                    height: 1, color: MysticColors.outlineVariant),
                _CaptureAction(
                  icon: Icons.notifications_active_outlined,
                  label: L10n.t('Allow SMS access'),
                  subtitle: L10n.t('System permission to read bank alerts'),
                  onTap: () => _requestPermission(context),
                ),
                _CaptureAction(
                  icon: Icons.history,
                  label: L10n.t('Scan inbox for past messages'),
                  subtitle: L10n.t('Pulls earlier bank alerts into the queue'),
                  onTap: () => _backfill(context),
                ),
                _CaptureAction(
                  icon: Icons.inbox_outlined,
                  label: svc.pendingCount == 0
                      ? L10n.t('Review captured messages')
                      : '${L10n.t('Review')} ${svc.pendingCount} '
                          '${L10n.t('captured message(s)')}',
                  subtitle: L10n.t('Approve, edit, or dismiss before they are recorded'),
                  trailing: svc.pendingCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: MysticColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${svc.pendingCount}',
                              style: labelStyle(9,
                                  letterSpacing: 1.0,
                                  color: MysticColors.primary,
                                  weight: FontWeight.w600)),
                        )
                      : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CapturedScreen()),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CaptureAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _CaptureAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: MysticColors.primary.withOpacity(0.6)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: bodyStyle(14, weight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: bodyStyle(11,
                          color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right,
                    size: 18,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

// ── Data tools card ───────────────────────────────────────────────────────────

/// Export + recurring + (later) appearance/security toggles.
class _ToolsCard extends StatelessWidget {
  final FinanceService svc;
  const _ToolsCard({required this.svc});

  Future<void> _export(BuildContext context) async {
    // Exporting the whole archive is sensitive — re-verify first.
    if (!await LockService.instance.requireAuth()) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    void snack(String msg, Color color) => messenger.showSnackBar(SnackBar(
          content: Text(msg, style: bodyStyle(13, color: readableOn(color))),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));

    try {
      final shared = await DataExporter.share(svc);
      if (!shared) snack(L10n.t('Export cancelled.'), MysticColors.onSurfaceVariant);
    } catch (_) {
      snack(L10n.t('Could not share the export — try again.'), MysticColors.tertiary);
    }
  }

  Future<void> _import(BuildContext context) async {
    // Importing writes into the archive — re-verify first.
    if (!await LockService.instance.requireAuth()) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    void snack(String msg, Color color) => messenger.showSnackBar(SnackBar(
          content: Text(msg, style: bodyStyle(13, color: readableOn(color))),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final bytes = picked.files.single.bytes;
    if (bytes == null) {
      snack(L10n.t('Could not read that file.'), MysticColors.tertiary);
      return;
    }
    if (!context.mounted) return;

    final result = CsvImporter.parse(
      utf8.decode(bytes, allowMalformed: true),
      {for (final a in svc.allAccounts) a.name: a.id},
    );

    if (result.total == 0) {
      snack(
          L10n.t('No importable rows found. Make sure the file was exported from Mystic Ledger.'),
          MysticColors.tertiary);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MysticColors.surfaceContainerLow,
        title: Text(L10n.t('Import records?'),
            style: headlineStyle(20,
                italic: true,
                weight: FontWeight.w700,
                color: MysticColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.total} ${L10n.t('records will be added to your ledger.')}',
              style: bodyStyle(14),
            ),
            if (result.skipped.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${result.skipped.length} ${L10n.t('skipped — no matching account.')}',
                style: bodyStyle(13, color: MysticColors.tertiary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(L10n.t('Cancel'),
                style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(L10n.t('Import'),
                style: bodyStyle(14,
                    weight: FontWeight.w700, color: MysticColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await svc.importAll(
        transactions: result.transactions,
        transfers: result.transfers,
        debts: result.debts,
        budgets: result.budgets,
      );
      snack('${result.total} ${L10n.t('entries imported.')}',
          MysticColors.secondary);
    } catch (_) {
      snack(L10n.t('Import failed — try again.'), MysticColors.tertiary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MysticColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_awesome_outlined,
                      size: 18, color: MysticColors.secondary),
                ),
                const SizedBox(width: 12),
                Text(L10n.t('DATA TOOLS'),
                    style: labelStyle(9,
                        letterSpacing: 1.5,
                        color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              ],
            ),
          ),
          _CaptureAction(
            icon: Icons.repeat,
            label: L10n.t('Recurring transactions'),
            subtitle: L10n.t('Salary, rent, subscriptions — schedules that propose themselves'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecurringScreen()),
            ),
          ),
          Divider(height: 1, color: MysticColors.outlineVariant),
          _CaptureAction(
            icon: Icons.file_download_outlined,
            label: L10n.t('Export to CSV'),
            subtitle: L10n.t('Back up or share your records — transactions, transfers, debts, budgets'),
            onTap: () => _export(context),
          ),
          Divider(height: 1, color: MysticColors.outlineVariant),
          _CaptureAction(
            icon: Icons.file_upload_outlined,
            label: L10n.t('Import from CSV'),
            subtitle: L10n.t('Merge records from a spreadsheet exported by Mystic Ledger'),
            onTap: () => _import(context),
          ),
        ],
      ),
    );
  }
}

// ── Security card ─────────────────────────────────────────────────────────────

/// App lock toggle backed by [LockService]. The lock itself is enforced at the
/// app root, so this card is only about the preference.
class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  Future<void> _toggle(BuildContext context, bool value) async {
    final svc = LockService.instance;
    // Captured before any await so no BuildContext is used across one.
    final messenger = ScaffoldMessenger.of(context);
    if (value && !svc.supported) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            L10n.t('Biometric lock is available on Android and iOS only.'),
            style: bodyStyle(13, color: MysticColors.onTertiary)),
        backgroundColor: MysticColors.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (value && !await svc.canUse) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            L10n.t('No fingerprint or PIN is enrolled on this device, so the lock '
                'cannot verify you.'),
            style: bodyStyle(13, color: MysticColors.onTertiary)),
        backgroundColor: MysticColors.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    await svc.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LockService.instance,
      builder: (context, _) {
        final svc = LockService.instance;
        return Container(
          decoration: BoxDecoration(
            color: MysticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: MysticColors.outlineVariant.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MysticColors.tertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.lock_outline,
                          size: 18, color: MysticColors.tertiary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(L10n.t('APP LOCK'),
                              style: labelStyle(9,
                                  letterSpacing: 1.5,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.6))),
                          const SizedBox(height: 2),
                          Text(L10n.t('Biometric / PIN gate'),
                              style: bodyStyle(14, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Switch(
                      value: svc.isEnabled,
                      activeTrackColor: MysticColors.tertiary.withOpacity(0.5),
                      activeColor: MysticColors.tertiary,
                      onChanged: (v) => _toggle(context, v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  svc.supported
                      ? L10n.t('Lock the ledger whenever the app leaves the screen. '
                          'Your fingerprint or device PIN unlocks it.')
                      : L10n.t('Available on Android and iOS devices.'),
                  style: bodyStyle(12,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.75)),
                ),
              ),
              if (svc.supported) ...[
                Divider(height: 1, color: MysticColors.outlineVariant),
                // Inactivity auto-lock — driven by SecurityService, whose
                // timer is fed by the root shell's interaction listener.
                ListenableBuilder(
                  listenable: SecurityService.instance,
                  builder: (context, _) {
                    final sec = SecurityService.instance;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 18,
                              color:
                                  MysticColors.primary.withOpacity(0.6)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                                L10n.t('Auto-lock after inactivity'),
                                style: bodyStyle(14,
                                    weight: FontWeight.w600)),
                          ),
                          DropdownButton<int>(
                            value: sec.autoLockMinutes,
                            dropdownColor: MysticColors.surfaceContainerLow,
                            style: bodyStyle(14, weight: FontWeight.w700),
                            underline: const SizedBox.shrink(),
                            onChanged: (v) {
                              if (v != null) sec.setAutoLockMinutes(v);
                            },
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Off')),
                              DropdownMenuItem(
                                  value: 1, child: Text('1 min')),
                              DropdownMenuItem(
                                  value: 5, child: Text('5 min')),
                              DropdownMenuItem(
                                  value: 15, child: Text('15 min')),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Appearance card ──────────────────────────────────────────────────────────

/// Dark-mode toggle. The palette swap applies instantly via ThemeService.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final svc = ThemeService.instance;
        return Container(
          decoration: BoxDecoration(
            color: MysticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: MysticColors.outlineVariant.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MysticColors.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.dark_mode_outlined,
                          size: 18, color: MysticColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(L10n.t('APPEARANCE'),
                              style: labelStyle(9,
                                  letterSpacing: 1.5,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.6))),
                          const SizedBox(height: 2),
                          Text(L10n.t('Dark mode'),
                              style: bodyStyle(14, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Switch(
                      value: svc.isDark,
                      activeTrackColor:
                          MysticColors.primary.withOpacity(0.5),
                      activeColor: MysticColors.primary,
                      onChanged: (v) => ThemeService.instance.setDark(v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  L10n.t('Deep charcoal and ink — the grimoire after hours.'),
                  style: bodyStyle(12,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.75)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Language card ────────────────────────────────────────────────────────────

/// English ⇄ Amharic picker. The whole tree rebuilds in the new language via
/// [L10n], and the choice is remembered on this device.
class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: L10n.instance,
      builder: (context, _) {
        final svc = L10n.instance;
        return Container(
          decoration: BoxDecoration(
            color: MysticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: MysticColors.outlineVariant.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MysticColors.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.translate,
                          size: 18, color: MysticColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(L10n.t('LANGUAGE'),
                              style: labelStyle(9,
                                  letterSpacing: 1.5,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.6))),
                          const SizedBox(height: 2),
                          Text(L10n.t('Language'),
                              style: bodyStyle(14, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    // English ⇄ አማርኛ segmented control
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: MysticColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LangButton(
                            label: 'EN',
                            selected: !svc.isAmharic,
                            onTap: () => svc.setLocale('en'),
                          ),
                          _LangButton(
                            label: 'አማ',
                            selected: svc.isAmharic,
                            onTap: () => svc.setLocale('am'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  svc.isAmharic
                      ? 'መጽሐፉ በአማርኛ ይነበባል።'
                      : 'The grimoire reads in English.',
                  style: bodyStyle(12,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.75)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? MysticColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: labelStyle(10,
              letterSpacing: 1.0,
              weight: FontWeight.w700,
              color: selected
                  ? MysticColors.onPrimary
                  : MysticColors.onSurfaceVariant.withOpacity(0.6)),
        ),
      ),
    );
  }
}

// ── Notifications card ───────────────────────────────────────────────────────

/// Local alert toggle. Alerts (budget limits, debt due dates, tithe reminder,
/// recurring prompts) are scheduled on-device and re-armed on resume.
class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard();

  Future<void> _toggle(BuildContext context, bool value) async {
    final svc = NotificationService.instance;
    final finance = context.read<FinanceService>();
    final messenger = ScaffoldMessenger.of(context);
    await svc.setEnabled(value);
    messenger.showSnackBar(SnackBar(
      content: Text(
        value
            ? L10n.t('Alerts enabled — budget, debt, tithe and recurring reminders.')
            : L10n.t('Alerts disabled. Pending reminders were cancelled.'),
        style: bodyStyle(13,
            color: value
                ? MysticColors.onSecondary
                : MysticColors.onSurface),
      ),
      backgroundColor:
          value ? MysticColors.secondary : MysticColors.onSurfaceVariant,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    if (value) {
      await finance.rearmNotifications();
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationService.instance,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: MysticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: MysticColors.outlineVariant.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MysticColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.notifications_active_outlined,
                          size: 18, color: MysticColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(L10n.t('NOTIFICATIONS'),
                              style: labelStyle(9,
                                  letterSpacing: 1.5,
                                  color: MysticColors.onSurfaceVariant
                                      .withOpacity(0.6))),
                          const SizedBox(height: 2),
                          Text(L10n.t('Local reminders'),
                              style: bodyStyle(14, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Switch(
                      value: NotificationService.instance.isEnabled,
                      activeTrackColor: MysticColors.primary.withOpacity(0.5),
                      activeColor: MysticColors.primary,
                      onChanged: (v) => _toggle(context, v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  L10n.t('Budget limits at 80% and 100%, debt due dates, the tithe '
                      'month-end check-in, and recurring-schedule prompts. All '
                      'alerts are scheduled on this device.'),
                  style: bodyStyle(12,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.75)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: e.key < rows.length - 1
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: MysticColors.outlineVariant.withOpacity(0.2)),
                    ),
                  )
                : null,
            child: e.value,
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MysticColors.primary.withOpacity(0.6)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: labelStyle(8,
                      letterSpacing: 1.5,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              const SizedBox(height: 2),
              Text(value,
                  style: bodyStyle(14, weight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
// ── Backup card ──────────────────────────────────────────────────────────────

/// Encrypted `.mlbackup` export and restore.
class _BackupCard extends StatelessWidget {
  final FinanceService svc;
  const _BackupCard({required this.svc});

  /// Prompts for a password; with [confirm] the user types it twice and the
  /// two must match. Returns null when cancelled.
  Future<String?> _askPassword(BuildContext context,
      {required bool confirm}) async {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var error = '';

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: MysticColors.surfaceContainerLow,
          title: Text(
              confirm
                  ? L10n.t('Backup password')
                  : L10n.t('Restore from backup'),
              style: headlineStyle(20,
                  italic: true,
                  weight: FontWeight.w700,
                  color: MysticColors.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                confirm
                    ? L10n.t('Choose a password to protect this backup. It is never stored anywhere.')
                    : L10n.t('Enter the password used when this backup was created.'),
                style: bodyStyle(13, color: MysticColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                autofocus: true,
                style: bodyStyle(16, weight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: L10n.t('Password'),
                  filled: true,
                  fillColor: MysticColors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  style: bodyStyle(16, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: L10n.t('Confirm password'),
                    filled: true,
                    fillColor: MysticColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              if (error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(error,
                    style: bodyStyle(12, color: MysticColors.tertiary)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(L10n.t('Cancel'),
                  style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () {
                final p = passwordCtrl.text;
                if (p.length < 4) {
                  setState(() => error =
                      L10n.t('Password must be at least 4 characters.'));
                  return;
                }
                if (confirm && p != confirmCtrl.text) {
                  setState(() => error = L10n.t('Passwords do not match.'));
                  return;
                }
                Navigator.pop(ctx, p);
              },
              child: Text(
                  confirm ? L10n.t('Create backup') : L10n.t('Unlock backup'),
                  style: bodyStyle(14,
                      weight: FontWeight.w700, color: MysticColors.primary)),
            ),
          ],
        ),
      ),
    );
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    return result;
  }

  Future<void> _backup(BuildContext context) async {
    // Exporting the whole archive is sensitive — re-verify first.
    if (!await LockService.instance.requireAuth()) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    void snack(String msg, Color color) => messenger.showSnackBar(SnackBar(
          content: Text(msg, style: bodyStyle(13, color: readableOn(color))),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));

    // The dialog below uses [context] synchronously inside _askPassword,
    // before any await in that frame.
    // ignore: use_build_context_synchronously
    final password = await _askPassword(context, confirm: true);
    if (password == null || !context.mounted) return;

    try {
      final shared = await BackupService.shareBackup(svc, password);
      if (!shared) {
        snack(L10n.t('Backup cancelled.'), MysticColors.onSurfaceVariant);
      }
    } catch (_) {
      snack(L10n.t('Could not create the backup — try again.'),
          MysticColors.tertiary);
    }
  }

  Future<void> _restore(BuildContext context) async {
    // Restoring replaces the archive — re-verify first.
    if (!await LockService.instance.requireAuth()) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    void snack(String msg, Color color) => messenger.showSnackBar(SnackBar(
          content: Text(msg, style: bodyStyle(13, color: readableOn(color))),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mlbackup'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final bytes = picked.files.single.bytes;
    if (bytes == null) {
      snack(L10n.t('Could not read that file.'), MysticColors.tertiary);
      return;
    }

    // The dialog below uses [context] synchronously inside _askPassword,
    // before any await in that frame.
    // ignore: use_build_context_synchronously
    final password = await _askPassword(context, confirm: false);
    if (password == null || !context.mounted) return;

    BackupData data;
    try {
      final plain = await BackupService.decryptFileBytes(bytes, password);
      data = BackupService.parsePayload(
          jsonDecode(plain) as Map<String, dynamic>);
    } catch (_) {
      snack(L10n.t('Could not decrypt the backup — is the password right?'),
          MysticColors.tertiary);
      return;
    }
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MysticColors.surfaceContainerLow,
        title: Text(L10n.t('Restore backup?'),
            style: headlineStyle(20,
                italic: true,
                weight: FontWeight.w700,
                color: MysticColors.tertiary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${data.count} ${L10n.t('records')}',
                style: bodyStyle(14, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                L10n.t('This replaces all current data with the backup contents.'),
                style: bodyStyle(13, color: MysticColors.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(L10n.t('Cancel'),
                style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(L10n.t('Restore'),
                style: bodyStyle(14,
                    weight: FontWeight.w700, color: MysticColors.tertiary)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await svc.restoreAll(
        accounts: data.accounts,
        transactions: data.transactions,
        transfers: data.transfers,
        debts: data.debts,
        budgets: data.budgets,
        recurring: data.recurring,
        settings: data.settings,
      );
      snack('${data.count} ${L10n.t('records restored.')}',
          MysticColors.secondary);
    } catch (_) {
      snack(L10n.t('Restore failed — try again.'), MysticColors.tertiary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MysticColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.verified_user_outlined,
                      size: 18, color: MysticColors.primary),
                ),
                const SizedBox(width: 12),
                Text(L10n.t('BACKUP'),
                    style: labelStyle(9,
                        letterSpacing: 1.5,
                        color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
              ],
            ),
          ),
          _CaptureAction(
            icon: Icons.lock_outline,
            label: L10n.t('Back up now'),
            subtitle: L10n.t('Create an encrypted .mlbackup you can save anywhere'),
            onTap: () => _backup(context),
          ),
          Divider(height: 1, color: MysticColors.outlineVariant),
          _CaptureAction(
            icon: Icons.settings_backup_restore_outlined,
            label: L10n.t('Restore from backup'),
            subtitle: L10n.t('Replace all data from an encrypted .mlbackup'),
            onTap: () => _restore(context),
          ),
        ],
      ),
    );
  }
}
