// lib/membership_qr_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Keep brand colors in sync with home_page.dart
const tkoOrange = Color(0xFFFF6A00);
const tkoCream  = Color(0xFFF7F2EC);
const tkoBrown  = Color(0xFF6A3B1A);
const tkoTeal   = Color(0xFF00B8A2);
const tkoGold   = Color(0xFFFFD23F);

class MembershipQRPage extends StatelessWidget {
  const MembershipQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ??
        (user?.email?.split('@').first ?? 'Member');
    final uid = user?.uid ?? 'guest';
    final memberId =
    uid.length > 8 ? uid.substring(0, 8).toUpperCase() : uid.toUpperCase();
    final code = 'TKO:$uid';

    return Stack(
      children: [
        // -------- Background (full-screen) --------
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF5EC),
                  Color(0xFFFDF7F3),
                  Color(0xFFF4FBF8),
                ],
              ),
            ),
          ),
        ),
        Positioned(top: -80, left: -40,
            child: _bubble(220, tkoOrange.withOpacity(.10))),
        Positioned(top: 40, right: -60,
            child: _bubble(160, tkoGold.withOpacity(.16))),
        Positioned(bottom: -70, right: -30,
            child: _bubble(230, tkoTeal.withOpacity(.16))),
        const Positioned(
          top: 120,
          left: 40,
          child: Icon(Icons.auto_awesome, size: 18, color: tkoGold),
        ),
        const Positioned(
          top: 155,
          right: 46,
          child: Icon(Icons.auto_awesome, size: 16, color: tkoTeal),
        ),

        // -------- Content --------
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // small label chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.04),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.workspace_premium,
                                  size: 14, color: tkoBrown),
                              SizedBox(width: 6),
                              Text(
                                'Loyalty Membership',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tkoBrown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      "$name's Membership",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tkoBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Show this QR at checkout to earn or redeem points.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Main card
                    _MembershipCard(code: code, memberId: memberId),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified_rounded,
                            size: 18, color: tkoTeal),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Secure one-tap loyalty at checkout.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Wallet buttons
                    Row(
                      children: const [
                        Expanded(
                          child: _WalletButton(
                            icon: Icons.wallet,
                            label: 'Add to Apple Wallet',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _WalletButton(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Add to Google Wallet',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Anime-style gradient card with QR
class _MembershipCard extends StatelessWidget {
  final String code;
  final String memberId;
  const _MembershipCard({
    required this.code,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tkoTeal, tkoGold, tkoOrange],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.white.withOpacity(.96),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // glow behind QR
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x1A00B8A2),
                    Color(0x1AFF6A00),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: code,
                  size: 210,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // member id pill
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.black.withOpacity(.03),
              ),
              child: Text(
                'Member ID: $memberId',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tkoBrown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _WalletButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        // TODO: integrate with actual wallet passes (Apple / Google Pay) later.
      },
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: tkoBrown),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tkoBrown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _bubble(double size, Color c) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
);
