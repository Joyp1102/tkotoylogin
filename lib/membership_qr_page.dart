// lib/membership_qr_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

const tkoOrange = Color(0xFFFF6A00);
const tkoTeal   = Color(0xFF00B8A2);
const tkoCream  = Color(0xFFF7F2EC);
const tkoBrown  = Color(0xFF6A3B1A);

class MembershipQRPage extends StatefulWidget {
  const MembershipQRPage({super.key});

  @override
  State<MembershipQRPage> createState() => _MembershipQRPageState();
}

class _MembershipQRPageState extends State<MembershipQRPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final name = user.displayName ?? "Member";
    final memberId = user.uid;
    final qrData = "TKO:$memberId";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // soft background bubbles
          Positioned(
            top: -60,
            left: -40,
            child: _bubble(220, tkoOrange.withOpacity(.12)),
          ),
          Positioned(
            bottom: -30,
            right: -40,
            child: _bubble(200, tkoTeal.withOpacity(.10)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  const SizedBox(height: 6),

                  // Only one logo on this page
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'assets/branding/tko_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "$name’s Membership",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: tkoBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Show this QR at TKO TOY CO. to earn or redeem points.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(.7),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Premium QR card with pulse animation
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.97, end: 1.03)
                        .animate(CurvedAnimation(
                      parent: _pulseCtrl,
                      curve: Curves.easeInOut,
                    )),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: tkoTeal.withOpacity(.35),
                          width: 2,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            tkoCream.withOpacity(.55),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // colorful ring around QR
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  tkoOrange,
                                  tkoTeal,
                                  tkoOrange,
                                ],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: QrImageView(
                                data: qrData,
                                size: 220,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Member ID chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.black.withOpacity(.05),
                            ),
                            child: Text(
                              "Member ID: ${memberId.substring(0, 6)}...",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: tkoBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 18, color: tkoTeal),
                      const SizedBox(width: 6),
                      Text(
                        "Secure one-tap loyalty at checkout.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Wallet buttons (UI only – hook up later)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _WalletButton(
                        icon: Icons.account_balance_wallet_rounded,
                        label: "Add to Apple Wallet",
                      ),
                      SizedBox(width: 10),
                      _WalletButton(
                        icon: Icons.wallet_rounded,
                        label: "Add to Google Wallet",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WalletButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WalletButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              tkoCream.withOpacity(.9),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // TODO: integrate Apple/Google Wallet pass here
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: tkoBrown),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tkoBrown,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
