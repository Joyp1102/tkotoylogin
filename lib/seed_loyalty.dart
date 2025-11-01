// lib/seed_loyalty.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedLoyaltyConfig() async {
  final doc = FirebaseFirestore.instance.doc('settings/general');

  final tiers = [
    {"name": "Featherweight", "min": 0},
    {"name": "Lightweight", "min": 1500},
    {"name": "Welterweight", "min": 5000},
    {"name": "Heavyweight", "min": 30000},
    {"name": "Reigning Champion", "min": 1000000},
  ];

  final discounts = {
    "Featherweight": {"singles": 0, "sealed": 0, "supplies": 0, "toys": 0},
    "Lightweight": {"singles": 3, "sealed": 2, "supplies": 4, "toys": 5},
    "Welterweight": {"singles": 7, "sealed": 2, "supplies": 8, "toys": 8},
    "Heavyweight": {"singles": 10, "sealed": 3, "supplies": 12, "toys": 13},
    "Reigning Champion": {"singles": 15, "sealed": 5, "supplies": 20, "toys": 15},
  };

  final perks = [
    // Access / Pre-orders
    {"title":"Access to Pre-Orders","desc":"Case by case depending on allocation (In Store Only).","icon":"bolt","minTier":"Welterweight"},
    {"title":"Guaranteed Access to Pre-Orders","desc":"1 item per SKU guaranteed (In Store Only).","icon":"bolt","minTier":"Heavyweight"},
    {"title":"Guaranteed Access to Pre-Orders","desc":"1 case per SKU (In Store Only).","icon":"bolt","minTier":"Reigning Champion"},

    // Events
    {"title":"Priority Registration","desc":"Early registration for events.","icon":"event","minTier":"Welterweight"},
    {"title":"Private Tier Events","desc":"Invite-only events for Heavyweight+.","icon":"event","minTier":"Heavyweight"},
    {"title":"VIP-Only Invites","desc":"Exclusive invites for top tier.","icon":"star","minTier":"Reigning Champion"},

    // Discord
    {"title":"Discord Access","desc":"Join our community Discord.","icon":"extension","minTier":"Featherweight"},
    {"title":"Priority Channels","desc":"Access tier-priority channels.","icon":"extension","minTier":"Heavyweight"},

    // Price & Hold
    {"title":"Same-Day Price + Product Lock","desc":"We’ll honor same-day price & lock product.","icon":"percent","minTier":"Welterweight"},
    {"title":"48-Hour Price + Product Lock","desc":"Hold & price protection for 48 hours.","icon":"percent","minTier":"Heavyweight"},
    {"title":"72-Hour Price + Product Lock","desc":"Hold & price protection for 72 hours.","icon":"percent","minTier":"Reigning Champion"},

    // Community bonus points
    {"title":"Community Bonus Points","desc":"Extra points for events & tournaments.","icon":"star","minTier":"Lightweight"},

    // Guaranteed status / freeze
    {"title":"Guaranteed Lightweight","desc":"You won’t drop below Lightweight next year.","icon":"workspace","minTier":"Lightweight"},
    {"title":"Guaranteed Lightweight (Keep Welterweight)","desc":"15000 yearly pts keeps Welterweight.","icon":"workspace","minTier":"Welterweight"},
    {"title":"Guaranteed Welterweight (Keep Heavyweight)","desc":"45000 yearly pts keeps Heavyweight.","icon":"workspace","minTier":"Heavyweight"},
    {"title":"Guaranteed Heavyweight","desc":"Top tier status safety net.","icon":"workspace","minTier":"Reigning Champion"},
    {"title":"Tier Freeze x1","desc":"Lock your tier once this year.","icon":"lock","minTier":"Welterweight"},
    {"title":"Tier Freeze x2","desc":"Lock your tier twice this year.","icon":"lock","minTier":"Heavyweight"},
  ];

  final earnMultipliers = {
    "Featherweight": 1.0,
    "Lightweight": 1.0,
    "Welterweight": 1.25,
    "Heavyweight": 1.5,
    "Reigning Champion": 2.0,
  };

  await doc.set({
    "pointsPerDollar": 1,
    "tiers": tiers,
    "discounts": discounts,
    "perks": perks,
    "earnMultipliers": earnMultipliers,
    "updatedAt": FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
