import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'features/auth/pages/auth_screen.dart';

class AiMentorApp extends StatelessWidget {
  const AiMentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Mentor Study',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthScreen(),
    );
  }
}
