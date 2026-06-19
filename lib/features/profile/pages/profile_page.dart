import 'package:flutter/material.dart';

import '../../../core/widgets/info_tile.dart';
import '../../../core/widgets/section_title.dart';
import '../widgets/profile_summary_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: const [
        SectionTitle(title: 'Profile'),
        SizedBox(height: 14),
        ProfileSummaryCard(),
        SizedBox(height: 18),
        SectionTitle(title: 'Thông tin cá nhân'),
        SizedBox(height: 12),
        InfoTile(
          icon: Icons.mail_outline,
          title: 'Email',
          subtitle: 'admin@gmail.com',
        ),
        InfoTile(
          icon: Icons.phone_outlined,
          title: 'Số điện thoại',
          subtitle: 'Chưa cập nhật',
        ),
        InfoTile(
          icon: Icons.school_outlined,
          title: 'Cấp học',
          subtitle: 'High school',
        ),
        SizedBox(height: 12),
        InfoTile(
          icon: Icons.language,
          title: 'Đổi ngôn ngữ',
          subtitle: 'Tiếng Việt / English',
        ),
        InfoTile(
          icon: Icons.lock_reset,
          title: 'Đổi mật khẩu',
          subtitle: 'Cập nhật mật khẩu đăng nhập',
        ),
        InfoTile(
          icon: Icons.notifications_none,
          title: 'Cài đặt thông báo',
          subtitle: 'Nhắc học, quiz mới, thành tích',
        ),
      ],
    );
  }
}
