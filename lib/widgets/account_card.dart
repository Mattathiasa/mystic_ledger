import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';

/// Displays a single account's balance (Telebirr / Bank / Cash).
///
/// [wide] = true renders a horizontal layout (used for the Cash card
/// that spans full width). [wide] = false stacks content vertically.
class AccountCard extends StatelessWidget {
  final String label;
  final String badge;
  final double balance;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double rotation; // in radians
  final bool wide;

  const AccountCard({
    super.key,
    required this.label,
    required this.badge,
    required this.balance,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.rotation,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final balanceText = 'ETB ${fmt.format(balance)}';

    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MysticColors.outlineVariant.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: MysticColors.onSurface.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: wide ? _wideLayout(balanceText) : _tallLayout(balanceText),
      ),
    );
  }

  Widget _wideLayout(String balanceText) {
    return Row(
      children: [
        _IconBox(icon: icon, color: iconColor),
        const SizedBox(width: 16),
        Expanded(child: _Labels(label: label, balance: balanceText, iconColor: iconColor)),
        _Badge(text: badge),
      ],
    );
  }

  Widget _tallLayout(String balanceText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _IconBox(icon: icon, color: iconColor),
            _Badge(text: badge),
          ],
        ),
        const SizedBox(height: 20),
        _Labels(label: label, balance: balanceText, iconColor: iconColor),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MysticColors.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: labelStyle(9, letterSpacing: 0.5),
      ),
    );
  }
}

class _Labels extends StatelessWidget {
  final String label;
  final String balance;
  final Color iconColor;
  const _Labels({required this.label, required this.balance, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: headlineStyle(16, italic: false, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(balance, style: bodyStyle(20, weight: FontWeight.w700, color: iconColor)),
      ],
    );
  }
}
