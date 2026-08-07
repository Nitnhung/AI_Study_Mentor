import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

class WelcomePanel extends StatelessWidget {
  const WelcomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final name = (ApiService.email ?? 'User').split('@').first;
    final xp = ApiService.xpPoints;
    final level = (xp / 250).floor().clamp(1, 99);
    final nextLevelXp = (level + 1) * 250;
    final progress = xp / nextLevelXp;

    return Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.softBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Chào mừng trở lại, $name', style: const TextStyle(color: AppColors.text, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Level $level  |  $xp XP', style: const TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 9,
            backgroundColor: AppColors.softBorder, valueColor: const AlwaysStoppedAnimation(AppColors.primary))),
        const SizedBox(height: 8),
        Text('$xp / $nextLevelXp XP', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ]));
  }
}
