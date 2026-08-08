import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../screens/profile_screen.dart';
import '../screens/main_scaffold.dart';
import 'app_theme.dart';

/// Shared AppBar used on all tab screens.
class MysticAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MysticAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.5);

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';

    return AppBar(
      backgroundColor: const Color(0xFFFDFCF0),
      elevation: 0,
      scrolledUnderElevation: 0,

      // ── Hamburger → opens drawer ──────────────────────────────────────────
      //
      // Must go through MainShell. Every tab wraps itself in its own Scaffold
      // and only the shell's declares a `drawer:`, so `Scaffold.of(ctx)` finds
      // the tab's — and `openDrawer()` on a drawer-less Scaffold does nothing
      // at all, silently. The fallback covers this bar being used outside the
      // shell, where the nearest Scaffold really is the right target.
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: MysticColors.primary),
            onPressed: () {
              final shell = MainShell.maybeOf(ctx);
              if (shell != null) {
                shell.openDrawer();
              } else {
                Scaffold.of(ctx).openDrawer();
              }
            },
          ),
        ),
      ),

      title: Text(
        'Mystic Ledger',
        style: GoogleFonts.epilogue(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          letterSpacing: -0.5,
          color: MysticColors.onSurface,
        ),
      ),

      // ── Profile avatar → opens ProfileScreen ─────────────────────────────
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: StreamBuilder<UserModel?>(
            stream: UserService().userStream(uid),
            builder: (context, snap) {
              final user = snap.data;
              final initials = user != null && user.name.trim().isNotEmpty
                  ? user.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase()
                  : null;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: MysticColors.primaryContainer.withOpacity(0.2),
                  child: initials != null
                      ? Text(
                          initials,
                          style: headlineStyle(13,
                              italic: false,
                              weight: FontWeight.w800,
                              color: MysticColors.primary),
                        )
                      : const Icon(
                          Icons.person_outline,
                          color: MysticColors.onSurfaceVariant,
                          size: 20,
                        ),
                ),
              );
            },
          ),
        ),
      ],

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(
          height: 1.5,
          color: MysticColors.outlineVariant.withOpacity(0.5),
        ),
      ),
    );
  }
}
