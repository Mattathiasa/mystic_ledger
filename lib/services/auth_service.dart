import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'l10n.dart';

/// Thin wrapper around FirebaseAuth for sign-in, sign-up, sign-out, and Google.
class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() async {
    // Google Sign-In can be unconfigured on a platform (no iOS
    // GoogleService-Info.plist, placeholder web client ID, Android without an
    // OAuth client) — its signOut then throws. The Firebase session is the
    // source of truth, so a failed Google sign-out must never block it.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Ignore — the Firebase sign-out below is what matters.
    }
    await _auth.signOut();
  }

  /// Sends a password-reset email. Throws FirebaseAuthException on failure.
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Permanently deletes the Firebase Auth account.
  /// Call deleteAllUserData() from FinanceService first to wipe Firestore.
  Future<void> deleteAccount() => _auth.currentUser!.delete();

  /// Sign in with Google. Returns null if the user cancelled.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Friendly message from a FirebaseAuthException code.
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return L10n.t('That email is already registered.');
      case 'invalid-email':
        return L10n.t('Please enter a valid email address.');
      case 'weak-password':
        return L10n.t('Password must be at least 6 characters.');
      case 'user-not-found':
        return L10n.t('No account found with that email.');
      case 'wrong-password':
        return L10n.t('Incorrect password. Please try again.');
      case 'too-many-requests':
        return L10n.t('Too many attempts. Please wait a moment.');
      case 'requires-recent-login':
        return L10n.t('Please sign out and sign in again before deleting your account.');
      default:
        return e.message ?? L10n.t('Authentication failed.');
    }
  }
}
