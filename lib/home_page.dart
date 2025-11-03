// home_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// ----------------------
/// TKO brand colors
/// ----------------------
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
        title: Text(['Home','Scan','Discover','Profile'][index]),
        actions: [
          if (index == 0) ...[
            IconButton(
              tooltip: 'Gifts',
              onPressed: () {},
              icon: const Icon(Icons.card_giftcard_outlined),
            ),
            IconButton(
              tooltip: 'Account',
              onPressed: () {},
              icon: const Icon(Icons.person_outline),
            ),
          ],
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

/// =========================
/// CLEAN HOME TAB (compact)
/// =========================
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Stream<DocumentSnapshot<Map<String, dynamic>>> _settings$() =>
      FirebaseFirestore.instance.doc('settings/general').snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> _user$() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.doc('users/$uid').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final name = FirebaseAuth.instance.currentUser?.displayName ??
        (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Member');

    return Stack(
      children: [
        // soft background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1,-1), end: Alignment(1,1),
                colors: [Colors.white, tkoCream],
              ),
            ),
          ),
        ),
        Positioned(left: -90, top: -80, child: _bubble(220, tkoOrange.withOpacity(.10))),
        Positioned(right: -70, bottom: -40, child: _bubble(180, tkoTeal.withOpacity(.10))),

        StreamBuilder(
          stream: _settings$(),
          builder: (context, sSnap) {
            if (!sSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: tkoBrown));
            }
            final settings = sSnap.data!.data() ?? {};

            // ---- parse settings ----
            final tiers = (settings['tiers'] as List? ?? [])
                .map((e) => _Tier.fromMap(Map<String, dynamic>.from(e)))
                .toList()
              ..sort((a,b)=>a.min.compareTo(b.min));

            final perks = (settings['perks'] as List? ?? [])
                .map((e) => _Perk.fromMap(Map<String, dynamic>.from(e)))
                .toList();

            final discountsMap = Map<String, dynamic>.from(settings['discounts'] ?? {});
            final earnMultipliers = Map<String, dynamic>.from(settings['earnMultipliers'] ?? {});
            final promoImage = settings['promoImage'] ??
                'https://images.unsplash.com/photo-1511920170033-f8396924c348?q=80&w=1200&auto=format&fit=crop';

            return StreamBuilder(
              stream: _user$(),
              builder: (context, uSnap) {
                if (!uSnap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: tkoBrown));
                }
                if (!uSnap.data!.exists) {
                  FirebaseFirestore.instance
                      .doc('users/${FirebaseAuth.instance.currentUser!.uid}')
                      .set({'tier':'Featherweight','yearPoints':0,'lifetimePts':0}, SetOptions(merge:true));
                  return const Center(child: CircularProgressIndicator(color: tkoBrown));
                }

                final u = uSnap.data!.data()!;
                final yearPts    = (u['yearPoints'] ?? 0) as int;
                final lifetime   = (u['lifetimePts'] ?? 0) as int;
                final curTier    = _currentTier(tiers, yearPts);
                final nextThresh = _nextThreshold(tiers, yearPts);
                final toNext     = nextThresh == null ? 0 : (nextThresh - yearPts);
                final progress   = nextThresh == null ? 1.0 : (yearPts / nextThresh).clamp(0,1).toDouble();
                final earnX      = ((earnMultipliers[curTier.name] ?? 1.0) as num).toDouble();

                return CustomScrollView(
                  slivers: [
                    // Greeting + icons
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
                                  Text('$name.',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
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

                    // Tier card (overflow-safe)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _TierCard(
                          tier: curTier.name,
                          yearPoints: yearPts,
                          toNextPoints: toNext,
                          progress: progress,
                          lifetimePts: lifetime,
                          earnX: earnX,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // --- Promo banner: Earn 200 Bonus Points ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _PromoCard(
                          title: 'Earn 200 Bonus Points',
                          subtitle: 'This week only on select items',
                          imageUrl: promoImage,
                          badge: '6 new offers',
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Big tiles: Benefits + Order
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _BigTile(
                                icon: Icons.workspace_premium_rounded,
                                label: 'Benefits',
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    builder: (_) => _BenefitsSheet(
                                      currentPoints: yearPts,
                                      tiers: tiers,
                                      perks: perks,
                                      discountsMap: discountsMap,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _BigTile(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Order',
                                onTap: () {}, // TODO: wire to your ordering flow
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Minimal quick actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _QuickChip(icon: Icons.qr_code_2, label: 'Scan'),
                            _QuickChip(icon: Icons.store_mall_directory_outlined, label: 'Stores'),
                            _QuickChip(icon: Icons.history, label: 'Activity'),
                            _QuickChip(icon: Icons.support_agent, label: 'Support'),
                          ],
                        ),
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

/// =========================
/// Scan tab (QR)
/// =========================
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

/// =========================
/// Discover (placeholder)
/// =========================
class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();
  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      8, (i) => ('Bonus ${100 + i * 25} pts', 'On selected items this week'),
    );
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return ListTile(
          leading: const Icon(Icons.local_offer_outlined),
          title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(item.$2),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }
}

/// =========================
/// Profile
/// =========================
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

/// =========================
/// Models
/// =========================
class _Tier {
  final String name;
  final int min;
  const _Tier({required this.name, required this.min});
  factory _Tier.fromMap(Map<String, dynamic> m) =>
      _Tier(name: m['name'] as String, min: (m['min'] as num).toInt());
}

class _Perk {
  final String title;
  final String description;
  final String minTierName;
  const _Perk({required this.title, required this.description, required this.minTierName});
  factory _Perk.fromMap(Map<String, dynamic> m) => _Perk(
    title: m['title'] ?? m['name'] ?? '',
    description: m['description'] ?? '',
    minTierName: m['minTier'] ?? m['minTierName'] ?? 'Featherweight',
  );
}

/// =========================
/// Helpers
/// =========================
_Tier _currentTier(List<_Tier> tiers, int pts) {
  _Tier cur = tiers.first;
  for (final t in tiers) {
    if (pts >= t.min) cur = t;
  }
  return cur;
}

int? _nextThreshold(List<_Tier> tiers, int pts) {
  for (final t in tiers) {
    if (pts < t.min) return t.min;
  }
  return null;
}

int _tierIndexByName(List<_Tier> tiers, String name) =>
    tiers.indexWhere((t) => t.name.toLowerCase() == name.toLowerCase());

/// =========================
/// UI pieces
/// =========================
class _TierCard extends StatelessWidget {
  final String tier;
  final int yearPoints;
  final int toNextPoints;
  final double progress;
  final int lifetimePts;
  final double earnX;
  const _TierCard({
    required this.tier,
    required this.yearPoints,
    required this.toNextPoints,
    required this.progress,
    required this.lifetimePts,
    required this.earnX,
  });

  Color get _tierColor {
    switch (tier.toLowerCase()) {
      case 'lightweight': return tkoGold;
      case 'welterweight': return tkoOrange;
      case 'heavyweight': return tkoBrown;
      case 'reigning champion': return tkoTeal;
      default: return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // let it grow if needed; avoid fixed height
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88, height: 88,
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
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TierChip(name: tier, color: _tierColor),
                const SizedBox(height: 4),
                Text(
                  '$yearPoints pts',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  toNextPoints <= 0 ? 'Top tier achieved' : '$toNextPoints pts to next tier',
                  style: TextStyle(color: Colors.black.withOpacity(.65)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _InfoPill(icon: Icons.bolt, text: 'Earn ${earnX.toStringAsFixed(2)}x per \$1'),
                    _InfoPill(icon: Icons.timeline, text: 'Lifetime: $lifetimePts pts'),
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: tkoBrown),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.black.withOpacity(.72))),
      ],
    );
  }
}

