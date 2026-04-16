import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';

/// Handles reading and writing user profile data in Firestore.
class UserService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');

  // ── Create ────────────────────────────────────────────────────────────────

  /// Called once after sign-up: writes the user document and seeds
  /// the four default accounts (Telebirr, Cash, CBE Bank, Savings Vault).
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
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

    // Default accounts
    final defaults = [
      Account(id: 'telebirr', name: 'Telebirr',     type: AccountType.mobile),
      Account(id: 'cash',     name: 'Cash On Hand',  type: AccountType.cash),
      Account(id: 'cbe',      name: 'CBE Bank',      type: AccountType.bank),
      Account(id: 'savings',  name: 'Savings Vault', type: AccountType.savings),
    ];
    for (final acc in defaults) {
      batch.set(
        userRef.collection('accounts').doc(acc.id),
        acc.toMap(),
      );
    }

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
