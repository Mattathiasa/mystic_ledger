import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../services/user_service.dart';
import '../widgets/app_theme.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MysticColors.surfaceContainerLow,
        title: Text('Delete Account?',
            style: headlineStyle(20,
                italic: true,
                weight: FontWeight.w700,
                color: MysticColors.tertiary)),
        content: Text(
          'This will permanently delete all your transactions, accounts, debts, budgets, and your profile. This cannot be undone.',
          style: bodyStyle(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete Everything',
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
              style: bodyStyle(13, color: Colors.white)),
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
    final uid = _auth.currentUser?.uid ?? '';
    final svc = context.watch<FinanceService>();
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCF0),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: MysticColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Profile',
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

                // ── Info rows ─────────────────────────────────────────
                _InfoCard(
                  rows: [
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'EMAIL',
                      value: user?.email ?? _auth.currentUser?.email ?? '—',
                    ),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'MEMBER SINCE',
                      value: user != null
                          ? DateFormat('MMMM d, yyyy').format(user.createdAt)
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
                        const Icon(Icons.logout,
                            color: MysticColors.tertiary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Sign Out',
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
                          'Delete Account & All Data',
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
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: headlineStyle(28,
                    italic: false,
                    weight: FontWeight.w900,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? '—',
            style: headlineStyle(24,
                italic: false,
                weight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '—',
            style: bodyStyle(13, color: Colors.white.withOpacity(0.65)),
          ),
          const SizedBox(height: 20),
          // Edit Profile button
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Edit Profile',
                      style: labelStyle(11,
                          letterSpacing: 0.5, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Total balance divider + value
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'TOTAL BALANCE',
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            svc.totalHidden
                ? '••••••'
                : '${svc.baseCurrency} ${fmt.format(svc.totalBalance)}',
            style: headlineStyle(32,
                italic: false,
                weight: FontWeight.w900,
                color: Colors.white),
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
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCF0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
          Text('Edit Profile',
              style: headlineStyle(26, italic: true, weight: FontWeight.w900)),
          const SizedBox(height: 24),
          // Display name field
          Text('DISPLAY NAME',
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
              hintText: 'Your name',
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
          Text('EMAIL',
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
          Text('Email cannot be changed here.',
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text('Save Changes',
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
            label: 'INCOME',
            value: '${svc.baseCurrency} ${fmt.format(svc.totalIncome)}',
            color: MysticColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'EXPENSES',
            value: '${svc.baseCurrency} ${fmt.format(svc.totalExpenses)}',
            color: MysticColors.tertiary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'SAVINGS',
            // Savings sits in its own account, so it carries that currency.
            value: '${svc.currencyOf(FinanceService.idSavings)} '
                '${fmt.format(svc.totalSavings)}',
            color: MysticColors.primary,
          ),
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
