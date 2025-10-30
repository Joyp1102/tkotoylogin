import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass  = TextEditingController();
  bool loadingEmail = false;
  bool loadingGoogle = false;

  Future<void> _continueEmail() async {
    setState(() => loadingEmail = true);
    try {
      // try sign-in, else create
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: pass.text.trim());
    } on FirebaseAuthException {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(), password: pass.text.trim());
    } finally {
      if (mounted) setState(() => loadingEmail = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => loadingGoogle = true);
    try {
      // 1) Google account picker
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) { setState(() => loadingGoogle = false); return; } // cancelled
      // 2) Tokens
      final gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      // 3) Firebase sign-in
      await FirebaseAuth.instance.signInWithCredential(credential);
    } finally {
      if (mounted) setState(() => loadingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Brand colors
    const cream = Color(0xFFF7F2EC);
    const accent = Color(0xFFFF6A00);
    const deep   = Color(0xFF6A3B1A);

    return Scaffold(
      body: Stack(
        children: [
          // soft gradient background
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
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand mark
                      Text('TKO Loyalty',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900, color: deep)),
                      const SizedBox(height: 4),
                      Text('Collect. Level up. Knockout rewards.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                      const SizedBox(height: 24),

                      // Google button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: loadingGoogle ? null : _continueWithGoogle,
                          icon: loadingGoogle
                              ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.g_mobiledata_rounded, size: 22),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Divider
                      Row(children: const [
                        Expanded(child: Divider()), SizedBox(width: 8),
                        Text('or email', style: TextStyle(color: Colors.black45)),
                        SizedBox(width: 8), Expanded(child: Divider()),
                      ]),
                      const SizedBox(height: 12),

                      // Email / Password
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email', border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: pass, obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password', border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Continue button (brand color)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: loadingEmail ? null : _continueEmail,
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: loadingEmail
                              ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Continue', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
