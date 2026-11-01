import 'package:flutter/material';
import 'package:upskilling_recommendation_app/screens/welcome_screen.dart';
import 'package:upskilling_recommendation_app/screens/dashboard_screen.dart';
import 'package:upskilling_recommendation_app/screens/career_skill_selection_screen.dart';
import 'package:upskilling_recommendation_app/screens/learning_plan_screen.dart';
import 'package:upskilling_recommendation_app/screens/profile_screen.dart';
import 'package:upskilling_recommendation_app/screens/settings_screen.dart';

void main() {
  runApp(const UpskillingApp());
}

class UpskillingApp extends StatelessWidget {
  const UpskillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upskilling Recommendation',
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      themeMode: ThemeMode.system,
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/career-skill-selection': (context) =>
            const CareerSkillSelectionScreen(),
        '/learning-plan': (context) => const LearningPlanScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}