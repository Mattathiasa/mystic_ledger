import 'package:flutter/material.dart';
import '../widgets/app_theme.dart';
import '../main.dart';

/// First screen shown on launch.
/// Displays the journal cover artwork and a CTA button.
/// Tapping "Open the Journal" fades into the main app shell.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      body: Stack(
        children: [
          // Ambient radial gold glow centred on the screen
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [Color(0x26D4AF37), Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _JournalCover(),
                  const SizedBox(height: 48),
                  const _TitleSection(),
                  const SizedBox(height: 56),
                  _OpenButton(
                    onTap: () => Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const AuthGate(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _MetaRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Journal book cover (built entirely from Flutter widgets) ────────────────

class _JournalCover extends StatelessWidget {
  const _JournalCover();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.017, // −1 degree tilt
      child: SizedBox(
        width: 220,
        height: 300,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Layer 3 — back parchment (deepest shadow)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                width: 220,
                height: 300,
                decoration: BoxDecoration(
                  color: MysticColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 20,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
              ),
            ),
            // Layer 2 — mid parchment
            Positioned(
              left: 3,
              top: 3,
              child: Container(
                width: 220,
                height: 300,
                decoration: BoxDecoration(
                  color: MysticColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // Layer 1 — main dark journal cover
            Container(
              width: 220,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF292520),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xFF1A1714), width: 14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: MysticColors.primaryContainer.withOpacity(0.4),
                    blurRadius: 32,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Eye of the Ledger — circular ring + gold star icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MysticColors.primaryContainer.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 52,
                      color: MysticColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Embossed gold lines
                  Container(
                    width: 60,
                    height: 2,
                    decoration: BoxDecoration(
                      color: MysticColors.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 2,
                    decoration: BoxDecoration(
                      color: MysticColors.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Mystic Ledger',
          style: headlineStyle(52, italic: true, weight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          'TRACK YOUR MONEY LIKE A STORY',
          style: labelStyle(11,
              letterSpacing: 2.5, color: MysticColors.outline),
        ),
      ],
    );
  }
}

class _OpenButton extends StatelessWidget {
  final VoidCallback onTap;
  const _OpenButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.history_edu_outlined),
        label: const Text('Open the Journal'),
        style: ElevatedButton.styleFrom(
          backgroundColor: MysticColors.primary,
          foregroundColor: MysticColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: MysticColors.primaryFixed.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          textStyle: headlineStyle(18, weight: FontWeight.w700, italic: false),
          elevation: 4,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow();

  @override
  Widget build(BuildContext context) {
    final style = labelStyle(10,
        letterSpacing: 2.0,
        color: MysticColors.outline.withOpacity(0.6));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('V 1.0.0', style: style),
        const SizedBox(width: 12),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: MysticColors.outline.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text("The Archivist's Grimoire", style: style),
      ],
    );
  }
}
