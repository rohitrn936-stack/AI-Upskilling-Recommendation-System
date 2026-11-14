import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/screens/career_details_screen.dart';
import 'package:upskilling/screens/career_recommendations_screen.dart';
import 'package:upskilling/screens/dashboard_screen.dart';
import 'package:upskilling/screens/learning_resources_screen.dart';
import 'package:upskilling/screens/learning_roadmap_screen.dart';
import 'package:upskilling/screens/login_screen.dart';
import 'package:upskilling/screens/onboarding_screen.dart';
import 'package:upskilling/screens/personalized_skill_suggestions_screen.dart';
import 'package:upskilling/screens/progress_tracking_screen.dart';
import 'package:upskilling/screens/registration_screen.dart';
import 'package:upskilling/screens/roadmap_task_details_screen.dart';
import 'package:upskilling/screens/settings_screen.dart';
import 'package:upskilling/screens/skill_gap_analysis_screen.dart';
import 'package:upskilling/screens/skill_management_screen.dart';
import 'package:upskilling/screens/splash_screen.dart';
import 'package:upskilling/screens/student_profile_screen.dart';
import 'package:upskilling/widgets/app_theme.dart';

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
      builder: (context, GoRouterState state) =>
          const CareerRecommendationsScreen(),
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
      builder: (context, GoRouterState state) =>
          const PersonalizedSkillSuggestionsScreen(),
    ),
    GoRoute(
      path: '/learning-roadmap',
      builder: (context, GoRouterState state) => const LearningRoadmapScreen(),
    ),
    GoRoute(
      path: '/roadmap-task-details',
      builder: (context, GoRouterState state) =>
          const RoadmapTaskDetailsScreen(),
    ),
    GoRoute(
      path: '/learning-resources',
      builder: (context, GoRouterState state) =>
          const LearningResourcesScreen(),
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
      debugShowCheckedModeBanner: false,
      title: 'AI Upskilling System',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerDelegate: goRouter.routerDelegate,
      routeInformationProvider: goRouter.routeInformationProvider,
      routeInformationParser: goRouter.routeInformationParser,
      backButtonDispatcher: goRouter.backButtonDispatcher,
    ),
  );
}
