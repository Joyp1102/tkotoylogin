import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  final _signinEmail = TextEditingController();
  final _signinPass  = TextEditingController();

  final _signupEmail = TextEditingController();
  final _signupPass  = TextEditingController();
  final _signupPass2 = TextEditingController();

  bool loadingEmail = false;
  bool loadingGoogle = false;

  // ---------- helpers ----------
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signInEmail() async {
    final email = _signinEmail.text.trim();
    final pass  = _signinPass.text.trim();
    if (email.isEmpty || pass.isEmpty) return _toast('Enter email and password');
    setState(() => loadingEmail = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Sign in failed');
    } finally { if (mounted) setState(() => loadingEmail = false); }
  }

  Future<void> _signUpEmail() async {
    final email = _signupEmail.text.trim();
    final p1    = _signupPass.text.trim();
    final p2    = _signupPass2.text.trim();
    if (email.isEmpty || p1.isEmpty) return _toast('Enter email and password');
    if (p1.length < 6) return _toast('Password must be at least 6 chars');
    if (p1 != p2) return _toast('Passwords do not match');
    setState(() => loadingEmail = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: p1);
      _toast('Account created! You are signed in.');
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Sign up failed');
    } finally { if (mounted) setState(() => loadingEmail = false); }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _signinEmail.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Send')),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Could not send reset email');
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => loadingGoogle = true);
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) return; // cancelled
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      await FirebaseAuth.instance.signInWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Google sign-in failed');
    } finally { if (mounted) setState(() => loadingGoogle = false); }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF7F2EC);
    const accent = Color(0xFFFF6A00);
    const deep   = Color(0xFF6A3B1A);

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [cream, Colors.white],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
          )),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0,10))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TKO Loyalty',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900, color: deep)),
                      const SizedBox(height: 6),
                      Text('Collect. Level up. Knockout rewards.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                      const SizedBox(height: 16),

                      // Google
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: loadingGoogle ? null : _continueWithGoogle,
                          icon: loadingGoogle
                              ? const SizedBox(height:18,width:18,child:CircularProgressIndicator(strokeWidth:2))
                              : const Icon(Icons.g_mobiledata_rounded, size: 22),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tabs
                      TabBar(
                        controller: _tab,
                        labelColor: deep,
                        tabs: const [Tab(text:'Sign in'), Tab(text:'Sign up')],
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 250,
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            // ----- Sign in -----
                            Column(
                              children: [
                                TextField(
                                  controller: _signinEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email', border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _signinPass,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password', border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword, child: const Text('Forgot password?'),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: loadingEmail ? null : _signInEmail,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: loadingEmail
                                        ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                                        : const Text('Sign in', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),

                            // ----- Sign up -----
                            Column(
                              children: [
                                TextField(
                                  controller: _signupEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email', border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _signupPass, obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password (min 6 chars)', border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _signupPass2, obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirm password', border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: loadingEmail ? null : _signUpEmail,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: loadingEmail
                                        ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                                        : const Text('Create account', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),
                      Text(
                        'By continuing you agree to TKO’s Terms & Privacy.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
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
