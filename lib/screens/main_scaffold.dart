import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'journal_screen.dart';
import 'ledger_screen.dart';
import 'giving_screen.dart';
import 'insights_screen.dart';
import 'finance_hub_screen.dart';

/// Root shell that holds the 5 main tabs.
/// Uses IndexedStack so each screen preserves its scroll position.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const _screens = [
    JournalScreen(),
    LedgerScreen(),
    GivingScreen(),
    InsightsScreen(),
    FinanceHubScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      drawer: const AppDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _MysticBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Custom bottom navigation bar ─────────────────────────────────────────────

class _MysticBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _MysticBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4E8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(
            color: MysticColors.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: MysticColors.onSurface.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.auto_stories_outlined,  activeIcon: Icons.auto_stories,            label: 'Journal',  index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.list_alt_outlined,      activeIcon: Icons.list_alt,                label: 'Ledger',   index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.volunteer_activism,     activeIcon: Icons.volunteer_activism,      label: 'Giving',   index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.bar_chart_outlined,     activeIcon: Icons.bar_chart,               label: 'Insights', index: 3, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Finance',  index: 4, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        transform: active
            ? (Matrix4.identity()..rotateZ(-0.017))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? MysticColors.primaryContainer.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? MysticColors.primary : const Color(0xFF9E9B8A),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 1.0,
                color: active ? MysticColors.primary : const Color(0xFF9E9B8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
