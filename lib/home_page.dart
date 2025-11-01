// lib/home_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// TKO brand
const tkoOrange = Color(0xFFFF6A00);
const tkoCream  = Color(0xFFF7F2EC);
const tkoBrown  = Color(0xFF6A3B1A);
const tkoTeal   = Color(0xFF00B8A2);
const tkoGold   = Color(0xFFFFD23F);

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const _ScanTab(),
      const _DiscoverTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(['Home', 'Scan', 'Discover', 'Profile'][index]),
        actions: [
          if (index == 0)
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
        ],
      ),
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.qr_code_2_outlined), selectedIcon: Icon(Icons.qr_code_2), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}

/// ------- Firestore helpers -------

class _Tier {
  final String name;
  final int min;
  _Tier(this.name, this.min);

  factory _Tier.fromMap(Map<String, dynamic> m) =>
      _Tier(m['name'] as String, (m['min'] as num).toInt());
}

Stream<DocumentSnapshot<Map<String, dynamic>>> _settings$() =>
    FirebaseFirestore.instance.doc('settings/general').snapshots();

Stream<DocumentSnapshot<Map<String, dynamic>>> _user$() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance.doc('users/$uid').snapshots();
}

/// Pick current tier by points
_Tier _currentTier(List<_Tier> tiers, int points) {
  _Tier cur = tiers.first;
  for (final t in tiers) {
    if (points >= t.min) cur = t;
  }
  return cur;
}

/// Find next threshold (min points for the next tier)
int? _nextThreshold(List<_Tier> tiers, int points) {
  for (final t in tiers) {
    if (points < t.min) return t.min;
  }
  return null;
}

/// ------- Home Tab -------

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final name = FirebaseAuth.instance.currentUser?.displayName ??
        (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Member');

    return Stack(
      children: [
        // soft brand background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -1), end: Alignment(1, 1),
                colors: [Colors.white, tkoCream],
                stops: [0.1, 1.0],
              ),
            ),
          ),
        ),
        Positioned(left: -90, top: -80, child: _bubble(240, tkoOrange.withOpacity(.12))),
        Positioned(right: -70, bottom: -40, child: _bubble(200, tkoTeal.withOpacity(.10))),
        Positioned(right: 16, top: 96, child: _bubble(72, tkoGold.withOpacity(.16))),

        // content
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _settings$(),
          builder: (context, settingsSnap) {
            if (!settingsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final settings = settingsSnap.data!.data() ?? {};
            final tiersRaw = (settings['tiers'] as List? ?? [])
                .map((e) => _Tier.fromMap(Map<String, dynamic>.from(e)))
                .toList()
              ..sort((a, b) => a.min.compareTo(b.min));

            if (tiersRaw.isEmpty) {
              return const Center(child: Text('No tier settings found.'));
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _user$(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final u = userSnap.data!.data() ?? {};
                final yearPts = (u['yearPoints'] ?? 0) as int;
                final lifetimePts = (u['lifetimePts'] ?? 0) as int;

                // compute from settings
                final current = _currentTier(tiersRaw, yearPts);
                final nextMin = _nextThreshold(tiersRaw, yearPts);
                final toNext = nextMin == null ? 0 : (nextMin - yearPts);
                final progress =
                nextMin == null ? 1.0 : (yearPts / nextMin).clamp(0, 1).toDouble();

                return CustomScrollView(
                  slivers: [
                    // greeting
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Good day,', style: TextStyle(color: Colors.black.withOpacity(.55))),
                                  const SizedBox(height: 2),
                                  Text('$name.', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                            const _RoundIcon(icon: Icons.card_giftcard_outlined),
                            const SizedBox(width: 8),
                            const _RoundIcon(icon: Icons.person_outline),
                          ],
                        ),
                      ),
                    ),

                    // Tier + points card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _TierCard(
                          tier: current.name,
                          yearPoints: yearPts,
                          toNextPoints: nextMin == null ? 0 : toNext,
                          progress: progress,
                          lifetimePts: lifetimePts,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Promo banner
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _PromoCard(
                          title: 'Earn 200 Bonus Points',
                          subtitle: 'This week only on select items',
                          imageUrl:
                          'https://images.unsplash.com/photo-1511920170033-f8396924c348?q=80&w=1200&auto=format&fit=crop',
                          badge: '6 new offers',
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Shortcuts
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                      sliver: SliverGrid.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: const [
                          _Shortcut(icon: Icons.shopping_bag_outlined, label: 'Order'),
                          _Shortcut(icon: Icons.stars_rounded, label: 'Rewards'),
                          _Shortcut(icon: Icons.local_offer_outlined, label: 'Offers'),
                          _Shortcut(icon: Icons.store_mall_directory_outlined, label: 'Stores'),
                          _Shortcut(icon: Icons.history, label: 'Activity'),
                          _Shortcut(icon: Icons.favorite_border, label: 'Community'),
                          _Shortcut(icon: Icons.support_agent, label: 'Support'),
                          _Shortcut(icon: Icons.info_outline, label: 'About'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// ------- Scan Tab -------

class _ScanTab extends StatelessWidget {
  const _ScanTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final code = 'TKO:$uid'; // replace with memberCode when you store it
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Membership QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          QrImageView(data: code, size: 240),
          const SizedBox(height: 10),
          const Text('Show at checkout to apply your tier benefits.'),
        ],
      ),
    );
  }
}

/// ------- Discover Tab -------

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();
  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      8,
          (i) => ('Bonus ${100 + i * 25} pts', 'On selected items this week'),
    );

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final (title, sub) = items[i];
        return ListTile(
          leading: const Icon(Icons.local_offer_outlined),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }
}

