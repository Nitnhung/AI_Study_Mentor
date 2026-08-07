import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../auth/pages/auth_screen.dart';
import '../../history/pages/history_page.dart';
import '../../leaderboard/pages/leaderboard_page.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(backgroundColor: Colors.white,
      child: SafeArea(child: ListView(padding: EdgeInsets.zero, children: [
        const Padding(padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Text('AI Mentor Study', style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w900))),
        _DrawerItem(icon: Icons.home_outlined, title: 'Trang chủ', onTap: () => Navigator.pop(context)),
        _DrawerItem(icon: Icons.history, title: 'Lịch sử câu hỏi', onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
        }),
        _DrawerItem(icon: Icons.leaderboard_outlined, title: 'Bảng xếp hạng', onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardPage()));
        }),
        const Divider(height: 28),
        ListTile(leading: const Icon(Icons.logout, color: AppColors.danger),
          title: const Text('Đăng xuất', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          onTap: () async {
            try { await ApiService.clearSession(); } catch (_) {}
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
            }
          }),
      ])));
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback? onTap;
  const _DrawerItem({required this.icon, required this.title, this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon, color: AppColors.text),
      title: Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      onTap: onTap ?? () => Navigator.pop(context));
  }
}
