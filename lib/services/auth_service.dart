import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> init() async { await GoogleSignIn.instance.initialize(); }

  /// Returns true if signed-in user is admin.
  /// Throws on non-canceled GoogleSignIn errors so callers can surface them.
  Future<bool> signInWithGoogle() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final googleAuth = account.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      await _auth.signInWithCredential(credential);
      return checkIsAdmin();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
    // All other exceptions propagate to caller (network errors, Firebase errors)
  }

  Future<bool> checkIsAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final snap = await _db.collection('users').doc(uid).get();
      return snap.exists && snap.data()?['role'] == 'admin';
    } catch (_) { return false; }
  }

  Future<void> logout() async {
    await Future.wait([_auth.signOut(), GoogleSignIn.instance.signOut()]);
  }
}
