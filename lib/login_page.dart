import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Brand colors
  static const cream  = Color(0xFFF7F2EC);
  static const accent = Color(0xFFFF6A00);
  static const deep   = Color(0xFF6A3B1A);

  final email = TextEditingController();
  final pass  = TextEditingController();
  bool loadingEmail = false;
  bool loadingGoogle = false;

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid'         : user.uid,
        'email'       : user.email,
        'displayName' : user.displayName ?? '',
        'photoURL'    : user.photoURL ?? '',
        'yearPoints'  : 0,
        'lifetimePts' : 0,
        'tier'        : 'Featherweight',
        'createdAt'   : FieldValue.serverTimestamp(),
        'updatedAt'   : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.set({'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    }
  }

  Future<void> _continueEmail() async {
    final e = email.text.trim();
    final p = pass.text.trim();
    if (e.isEmpty || p.isEmpty) {
      _toast('Enter email and password'); return;
    }
    setState(() => loadingEmail = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: e, password: p);
      await _ensureUserDoc(cred.user!);
    } on FirebaseAuthException catch (ex) {
      if (ex.code == 'user-not-found') {
        if (p.length < 6) {
          _toast('Password must be at least 6 characters');
        } else {
          final cred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: e, password: p);
          await _ensureUserDoc(cred.user!);
        }
      } else {
        _toast(ex.message ?? 'Sign in failed');
      }
    } finally {
      if (mounted) setState(() => loadingEmail = false);
    }
  }

  Future<void> _forgotPassword() async {
    final addr = email.text.trim();
    if (addr.isEmpty) { _toast('Enter your email first'); return; }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: addr);
      _toast('Reset link sent to $addr');
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Could not send reset link');
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => loadingGoogle = true);
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) return;
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      final result = await FirebaseAuth.instance.signInWithCredential(cred);
      await _ensureUserDoc(result.user!);
    } catch (_) {
      _toast('Google sign-in failed. Check SHA-1/256 & google-services.json.');
    } finally {
      if (mounted) setState(() => loadingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [cream, Colors.white],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(
                      color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Logo (optional) + Title
                  SizedBox(
                    height: 56,
                    child: Image.asset(
                      'assets/branding/tko_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('TKO Loyalty',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900, color: deep)),
                  const SizedBox(height: 4),
                  Text('Collect. Level up. Knockout rewards.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      )),
                  const SizedBox(height: 24),

                  // Google
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: loadingGoogle ? null : _continueWithGoogle,
                      icon: loadingGoogle
                          ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.g_mobiledata_rounded, size: 22),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // divider
                  Row(children: const [
                    Expanded(child: Divider()), SizedBox(width: 8),
                    Text('or email', style: TextStyle(color: Colors.black45)),
                    SizedBox(width: 8), Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 12),

                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pass, obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password', border: OutlineInputBorder()),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 6),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loadingEmail ? null : _continueEmail,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loadingEmail
                          ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : const Text('Continue',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
