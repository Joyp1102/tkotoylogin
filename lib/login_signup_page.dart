// lib/login_signup_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // --------- TKO BRAND ----------
  static const tkoOrange = Color(0xFFFF6A00); // knockout orange
  static const tkoCream  = Color(0xFFF7F2EC); // warm canvas
  static const tkoBrown  = Color(0xFF6A3B1A); // deep accent
  static const tkoTeal   = Color(0xFF00B8A2); // secondary pop
  static const tkoGold   = Color(0xFFFFD23F); // highlight

  // --------- CONTROLLERS ----------
  final inEmail = TextEditingController();
  final inPass  = TextEditingController();

  final upEmail = TextEditingController();
  final upPass1 = TextEditingController();
  final upPass2 = TextEditingController();

  bool busyEmail = false;
  bool busyGoogle = false;

  late final TabController _tab = TabController(length: 2, vsync: this);

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // --------- AUTH ACTIONS ----------
  Future<void> _signInEmail() async {
    final e = inEmail.text.trim(), p = inPass.text.trim();
    if (e.isEmpty || p.isEmpty) return _toast('Enter email & password');
    setState(() => busyEmail = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: e, password: p);
    } on FirebaseAuthException catch (ex) {
      _toast(ex.message ?? 'Sign in failed');
    } finally {
      if (mounted) setState(() => busyEmail = false);
    }
  }

  Future<void> _forgotPassword() async {
    final ctl = TextEditingController(text: inEmail.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(controller: ctl, decoration: const InputDecoration(labelText: 'Email')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, ctl.text.trim()), child: const Text('Send')),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('Reset link sent.');
    } on FirebaseAuthException catch (ex) {
      _toast(ex.message ?? 'Could not send reset link');
    }
  }

  Future<void> _signUpEmail() async {
    final e = upEmail.text.trim(), p1 = upPass1.text.trim(), p2 = upPass2.text.trim();
    if (e.isEmpty || p1.isEmpty) return _toast('Enter email & password');
    if (p1.length < 6) return _toast('Password must be at least 6 characters');
    if (p1 != p2) return _toast('Passwords do not match');
    setState(() => busyEmail = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: e, password: p1);
    } on FirebaseAuthException catch (ex) {
      _toast(ex.message ?? 'Sign up failed');
    } finally {
      if (mounted) setState(() => busyEmail = false);
    }
  }

  Future<void> _google() async {
    setState(() => busyGoogle = true);
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) return; // cancelled
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      await FirebaseAuth.instance.signInWithCredential(cred);
    } catch (e) {
      _toast('Google sign-in failed (check SHA-1/256 & google-services.json).');
    } finally {
      if (mounted) setState(() => busyGoogle = false);
    }
  }

  // --------- UI ----------
  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      body: Stack(
        children: [
          // Cream gradient canvas
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -1), end: Alignment(1, 1),
                colors: [Colors.white, tkoCream],
                stops: [0.1, 1.0],
              ),
            ),
          ),
          // Brand bubbles (soft)
          Positioned(left: -100, top: -80, child: _bubble(260, tkoOrange.withOpacity(.14))),
          Positioned(right: -80, bottom: -60, child: _bubble(220, tkoTeal.withOpacity(.12))),
          Positioned(right: 24, top: 96, child: _bubble(80, tkoGold.withOpacity(.18))),

          Center(
            child: Theme(
              data: Theme.of(context).copyWith(textTheme: textTheme),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ----- BRAND HEADER (logo + wordmark) -----
                        Column(
                          children: [
                            // Use your asset logo
                            // Make sure it's declared in pubspec.yaml (assets/branding/tko_logo.png)
                            Image.asset('C:\Users\joypa\StudioProjects\tkotoylogin\assets\branding\tko_logo1.png', height: 68),
                            const SizedBox(height: 10),
                            Text('TKO TOY',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: .4,
                                color: tkoBrown,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Remember the fun that matters.',
                                style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ----- Google CTA -----
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: OutlinedButton(
                            onPressed: busyGoogle ? null : _google,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.black.withOpacity(.12)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            child: busyGoogle
                                ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2))
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.g_mobiledata_rounded, size: 26),
                                SizedBox(width: 8),
                                Text('Sign in with Google'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('or email',
                                  style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ----- Tabs -----
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tab,
                            indicator: BoxDecoration(
                              color: tkoOrange.withOpacity(.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelColor: tkoBrown,
                            unselectedLabelColor: Colors.black54,
                            tabs: const [Tab(text: 'Sign in'), Tab(text: 'Sign up')],
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          height: 280,
                          child: TabBarView(
                            controller: _tab,
                            children: [
                              // ---------- SIGN IN ----------
                              Column(
                                children: [
                                  _Field(label: 'Email', controller: inEmail, keyboard: TextInputType.emailAddress),
                                  const SizedBox(height: 10),
                                  _Field(label: 'Password', controller: inPass, obscure: true),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _forgotPassword,
                                      style: TextButton.styleFrom(foregroundColor: tkoBrown),
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _BrandButton(
                                    text: 'Continue',
                                    onPressed: busyEmail ? null : _signInEmail,
                                  ),
                                ],
                              ),

                              // ---------- SIGN UP ----------
                              Column(
                                children: [
                                  _Field(label: 'Email', controller: upEmail, keyboard: TextInputType.emailAddress),
                                  const SizedBox(height: 10),
                                  _Field(label: 'Password (min 6)', controller: upPass1, obscure: true),
                                  const SizedBox(height: 10),
                                  _Field(label: 'Confirm password', controller: upPass2, obscure: true),
                                  const SizedBox(height: 8),
                                  _BrandButton(
                                    text: 'Create account',
                                    onPressed: busyEmail ? null : _signUpEmail,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'By continuing you agree to TKO’s Terms & Privacy.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // subtle brand bubble
  Widget _bubble(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// Glassy elevated card
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 14)),
        ],
      ),
      child: child,
    );
  }
}

// Input field
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  const _Field({required this.label, required this.controller, this.obscure = false, this.keyboard});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.black.withOpacity(.035),
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// Brand button
class _BrandButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const _BrandButton({required this.text, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _LoginPageState.tkoOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