class _TierChip extends StatelessWidget {
  final String name; final Color color;
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
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.local_offer_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(badge),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right, size: 18),
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

class _BigTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _BigTile({required this.icon, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon; final String label;
  const _QuickChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18), const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon; const _RoundIcon({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Ink(
      width: 40, height: 40,
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

/// ------------------------
/// Benefits bottom sheet
/// ------------------------
class _BenefitsSheet extends StatefulWidget {
  final int currentPoints;
  final List<_Tier> tiers;
  final List<_Perk> perks;
  final Map<String, dynamic> discountsMap;
  const _BenefitsSheet({
    required this.currentPoints,
    required this.tiers,
    required this.perks,
    required this.discountsMap,
  });

  @override
  State<_BenefitsSheet> createState() => _BenefitsSheetState();
}

class _BenefitsSheetState extends State<_BenefitsSheet> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    final curTier = _currentTier(widget.tiers, widget.currentPoints);
    final curIdx  = widget.tiers.indexOf(curTier);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 44, height: 5, decoration: BoxDecoration(
            color: Colors.black12, borderRadius: BorderRadius.circular(20),
          )),
          const SizedBox(height: 12),
          const Text('Your Benefits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          TabBar(
            controller: _tab,
            indicatorColor: tkoOrange,
            labelColor: Colors.black,
            tabs: const [Tab(text: 'Perks'), Tab(text: 'Discounts')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // PERKS
                ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.perks.length,
                  itemBuilder: (_, i) {
                    final p = widget.perks[i];
                    final needIdx = _tierIndexByName(widget.tiers, p.minTierName);
                    final unlocked = (needIdx != -1 && needIdx <= curIdx);
                    int? pointsLeft;
                    if (!unlocked && needIdx != -1) {
                      pointsLeft = (widget.tiers[needIdx].min - widget.currentPoints).clamp(0, 1<<31);
                    }
                    return _PerkTile(perk: p, unlocked: unlocked, pointsLeft: pointsLeft);
                  },
                ),

                // DISCOUNTS
                ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DiscountsPanel(
                      tierName: curTier.name,
                      discountsMap: widget.discountsMap,
                    ),
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

class _PerkTile extends StatelessWidget {
  final _Perk perk;
  final bool unlocked;
  final int? pointsLeft;
  const _PerkTile({required this.perk, required this.unlocked, this.pointsLeft});

  @override
  Widget build(BuildContext context) {
    final c = unlocked ? Colors.green : Colors.orange;
    final status = unlocked ? 'Unlocked' :
    (pointsLeft != null ? '$pointsLeft pts to unlock' : 'Locked');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(.12)),
            child: Icon(unlocked ? Icons.verified_rounded : Icons.lock_clock_rounded, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(perk.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (perk.description.isNotEmpty)
                Text(perk.description, style: TextStyle(color: Colors.black.withOpacity(.7))),
              Text(status, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
            ]),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _DiscountsPanel extends StatelessWidget {
  final String tierName;
  final Map<String, dynamic> discountsMap;
  const _DiscountsPanel({required this.tierName, required this.discountsMap});

  @override
  Widget build(BuildContext context) {
    final tierDisc = Map<String, dynamic>.from(discountsMap[tierName] ?? {});
    final rows = <Widget>[];
    tierDisc.forEach((k, v) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 18, color: tkoBrown),
              const SizedBox(width: 10),
              Expanded(child: Text(k)),
              Text(
                v is num ? '-${v.toStringAsFixed(0)}%' : '-$v%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
      rows.add(const Divider(height: 1));
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$tierName Discounts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }
}
