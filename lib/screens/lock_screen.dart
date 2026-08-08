import 'package:flutter/material.dart';
import '../services/lock_service.dart';
import '../widgets/app_theme.dart';

/// Full-screen gate shown while the app is locked.
///
/// Replaces the normal UI (not stacked on top of it) so nothing is visible —
/// not even a glimpse under the dialog. Authentication is attempted on the
/// button; if the device has no biometric/PIN enrolled the user is given the
/// honest option to proceed (there is nothing to check against, so locking
/// would just trap them).
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _busy = false;
  bool? _canUse;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    final can = await LockService.instance.canUse;
    if (!mounted) return;
    setState(() => _canUse = can);
  }

  Future<void> _unlock() async {
    setState(() => _busy = true);
    final ok = await LockService.instance.authenticate();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Not recognised — try again.',
            style: bodyStyle(13, color: Colors.white)),
        backgroundColor: MysticColors.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF292520),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: MysticColors.primaryContainer.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: MysticColors.primaryContainer.withOpacity(0.4),
                        width: 1.5),
                  ),
                  child: Icon(Icons.lock_outline,
                      color: MysticColors.primaryContainer, size: 40),
                ),
                const SizedBox(height: 24),
                Text('Sealed',
                    style: headlineStyle(34,
                        italic: true,
                        weight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Your ledger is locked. Unlock to read the records.',
                  textAlign: TextAlign.center,
                  style: bodyStyle(14, color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 36),

                GestureDetector(
                  onTap: _busy ? null : _unlock,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      color: MysticColors.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: MysticColors.primaryContainer
                              .withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Color(0xFF292520), strokeWidth: 2),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fingerprint,
                                  color: Color(0xFF292520), size: 22),
                              const SizedBox(width: 10),
                              Text('UNLOCK',
                                  style: labelStyle(11,
                                      letterSpacing: 1.5,
                                      color: const Color(0xFF292520),
                                      weight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                if (_canUse == false) ...[
                  Text(
                    'No fingerprint or PIN is enrolled on this device, so '
                    'nothing can verify you. You can proceed without the lock.',
                    textAlign: TextAlign.center,
                    style: bodyStyle(12,
                        color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      LockService.instance.unlock();
                      LockService.instance.setEnabled(false);
                    },
                    child: Text('Turn off the lock',
                        style: bodyStyle(13,
                            color: MysticColors.primaryContainer)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
