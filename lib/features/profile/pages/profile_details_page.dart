import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/info_tile.dart';

class ProfileDetailsPage extends StatelessWidget {
  const ProfileDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: const [
            InfoTile(
              icon: Icons.person_outline,
              title: 'Long',
              subtitle: 'Level 5 | 1250 XP',
            ),
            InfoTile(
              icon: Icons.mail_outline,
              title: 'Email',
              subtitle: 'admin@gmail.com',
            ),
            InfoTile(
              icon: Icons.school_outlined,
              title: 'High school',
              subtitle: 'Step-by-step explanation',
            ),
          ],
        ),
      ),
    );
  }
}
