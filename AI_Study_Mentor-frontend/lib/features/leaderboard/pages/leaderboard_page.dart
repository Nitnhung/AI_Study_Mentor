import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.getLeaderboard();
      if (mounted) setState(() { _items = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Bảng xếp hạng'), backgroundColor: Colors.white, foregroundColor: AppColors.text),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty ? const Center(child: Text('Chưa có dữ liệu'))
        : ListView.builder(padding: const EdgeInsets.all(18), itemCount: _items.length,
            itemBuilder: (ctx, i) {
              final item = _items[i] as Map<String, dynamic>? ?? {};
              return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: i == 0 ? Colors.amber : AppColors.softBorder)),
                child: Row(children: [
                  Container(width: 36, height: 36, alignment: Alignment.center,
                    decoration: BoxDecoration(color: i == 0 ? Colors.amber : AppColors.softPrimary, borderRadius: BorderRadius.circular(18)),
                    child: Text('#${item['ranking'] ?? i + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: i == 0 ? Colors.white : AppColors.primary))),
                  const SizedBox(width: 14),
                  Expanded(child: Text(item['userId']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text('${item['totalXpPoints'] ?? 0} XP', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                ]));
            }));
  }
}
