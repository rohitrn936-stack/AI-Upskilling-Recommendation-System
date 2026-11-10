import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/screens/splash_screen.dart';
import 'package:upskilling/screens/onboarding_screen.dart';
import 'package:upskilling/screens/registration_screen.dart';
import 'package:upskilling/screens/login_screen.dart';
import 'package:upskilling/screens/dashboard_screen.dart';
import 'package:upskilling/screens/student_profile_screen.dart';
import 'package:upskilling/screens/skill_management_screen.dart';
import 'package:upskilling/screens/career_recommendations_screen.dart';
import 'package:upskilling/screens/career_details_screen.dart';
import 'package:upskilling/screens/skill_gap_analysis_screen.dart';
import 'package:upskilling/screens/personalized_skill_suggestions_screen.dart';
import 'package:upskilling/screens/learning_roadmap_screen.dart';
import 'package:upskilling/screens/roadmap_task_details_screen.dart';
import 'package:upskilling/screens/learning_resources_screen.dart';
import 'package:upskilling/screens/progress_tracking_screen.dart';
import 'package:upskilling/screens/settings_screen.dart';

import 'widgets/app_bar.dart';

final goRouter = GoRouter(
  routes: [
    // Auth routes
    GoRoute(
      path: '/',
      builder: (context, GoRouterState state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, GoRouterState state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/registration',
      builder: (context, GoRouterState state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, GoRouterState state) => const LoginScreen(),
    ),
    // Main app routes (authenticated)
    GoRoute(
      path: '/dashboard',
      builder: (context, GoRouterState state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, GoRouterState state) => const StudentProfileScreen(),
    ),
    GoRoute(
      path: '/skill-management',
      builder: (context, GoRouterState state) => const SkillManagementScreen(),
    ),
    GoRoute(
      path: '/career-recommendations',
      builder: (context, GoRouterState state) => const CareerRecommendationsScreen(),
    ),
    GoRoute(
      path: '/career-details',
      builder: (context, GoRouterState state) => const CareerDetailsScreen(),
    ),
    GoRoute(
      path: '/skill-gap-analysis',
      builder: (context, GoRouterState state) => const SkillGapAnalysisScreen(),
    ),
    GoRoute(
      path: '/personalized-skills',
      builder: (context, GoRouterState state) => const PersonalizedSkillSuggestionsScreen(),
    ),
    GoRoute(
      path: '/learning-roadmap',
      builder: (context, GoRouterState state) => const LearningRoadmapScreen(),
    ),
    GoRoute(
      path: '/roadmap-task-details',
      builder: (context, GoRouterState state) => const RoadmapTaskDetailsScreen(),
    ),
    GoRoute(
      path: '/learning-resources',
      builder: (context, GoRouterState state) => const LearningResourcesScreen(),
    ),
    GoRoute(
      path: '/progress-tracking',
      builder: (context, GoRouterState state) => const ProgressTrackingScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, GoRouterState state) => const SettingsScreen(),
    ),
  ],
);

void main() {
  runApp(
    MaterialApp.router(
      title: 'Upskilling Recommendation System',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: const MaterialColor(
          0xFF6750A4,
          {
            50: Color(0xFFE8EAF6),
            100: Color(0xFFC5CBE9),
            200: Color(0xFFA3B2D5),
            300: Color(0xFF8099C7),
            400: Color(0xFF5D80B8),
            500: Color(0xFF6750A4),
            600: Color(0xFF5A4399),
            700: Color(0xFF4D368A),
            800: Color(0xFF40297C),
            900: Color(0xFF331C6E),
          },
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF6750A4),
          secondary: Color(0xFF00D1C1),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        primarySwatch: const MaterialColor(
          0xFF6750A4,
          {
            50: Color(0xFF1E2027),
            100: Color(0xFF2D3038),
            200: Color(0xFF3C4048),
            300: Color(0xFF4B5057),
            400: Color(0xFF5A606D),
            500: Color(0xFF6750A4),
            600: Color(0xFF5A4399),
            700: Color(0xFF4D368A),
            800: Color(0xFF40297C),
            900: Color(0xFF331C6E),
          },
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6750A4),
          secondary: Color(0xFF00D1C1),
        ),
      ),
      themeMode: ThemeMode.system,
      routerDelegate: goRouter.routerDelegate,
      routeInformationProvider: goRouter.routeInformationProvider,
      routeInformationParser: goRouter.routeInformationParser,
      backButtonDispatcher: goRouter.backButtonDispatcher,
    ),
  );
}