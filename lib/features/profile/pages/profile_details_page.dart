import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'profile_page.dart';

class ProfileDetailsPage extends StatelessWidget {
  const ProfileDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
      ),
      body: const SafeArea(child: ProfilePage()),
    );
  }
}
