import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/app_theme.dart';

/// Login / Sign-Up screen shown when no user is authenticated.
/// Toggles between Sign In and Sign Up modes.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _nameCtrl   = TextEditingController();

  final _auth = AuthService();
  bool _isSignUp   = false;
  bool _loading    = false;
  bool _obscure    = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      if (_isSignUp) {
        final cred = await _auth.signUp(
          email:    _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        // Create Firestore profile + default accounts
        await UserService().createUserProfile(
          uid:   cred.user!.uid,
          name:  _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
      } else {
        await _auth.signIn(
          email:    _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      }
      // Auth gate in main.dart automatically navigates to MainScaffold
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    try {
      await _showResetDialog(emailCtrl);
    } finally {
      // Disposed here rather than left to the GC — a new controller was
      // otherwise leaked every time the dialog opened.
      emailCtrl.dispose();
    }
  }

  Future<void> _showResetDialog(TextEditingController emailCtrl) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MysticColors.surfaceContainerLow,
        title: Text('Reset Password',
            style: headlineStyle(20, italic: true, weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your email and we\'ll send a reset link.',
                style: bodyStyle(14)),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: bodyStyle(15),
              decoration: InputDecoration(
                hintText: 'your@email.com',
                hintStyle: bodyStyle(15).copyWith(
                    color: MysticColors.onSurface.withOpacity(0.3)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: MysticColors.outlineVariant.withOpacity(0.4)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: MysticColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: bodyStyle(14, color: MysticColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              // Capture before the async gap so no BuildContext is used after it.
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _auth.resetPassword(email);
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Reset link sent to $email',
                        style: bodyStyle(13, color: Colors.white)),
                    backgroundColor: MysticColors.secondary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                navigator.pop();
                setState(() => _error = AuthService.friendlyError(e));
              }
            },
            child: Text('Send Link',
                style: bodyStyle(14,
                    weight: FontWeight.w700, color: MysticColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await _auth.signInWithGoogle();
      if (cred == null) return; // user cancelled

      // Create profile if this is a brand-new Google user
      if (cred.additionalUserInfo?.isNewUser == true) {
        await UserService().createUserProfile(
          uid:   cred.user!.uid,
          name:  cred.user!.displayName ?? 'Archivist',
          email: cred.user!.email ?? '',
        );
      }
      // AuthGate rebuilds automatically
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
    } catch (_) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: MysticColors.background,
        body: Stack(
          children: [
            // Ambient glow
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.0,
                    colors: [Color(0x1AD4AF37), Colors.transparent],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Logo / header ──────────────────────────────────
                      _Bookmark(),
                      const SizedBox(height: 32),
                      Text(
                        _isSignUp ? 'Begin Your\nLedger' : 'Welcome\nBack',
                        style: headlineStyle(44,
                            italic: true, weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSignUp
                            ? 'CREATE YOUR ARCHIVIST ACCOUNT'
                            : 'SIGN IN TO YOUR GRIMOIRE',
                        style: labelStyle(10,
                            letterSpacing: 2.0,
                            color: MysticColors.onSurfaceVariant
                                .withOpacity(0.6)),
                      ),
                      const SizedBox(height: 40),

                      // ── Form card ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: MysticColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: MysticColors.outlineVariant
                                  .withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: MysticColors.onSurface.withOpacity(0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name (sign-up only)
                            if (_isSignUp) ...[
                              const _FieldLabel('FULL NAME'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _nameCtrl,
                                hint: 'Your archivist name',
                                textCapitalization:
                                    TextCapitalization.words,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter your name'
                                        : null,
                              ),
                              const SizedBox(height: 24),
                              _HRule(),
                              const SizedBox(height: 24),
                            ],

                            // Email
                            const _FieldLabel('EMAIL'),
                            const SizedBox(height: 8),
                            _InputField(
                              controller: _emailCtrl,
                              hint: 'your@email.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your email';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _HRule(),
                            const SizedBox(height: 24),

                            // Password
                            const _FieldLabel('PASSWORD'),
                            const SizedBox(height: 8),
                            _PasswordField(
                              controller: _passCtrl,
                              obscure: _obscure,
                              onToggle: () =>
                                  setState(() => _obscure = !_obscure),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter your password';
                                }
                                if (_isSignUp && v.length < 6) {
                                  return 'At least 6 characters required';
                                }
                                return null;
                              },
                            ),

                            // Forgot password (sign-in only)
                            if (!_isSignUp) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _forgotPassword,
                                  child: Text(
                                    'Forgot password?',
                                    style: bodyStyle(13,
                                        color: MysticColors.primary,
                                        weight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],

                            // Error message
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: MysticColors.tertiary
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: MysticColors.tertiary
                                          .withOpacity(0.25)),
                                ),
                                child: Text(
                                  _error!,
                                  style: bodyStyle(13,
                                      color: MysticColors.tertiary),
                                ),
                              ),
                            ],

                            const SizedBox(height: 32),

                            // Submit button
                            _loading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: MysticColors.primary,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _SubmitButton(
                                        label: _isSignUp
                                            ? 'Open the Ledger'
                                            : 'Enter the Archive',
                                        onTap: _submit,
                                      ),
                                      const SizedBox(height: 16),
                                      _OrDivider(),
                                      const SizedBox(height: 16),
                                      _GoogleButton(onTap: _googleSignIn),
                                    ],
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Toggle sign-in / sign-up ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp
                                ? 'Already have an account?'
                                : 'No account yet?',
                            style: bodyStyle(13,
                                color: MysticColors.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                            }),
                            child: Text(
                              _isSignUp ? 'Sign In' : 'Sign Up',
                              style: bodyStyle(13,
                                      weight: FontWeight.w700,
                                      color: MysticColors.primary)
                                  .copyWith(
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          MysticColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ── Small journal bookmark logo ───────────────────────────────────────────────

class _Bookmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFF292520),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          child: Center(
            child: Icon(Icons.auto_awesome,
                color: MysticColors.primaryContainer, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Mystic Ledger',
          style: headlineStyle(22, italic: true, weight: FontWeight.w900),
        ),
      ],
    );
  }
}

// ── Shared form components ────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: labelStyle(9,
            letterSpacing: 1.5,
            color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
      );
}

class _HRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: MysticColors.outlineVariant.withOpacity(0.2));
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: bodyStyle(16, weight: FontWeight.w500),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
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
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: MysticColors.tertiary, width: 1.5),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: MysticColors.tertiary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: bodyStyle(16, weight: FontWeight.w500),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: '••••••••',
        hintStyle: bodyStyle(16)
            .copyWith(color: MysticColors.onSurface.withOpacity(0.25)),
        contentPadding: const EdgeInsets.only(bottom: 8),
        isDense: true,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: MysticColors.onSurfaceVariant.withOpacity(0.5),
          ),
          onPressed: onToggle,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: MysticColors.outlineVariant.withOpacity(0.3),
              width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: MysticColors.primary, width: 1.5),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: MysticColors.tertiary, width: 1.5),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: MysticColors.tertiary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SubmitButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: MysticColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MysticColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: headlineStyle(20,
                italic: true,
                weight: FontWeight.w900,
                color: MysticColors.onPrimary),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: MysticColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.5)),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: MysticColors.outlineVariant.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: MysticColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MysticColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" icon drawn with coloured text
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: bodyStyle(15, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
