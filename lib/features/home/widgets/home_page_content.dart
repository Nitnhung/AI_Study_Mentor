import 'package:flutter/material.dart';

import '../../../core/widgets/section_title.dart';
import '../pages/home_screen.dart';
import 'ask_ai_panel.dart';
import 'continue_learning_section.dart';
import 'recent_activity_section.dart';
import 'subject_section.dart';
import 'welcome_panel.dart';

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      children: const [
        HomeHeader(),
        SizedBox(height: 16),
        WelcomePanel(),
        SizedBox(height: 18),
        AskAiPanel(),
        SizedBox(height: 24),
        SectionTitle(title: 'Môn học phổ biến'),
        SizedBox(height: 12),
        SubjectSection(),
        SizedBox(height: 24),
        SectionTitle(title: 'Tiếp tục học'),
        SizedBox(height: 12),
        ContinueLearningSection(),
        SizedBox(height: 24),
        SectionTitle(title: 'Hoạt động gần đây'),
        SizedBox(height: 12),
        RecentActivitySection(),
      ],
    );
  }
}
