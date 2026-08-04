import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/info_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const notifications = [
      'Bạn đạt 1000 XP',
      'Quiz mới đã sẵn sàng',
      'Bạn chưa học hôm nay',
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: notifications
              .map(
                (item) => InfoTile(
                  icon: Icons.notifications_none,
                  title: item,
                  subtitle: 'Vừa xong',
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
