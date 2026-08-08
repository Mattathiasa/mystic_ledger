import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/app_settings.dart';
import '../models/currency_model.dart';

/// Handles reading and writing user profile data in Firestore.
class UserService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');

  // ── Create ────────────────────────────────────────────────────────────────

  /// Called once after sign-up: writes the user document and the settings doc.
  ///
  /// Deliberately creates **no accounts**. The ledger starts empty and the user
  /// builds it from their own vaults — a pre-populated list of accounts they
  /// may not hold reads as demo data and has to be cleaned up before the app is
  /// usable. Every screen that needs an account shows a first-run prompt
  /// instead (see `lib/widgets/empty_state_card.dart`).
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    String baseCurrency = Currency.defaultCode,
  }) async {
    final batch = _db.batch();
    final userRef = _users.doc(uid);

    // User profile document
    final user = UserModel(
      uid: uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
    batch.set(userRef, user.toMap());

    // Seed the settings doc so base currency is explicit from day one.
    batch.set(
      userRef.collection('settings').doc('prefs'),
      AppSettings(baseCurrency: baseCurrency).toMap(),
    );

    await batch.commit();
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<UserModel?> userStream(String uid) => _users.doc(uid).snapshots().map(
        (s) => s.exists
            ? UserModel.fromMap(s.data() as Map<String, dynamic>)
            : null,
      );

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> updateName(String uid, String name) =>
      _users.doc(uid).update({'name': name});
}
