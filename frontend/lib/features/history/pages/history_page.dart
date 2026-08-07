import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.getHistory();
      if (mounted) setState(() { _items = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = 'Không tải được lịch sử'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Lịch sử câu hỏi'), backgroundColor: Colors.white, foregroundColor: AppColors.text),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: Text(_error!))
        : _items.isEmpty ? const Center(child: Text('Chưa có câu hỏi nào'))
        : ListView.builder(padding: const EdgeInsets.all(18), itemCount: _items.length,
            itemBuilder: (ctx, i) {
              final q = _items[i] as Map<String, dynamic>? ?? {};
              return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.softBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(q['questionText']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  if ((q['directAnswer']?.toString() ?? '').isNotEmpty)
                    Text(q['directAnswer'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    if ((q['subject']?.toString() ?? '').isNotEmpty)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.softPrimary, borderRadius: BorderRadius.circular(12)),
                        child: Text(q['subject'].toString(), style: const TextStyle(fontSize: 11, color: AppColors.primary))),
                    const Spacer(),
                    Text(q['status']?.toString() ?? '', style: TextStyle(fontSize: 11,
                      color: q['status'] == 'Resolved' ? Colors.green : AppColors.muted)),
                  ]),
                ]));
            }));
  }
}
