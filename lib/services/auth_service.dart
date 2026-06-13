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

  Future<void> init() async {
    await GoogleSignIn.instance.initialize();
  }

  Future<bool> signInWithGoogle() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      // authentication is a sync getter in 7.x — no await
      final googleAuth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // accessToken moved to authorizationClient in 7.x; idToken alone suffices for Firebase
      );
      await _auth.signInWithCredential(credential);
      return checkIsAdmin();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      return false;
    } catch (_) { return false; }
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
