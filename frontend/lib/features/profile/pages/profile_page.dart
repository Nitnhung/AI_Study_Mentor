import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/info_tile.dart';
import '../../../core/widgets/section_title.dart';
import '../widgets/profile_summary_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true && mounted) setState(() => _profile = res['data'] as Map<String, dynamic>?);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 18), children: [
      const SectionTitle(title: 'Profile'),
      const SizedBox(height: 14),
      ProfileSummaryCard(email: p?['email']?.toString() ?? ApiService.email ?? '', xp: (p?['xpPoints'] as num?)?.toInt() ?? ApiService.xpPoints),
      const SizedBox(height: 18),
      const SectionTitle(title: 'Thông tin cá nhân'),
      const SizedBox(height: 12),
      InfoTile(icon: Icons.mail_outline, title: 'Email', subtitle: p?['email']?.toString() ?? ApiService.email ?? '...'),
      InfoTile(icon: Icons.school_outlined, title: 'Cấp học', subtitle: p?['educationLevel']?.toString() ?? '...'),
      InfoTile(icon: Icons.style_outlined, title: 'Phong cách', subtitle: p?['preferredStyle']?.toString() ?? '...'),
      InfoTile(icon: Icons.star_outline, title: 'XP', subtitle: '${(p?['xpPoints'] as num?)?.toInt() ?? ApiService.xpPoints} điểm'),
    ]);
  }
}
