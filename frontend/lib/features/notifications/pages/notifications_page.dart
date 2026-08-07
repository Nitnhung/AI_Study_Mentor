import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/info_tile.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.getNotifications();
      if (mounted) setState(() { _items = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Thông báo'), backgroundColor: Colors.white, foregroundColor: AppColors.text),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty ? const Center(child: Text('Không có thông báo'))
        : ListView(padding: const EdgeInsets.all(18), children:
            _items.map((n) {
              final item = n as Map<String, dynamic>? ?? {};
              return InfoTile(icon: Icons.notifications_none,
                title: item['message']?.toString() ?? '', subtitle: item['type']?.toString() ?? '');
            }).toList()));
  }
}
