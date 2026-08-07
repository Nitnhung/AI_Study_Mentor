import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileSummaryCard extends StatelessWidget {
  final String email;
  final int xp;
  const ProfileSummaryCard({super.key, this.email = '', this.xp = 0});

  @override
  Widget build(BuildContext context) {
    final level = (xp / 250).floor().clamp(1, 99);
    final progress = (xp % 250) / 250;
    return Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.softBorder)),
      child: Row(children: [
        Container(width: 62, height: 62,
          decoration: const BoxDecoration(color: AppColors.softPrimary, shape: BoxShape.circle),
          child: const Icon(Icons.person, color: AppColors.primary, size: 34)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(email.split('@').first, style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('Level $level | $xp XP', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 6,
              backgroundColor: AppColors.softBorder, valueColor: const AlwaysStoppedAnimation(AppColors.primary))),
        ])),
      ]));
  }
}
