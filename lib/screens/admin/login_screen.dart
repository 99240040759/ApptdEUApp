import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  User? _user;
  bool _isAdmin = false;
  bool _loading = true;
  bool _signing = false;
  String? _error;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = _auth.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (!mounted) return;
    if (user == null) {
      setState(() { _user = null; _isAdmin = false; _loading = false; });
      return;
    }
    final admin = await _auth.checkIsAdmin();
    if (!mounted) return;
    setState(() { _user = user; _isAdmin = admin; _loading = false; });
    if (admin) Navigator.pushReplacementNamed(context, '/admin/dashboard');
  }

  @override
  void dispose() { _authSub?.cancel(); super.dispose(); }

  Future<void> _signIn() async {
    setState(() { _signing = true; _error = null; });
    try {
      await _auth.signInWithGoogle();
      // auth state listener handles navigation
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    // Signed in but NOT admin — show Access Denied (matches website behavior)
    if (_user != null && !_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.lock_outline_rounded, size: 32, color: Colors.red.shade600),
              ),
              const SizedBox(height: 20),
              const Text('Access Restricted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 10),
              const Text('This area is for authorized administrators only.\nContact the site administrator if you require access.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async { await _auth.logout(); },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Sign out'),
                ),
              ),
            ]),
          )),
        )),
      );
    }

    // Not signed in — show Google Sign-In button
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.jpg', height: 64, width: 64, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.admin_panel_settings, size: 64, color: AppColors.primary)),
                ),
                const SizedBox(height: 16),
                const Text('Admin Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Sign in with your authorized Google account',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                // Google Sign-In button (matches website style)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _signing ? null : _signIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFDADCE0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _signing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            // Google G logo
                            CustomPaint(size: const Size(20, 20), painter: _GoogleLogoPainter()),
                            const SizedBox(width: 12),
                            const Text('Sign in with Google',
                              style: TextStyle(color: Color(0xFF3C4043), fontWeight: FontWeight.w500, fontSize: 15)),
                          ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2;
    // Simplified Google G — four colored arcs
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -0.3, 1.9, false, paint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.28);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), 1.6, 1.1, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), 2.7, 0.8, false, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -1.2, 0.9, false, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}
