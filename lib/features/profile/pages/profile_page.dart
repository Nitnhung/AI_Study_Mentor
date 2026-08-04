import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/info_tile.dart';
import '../../../core/widgets/section_title.dart';
import '../../auth/pages/auth_screen.dart';
import '../widgets/profile_summary_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _usersUrl = 'http://10.0.2.2:8080/api/users';

  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isVietnamese = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse(_usersUrl));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final users =
          jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _user = users.isEmpty
            ? null
            : Map<String, dynamic>.from(users.first as Map);
        _error = users.isEmpty
            ? 'Chưa có người dùng nào trong hệ thống.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Không thể tải hồ sơ: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    if (_user == null) return;
    final name = TextEditingController(text: _user!['username']?.toString());
    final email = TextEditingController(text: _user!['email']?.toString());
    var level = _user!['educationLevel']?.toString() ?? 'high_school';
    var style = _user!['preferredStyle']?.toString() ?? 'step_by_step';

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chỉnh sửa hồ sơ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                ),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'Cấp học'),
                  items: const [
                    DropdownMenuItem(
                      value: 'middle_school',
                      child: Text('THCS'),
                    ),
                    DropdownMenuItem(value: 'high_school', child: Text('THPT')),
                    DropdownMenuItem(
                      value: 'university',
                      child: Text('Đại học'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => level = value ?? level),
                ),
                DropdownButtonFormField<String>(
                  initialValue: style,
                  decoration: const InputDecoration(
                    labelText: 'Phong cách giải thích',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'short', child: Text('Ngắn gọn')),
                    DropdownMenuItem(
                      value: 'detailed',
                      child: Text('Chi tiết'),
                    ),
                    DropdownMenuItem(
                      value: 'step_by_step',
                      child: Text('Từng bước'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => style = value ?? style),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true ||
        name.text.trim().isEmpty ||
        email.text.trim().isEmpty) {
      return;
    }
    await _updateProfile({
      ..._user!,
      'username': name.text.trim(),
      'email': email.text.trim(),
      'educationLevel': level,
      'preferredStyle': style,
    });
  }

  Future<void> _updateProfile(Map<String, dynamic> payload) async {
    final id = _user?['userId']?.toString();
    if (id == null) return;
    setState(() => _isSaving = true);
    try {
      final response = await http.put(
        Uri.parse('$_usersUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      if (!mounted) return;
      setState(
        () => _user = Map<String, dynamic>.from(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map,
        ),
      );
      _showMessage('Đã cập nhật hồ sơ.');
    } catch (error) {
      if (mounted) _showMessage('Cập nhật thất bại: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_user == null) return;
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
    if (submit != true) return;
    if (next.text.length < 6 || next.text != confirm.text) {
      _showMessage(
        'Mật khẩu mới phải có ít nhất 6 ký tự và khớp nhau.',
        isError: true,
      );
      return;
    }
    final id = _user!['userId'].toString();
    setState(() => _isSaving = true);
    try {
      final response = await http.put(
        Uri.parse('$_usersUrl/$id/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': current.text,
          'newPassword': next.text,
        }),
      );
      if (response.statusCode != 204) {
        final message = utf8.decode(response.bodyBytes);
        throw Exception(
          message.isEmpty ? 'HTTP ${response.statusCode}' : message,
        );
      }
      if (mounted) _showMessage('Đổi mật khẩu thành công.');
    } catch (error) {
      if (mounted) _showMessage('Đổi mật khẩu thất bại: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ quay lại màn hình đăng nhập.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  String _levelLabel(String? value) => switch (value) {
    'middle_school' => 'THCS',
    'university' => 'Đại học',
    _ => 'THPT',
  };

  String _styleLabel(String? value) => switch (value) {
    'short' => 'Ngắn gọn',
    'detailed' => 'Chi tiết',
    _ => 'Từng bước',
  };

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user!;
    final name = user['username']?.toString() ?? 'Người dùng';
    final email = user['email']?.toString() ?? '';
    final xp = int.tryParse(user['xpPoints']?.toString() ?? '') ?? 0;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchProfile,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: [
              const SectionTitle(title: 'Hồ sơ'),
              const SizedBox(height: 14),
              ProfileSummaryCard(
                name: name,
                email: email,
                xpPoints: xp,
                onEdit: _editProfile,
              ),
              const SizedBox(height: 18),
              const SectionTitle(title: 'Thông tin cá nhân'),
              const SizedBox(height: 12),
              InfoTile(
                icon: Icons.person_outline,
                title: 'Họ và tên',
                subtitle: name,
                onTap: _editProfile,
              ),
              InfoTile(
                icon: Icons.mail_outline,
                title: 'Email',
                subtitle: email,
                onTap: _editProfile,
              ),
              InfoTile(
                icon: Icons.school_outlined,
                title: 'Cấp học',
                subtitle: _levelLabel(user['educationLevel']?.toString()),
                onTap: _editProfile,
              ),
              InfoTile(
                icon: Icons.psychology_outlined,
                title: 'Phong cách giải thích',
                subtitle: _styleLabel(user['preferredStyle']?.toString()),
                onTap: _editProfile,
              ),
              const SizedBox(height: 8),
              InfoTile(
                icon: Icons.language,
                title: 'Ngôn ngữ',
                subtitle: _isVietnamese ? 'Tiếng Việt' : 'English',
                onTap: () => setState(() => _isVietnamese = !_isVietnamese),
              ),
              InfoTile(
                icon: Icons.lock_reset,
                title: 'Đổi mật khẩu',
                subtitle: 'Cập nhật mật khẩu đăng nhập',
                onTap: _changePassword,
              ),
              InfoTile(
                icon: Icons.logout,
                title: 'Đăng xuất',
                subtitle: 'Thoát khỏi ứng dụng',
                onTap: _logout,
              ),
            ],
          ),
        ),
        if (_isSaving)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
