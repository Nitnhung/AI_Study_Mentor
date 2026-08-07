import 'package:flutter/material.dart';

import '../../../core/widgets/section_title.dart';
import '../widgets/ask_ai_panel.dart';

class AskAiPage extends StatelessWidget {
  const AskAiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: const [
        SectionTitle(title: 'Ask AI'),
        SizedBox(height: 14),
        AskAiPanel(),
      ],
    );
  }
}
