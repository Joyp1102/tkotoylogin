// lib/perk_details_page.dart
import 'package:flutter/material.dart';

const tkoOrange = Color(0xFFFF6A00);
const tkoCream  = Color(0xFFF7F2EC);

class PerkDetailsPage extends StatelessWidget {
  final String title;
  final String desc;
  final String iconName;
  final String minTierName;
  final bool unlocked;
  final int? pointsLeft;

  const PerkDetailsPage({
    super.key,
    required this.title,
    required this.desc,
    required this.iconName,
    required this.minTierName,
    required this.unlocked,
    this.pointsLeft,
  });

  IconData _iconFromName(String n) {
    switch (n) {
      case 'percent':   return Icons.percent_rounded;
      case 'extension': return Icons.extension_rounded;
      case 'bolt':      return Icons.bolt_rounded;
      case 'event':     return Icons.event_available_rounded;
      case 'star':      return Icons.star_rounded;
      case 'workspace': return Icons.workspace_premium_rounded;
      case 'lock':      return Icons.lock_outline_rounded;
      default:          return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        title: const Text('Perk details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // hero card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: tkoOrange.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconFromName(iconName), color: tkoOrange, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              unlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
                              size: 18,
                              color: unlocked ? Colors.green : Colors.black45,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              unlocked ? 'Unlocked' : 'Locked',
                              style: TextStyle(
                                color: unlocked ? Colors.green : Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // description
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Text(
                desc,
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
            ),
            const SizedBox(height: 16),

            // requirement & CTA
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Requirement',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Available at tier: $minTierName',
                      style: TextStyle(color: Colors.black.withOpacity(.7))),
                  if (!unlocked && pointsLeft != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 18),
                        const SizedBox(width: 8),
                        Text('${pointsLeft} pts to unlock',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tkoOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Earn points'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
