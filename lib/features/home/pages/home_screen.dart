import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../notifications/pages/notifications_page.dart';
import '../../profile/pages/profile_details_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../quiz/pages/quiz_page.dart';
import '../widgets/home_drawer.dart';
import '../widgets/home_page_content.dart';
import 'ask_ai_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const HomeDrawer(),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            HomePageContent(),
            AskAiPage(),
            QuizPage(),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.softPrimary,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Ask AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (context) {
            return IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: AppColors.text),
            );
          },
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
          icon: const Icon(Icons.notifications_none, color: AppColors.text),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileDetailsPage()),
            );
          },
          icon: const Icon(
            Icons.account_circle_outlined,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
