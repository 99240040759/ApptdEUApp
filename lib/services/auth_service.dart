import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // ─────────────────────────────────────────────────────────────────────
  // TODO: Replace with your Web Client ID from Google Cloud Console:
  //   Console → project samezz-3f3a9 → APIs & Services → Credentials
  //   → OAuth 2.0 Client ID of type "Web client (auto created by Google Service)"
  //   Format: 708285207203-xxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
  // ─────────────────────────────────────────────────────────────────────
  static const _serverClientId = 'YOUR_WEB_CLIENT_ID_HERE';

  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn(serverClientId: _serverClientId);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<bool> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
    return checkIsAdmin();
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
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
