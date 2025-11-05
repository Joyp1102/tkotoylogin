// lib/home_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Brand
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
      // Branded header
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'TKO TOY CO.',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: tkoBrown,
            ),
          ),
        ),
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_none, color: Colors.black87)),
          IconButton(onPressed: (){}, icon: const Icon(Icons.account_circle_outlined, color: Colors.black87)),
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
/// HOME TAB (clean, responsive)
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
        // soft brand background
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
        Positioned(left: -90, top: -80, child: _bubble(220, tkoOrange.withValues(alpha: .10))),
        Positioned(right: -70, bottom: -40, child: _bubble(180, tkoTeal.withValues(alpha: .10))),
        Positioned(right: 16, top: 64, child: _bubble(70, tkoGold.withValues(alpha: .16))),

        StreamBuilder(
          stream: _settings$(),
          builder: (context, sSnap) {
            if (!sSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: tkoBrown));
            }
            final settings = sSnap.data!.data() ?? {};

            final tiers = (settings['tiers'] as List? ?? [])
                .map((e) => _Tier.fromMap(Map<String, dynamic>.from(e)))
                .toList()
              ..sort((a,b)=>a.min.compareTo(b.min));

            final perks = (settings['perks'] as List? ?? [])
                .map((e) => _Perk.fromMap(Map<String, dynamic>.from(e)))
                .toList();

            final discountsMap = Map<String, dynamic>.from(settings['discounts'] ?? {});
            final earnMultipliers = Map<String, dynamic>.from(settings['earnMultipliers'] ?? {});

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

                // width-aware poster height (16:9)
                final double posterHeight =
                    (MediaQuery.of(context).size.width - 32) * 9 / 16;

                return CustomScrollView(
                  slivers: [
                    // Greeting line
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Good day,', style: TextStyle(color: Colors.black.withValues(alpha: .55))),
                            const SizedBox(height: 2),
                            Text(
                              '$name.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tier progress card
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
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // Posters carousel (fills width)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _PosterCarousel(height: posterHeight),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // Two big tiles: Benefits & Order
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
                            const Expanded(
                              child: _BigTile(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Order',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Quick chips
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                        child: Wrap(
                          spacing: 10, runSpacing: 10,
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

/// Posters (Firestore)
class _Poster {
  final String id, title, imageUrl, subtitle, ctaText, deeplink;
  final int priority;
  _Poster({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.subtitle,
    required this.ctaText,
    required this.deeplink,
    required this.priority,
  });

  factory _Poster.fromDoc(DocumentSnapshot d) {
    final m = (d.data() as Map<String, dynamic>? ?? {});
    return _Poster(
      id: d.id,
      title: (m['title'] ?? '').toString(),
      imageUrl: (m['imageUrl'] ?? '').toString(),
      subtitle: (m['subtitle'] ?? '').toString(),
      ctaText: (m['ctaText'] ?? '').toString(),
      deeplink: (m['deeplink'] ?? '').toString(),
      priority: (m['priority'] ?? 0) is num ? (m['priority'] as num).toInt() : 0,
    );
  }
}

class _PosterCarousel extends StatefulWidget {
  final double height;
  const _PosterCarousel({required this.height});

  @override
  State<_PosterCarousel> createState() => _PosterCarouselState();
}

class _PosterCarouselState extends State<_PosterCarousel> {
  final _page = PageController(viewportFraction: 1.0);

  Stream<List<_Poster>> _posters$() {
    final now = Timestamp.now();

    return FirebaseFirestore.instance
        .collection('posters')
        .orderBy('priority', descending: true)
        .snapshots()
        .map((s) => s.docs
        .where((d) {
      final m = (d.data() as Map<String, dynamic>? ?? {});
      final Timestamp? startsAt = m['startsAt'];
      final Timestamp? endsAt   = m['endsAt'];
      final afterStart = (startsAt == null) || (startsAt.compareTo(now) <= 0);
      final beforeEnd  = (endsAt == null)   || (endsAt.compareTo(now) >= 0);
      return afterStart && beforeEnd;
    })
        .map(_Poster.fromDoc)
        .where((p) => p.title.isNotEmpty && p.imageUrl.isNotEmpty)
        .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_Poster>>(
      stream: _posters$(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final list = snap.data!;
        if (list.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: PageView.builder(
            controller: _page,
            padEnds: false,
            itemCount: list.length,
            itemBuilder: (_, i) => _PosterCard(item: list[i]),
          ),
        );
      },
    );
  }
}

class _PosterCard extends StatelessWidget {
  final _Poster item;
  const _PosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
          ),
          // gradient readable overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: .55),
                    Colors.black.withValues(alpha: .05),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      if (item.subtitle.isNotEmpty)
                        Text(item.subtitle,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: .85))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: .25),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // TODO: open item.deeplink or route
                  },
                  child: Text(item.ctaText.isEmpty ? 'View' : item.ctaText),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final code = 'TKO:$uid';
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
/// Tier/Perk models & helpers
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
    return LayoutBuilder(
      builder: (_, c) {
        final compact = c.maxWidth < 360;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: compact ? 76 : 92, height: compact ? 76 : 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0,1),
                      strokeWidth: 8,
                      color: _tierColor,
                      backgroundColor: Colors.black12,
                    ),
                    Center(
                      child: Text('${(progress*100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TierChip(name: tier, color: _tierColor),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('$yearPoints pts',
                          style: TextStyle(fontSize: compact ? 18 : 22, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        toNextPoints <= 0 ? 'Top tier achieved' : '$toNextPoints pts to next tier',
                        style: TextStyle(color: Colors.black.withValues(alpha: .65)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 16, color: tkoBrown),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('Earn ${earnX.toStringAsFixed(2)}x points per \$1',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.black.withValues(alpha: .7))),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.timeline, size: 16, color: tkoBrown),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('Lifetime: $lifetimePts pts',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.black.withValues(alpha: .7))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .35)),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18), const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
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
      initialChildSize: 0.90,
      minChildSize: 0.50,
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: .12)),
            child: Icon(unlocked ? Icons.verified_rounded : Icons.lock_clock_rounded, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(perk.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (perk.description.isNotEmpty)
                Text(perk.description, style: TextStyle(color: Colors.black.withValues(alpha: .7))),
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
              Text('-${v is num ? v.toStringAsFixed(0) : v}%',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
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