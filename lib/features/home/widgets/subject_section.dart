import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../quiz/pages/quiz_play_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../models/subject_model.dart';

class SubjectSection extends StatefulWidget {
  const SubjectSection({super.key});

  @override
  State<SubjectSection> createState() => _SubjectSectionState();
}

class _SubjectSectionState extends State<SubjectSection> {
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/subjects'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _subjects = data.map((s) => Subject.fromJson(s)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_subjects.isEmpty) {
      // Fallback nếu database chưa có data
      final defaultNames = ['Toán', 'Tiếng Anh', 'Lý', 'Hóa', 'CNTT'];
      return _buildWrap(defaultNames.map((name) => Subject(id: '0', name: name)).toList());
    }

    return _buildWrap(_subjects);
  }

  Widget _buildWrap(List<Subject> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (subject) => InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizPlayScreen(topic: subject.name),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: const BoxConstraints(minWidth: 72, minHeight: 58),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: Text(
                  subject.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
