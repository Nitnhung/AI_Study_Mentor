import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/info_tile.dart';

class ProfileDetailsPage extends StatelessWidget {
  const ProfileDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = ApiService.email ?? '';
    final name = email.split('@').first;
    final xp = ApiService.xpPoints;
    final level = (xp / 250).floor().clamp(1, 99);

    return Scaffold(backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Users'), backgroundColor: Colors.white, foregroundColor: AppColors.text),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
        InfoTile(icon: Icons.person_outline, title: name, subtitle: 'Level $level | $xp XP'),
        InfoTile(icon: Icons.mail_outline, title: 'Email', subtitle: email),
        InfoTile(icon: Icons.school_outlined, title: ApiService.educationLevel ?? 'High school',
          subtitle: ApiService.preferredStyle ?? 'Step-by-step'),
      ])));
  }
}
