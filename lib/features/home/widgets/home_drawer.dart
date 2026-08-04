import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/pages/auth_screen.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Text(
                'AI Mentor Study',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const _DrawerItem(icon: Icons.home_outlined, title: 'Trang chủ'),
            const _DrawerItem(icon: Icons.bookmark_border, title: 'Bookmark'),
            const _DrawerItem(
              icon: Icons.workspace_premium_outlined,
              title: 'Thành tích',
            ),
            const _DrawerItem(
              icon: Icons.leaderboard_outlined,
              title: 'Bảng xếp hạng',
            ),
            const _DrawerItem(icon: Icons.settings_outlined, title: 'Cài đặt'),
            const Divider(height: 28),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () => Navigator.of(context).pop(),
    );
  }
}
