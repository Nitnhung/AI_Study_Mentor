import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/services/api_service.dart';
import 'core/services/navigator_key.dart';
import 'features/auth/pages/auth_screen.dart';
import 'features/home/pages/home_screen.dart';

class AiMentorApp extends StatelessWidget {
  const AiMentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Mentor Study',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: FutureBuilder<bool>(
        future: ApiService.loadSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data == true ? const HomeScreen() : const AuthScreen();
        },
      ),
    );
  }
}
