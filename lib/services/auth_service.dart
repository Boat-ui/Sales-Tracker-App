import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register ───────────────────────────────────────────
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String role, // 'owner', 'manager', 'cashier'
    String? businessId,   // null if owner (creates new business)
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // If owner, create a new business document
      String resolvedBusinessId = businessId ?? '';
      if (role == 'owner') {
        final bizRef = _db.collection('businesses').doc();
        resolvedBusinessId = bizRef.id;
        await bizRef.set({
          'name': '$name\'s Business',
          'ownerId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Save user profile
      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': role,
        'businessId': resolvedBusinessId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await cred.user!.updateDisplayName(name);
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  // ── Login ──────────────────────────────────────────────
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  // ── Logout ─────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Get user profile ───────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ── Password reset ─────────────────────────────────────
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':      return 'No account found with this email.';
      case 'wrong-password':      return 'Incorrect password.';
      case 'email-already-in-use':return 'An account already exists with this email.';
      case 'weak-password':       return 'Password must be at least 6 characters.';
      case 'invalid-email':       return 'Please enter a valid email address.';
      case 'too-many-requests':   return 'Too many attempts. Please try again later.';
      default:                    return 'Something went wrong. Please try again.';
    }
  }
}