/// ------- Profile Tab -------

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: (u?.photoURL != null) ? NetworkImage(u!.photoURL!) : null,
            child: (u?.photoURL == null) ? const Icon(Icons.person) : null,
          ),
          title: Text(u?.displayName ?? 'Member'),
          subtitle: Text(u?.email ?? ''),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }
}

/// ------- Widgets -------

class _TierCard extends StatelessWidget {
  final String tier;
  final int yearPoints;
  final int toNextPoints; // 0 when top tier
  final double progress;
  final int lifetimePts;

  const _TierCard({
    required this.tier,
    required this.yearPoints,
    required this.toNextPoints,
    required this.progress,
    required this.lifetimePts,
  });

  Color get _tierColor {
    switch (tier.toLowerCase()) {
      case 'featherweight': return Colors.black87;
      case 'lightweight':   return tkoTeal;
      case 'welterweight':  return tkoGold;
      case 'heavyweight':   return tkoOrange;
      case 'reigning champion': return tkoBrown;
      default: return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // progress ring
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  strokeWidth: 8,
                  color: _tierColor,
                  backgroundColor: Colors.black12,
                ),
                Center(
                  child: Text('${(progress * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TierChip(name: tier, color: _tierColor),
                const SizedBox(height: 6),
                Text('$yearPoints pts',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  toNextPoints == 0 ? 'Top tier achieved' : '$toNextPoints pts to next tier',
                  style: TextStyle(color: Colors.black.withOpacity(.6)),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.all_inclusive, size: 16),
                    const SizedBox(width: 6),
                    Text('Lifetime: $lifetimePts pts',
                        style: TextStyle(color: Colors.black.withOpacity(.7))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final String name;
  final Color color;
  const _TierChip({required this.name, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title, subtitle, imageUrl, badge;
  const _PromoCard({required this.title, required this.subtitle, required this.imageUrl, required this.badge});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            right: 140,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(.7))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: tkoOrange.withOpacity(.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.local_offer_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('6 new offers'),
                        SizedBox(width: 6),
                        Icon(Icons.chevron_right, size: 18),
                      ]),
                    ),
                  ]),
            ),
          ),
          Positioned(
            right: 8, top: 8, bottom: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 124,
                child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Shortcut({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Icon(icon, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  const _RoundIcon({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Ink(
      width: 40,
      height: 40,
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: CircleBorder(),
        shadows: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: IconButton(onPressed: () {}, icon: Icon(icon, size: 20)),
    );
  }
}

Widget _bubble(double size, Color c) =>
    Container(width: size, height: size, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
