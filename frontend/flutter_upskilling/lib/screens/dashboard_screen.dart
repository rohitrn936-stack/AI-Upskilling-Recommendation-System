import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  String _studentName = 'Student';
  int _skillsCount = 0;
  int _roadmapsCount = 0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  int _progressPercentage = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        APIClient.getProfile(),
        APIClient.getSkills(),
        APIClient.getProgress(),
      ]);

      final profileData =
          (results[0] as Map<String, dynamic>)['data'] as Map<String, dynamic>? ??
              {};
      final skills = results[1] as List<dynamic>;
      final progressData =
          (results[2] as Map<String, dynamic>)['data'] as Map<String, dynamic>? ??
              {};

      if (!mounted) return;
      setState(() {
        _studentName = (profileData['name'] ?? 'Student').toString();
        _skillsCount = skills.length;
        _roadmapsCount = (progressData['roadmap_count'] as num?)?.toInt() ?? 0;
        _completedTasks = (progressData['completed'] as num?)?.toInt() ?? 0;
        _totalTasks = (progressData['total'] as num?)?.toInt() ?? 0;
        _progressPercentage = (progressData['percentage'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('unauthorized')) {
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() => _error = msg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'AI Upskilling',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Dashboard',
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading your dashboard...')
          : _error != null
              ? ErrorMessage(message: _error!, onRetry: _loadDashboard)
              : PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBanner(),
                      const SizedBox(height: 24),
                      _buildStatsGrid(),
                      const SizedBox(height: 28),
                      const SectionHeader(
                        title: 'Explore & Upskill',
                        subtitle:
                            'Pick a workflow below to manage skills, compare career paths, or continue your roadmap.',
                      ),
                      const SizedBox(height: 16),
                      _buildActionGrid(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          final greeting = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'STUDENT WORKSPACE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome back, $_studentName!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _totalTasks > 0
                    ? 'You have completed $_completedTasks of $_totalTasks roadmap tasks ($_progressPercentage%). Keep going!'
                    : 'Start by adding your skills, then discover matched career recommendations.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.45,
                ),
              ),
            ],
          );

          final cta = ElevatedButton.icon(
            onPressed: () => context.go(
              _roadmapsCount > 0
                  ? '/learning-roadmap'
                  : '/career-recommendations',
            ),
            icon: Icon(
              _roadmapsCount > 0
                  ? Icons.play_arrow_rounded
                  : Icons.explore_rounded,
            ),
            label: Text(
              _roadmapsCount > 0 ? 'Continue Roadmap' : 'Explore Careers',
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: greeting),
                const SizedBox(width: 24),
                cta,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              greeting,
              const SizedBox(height: 18),
              cta,
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 860 ? 4 : (width >= 480 ? 2 : 1);
        final cardWidth = (width - (16 * (columns - 1))) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                label: 'Saved Skills',
                value: '$_skillsCount',
                subtitle: 'Tracked in your inventory',
                icon: Icons.code_rounded,
                color: AppColors.primary,
                onTap: () => context.go('/skill-management'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                label: 'Learning Roadmaps',
                value: '$_roadmapsCount',
                subtitle: 'Generated career plans',
                icon: Icons.map_rounded,
                color: AppColors.secondary,
                onTap: () => context.go('/learning-roadmap'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                label: 'Tasks Completed',
                value: '$_completedTasks / $_totalTasks',
                subtitle: 'Across active roadmap',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
                onTap: () => context.go('/progress-tracking'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                label: 'Overall Progress',
                value: '$_progressPercentage%',
                subtitle: 'Roadmap completion',
                icon: Icons.trending_up_rounded,
                color: AppColors.info,
                progress: _progressPercentage / 100.0,
                onTap: () => context.go('/progress-tracking'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      (
        'Manage Skills',
        'Add technical skills, set proficiency levels, and organize categories.',
        Icons.code_rounded,
        AppColors.primary,
        '/skill-management',
      ),
      (
        'Career Recommendations',
        'Discover roles matched to your current skills and career interests.',
        Icons.work_outline_rounded,
        AppColors.secondary,
        '/career-recommendations',
      ),
      (
        'Skill Gap Analysis',
        'Measure role readiness and identify high-impact missing skills.',
        Icons.analytics_outlined,
        AppColors.warning,
        '/skill-gap-analysis',
      ),
      (
        'Learning Roadmap',
        'Follow structured phases and update task status as you learn.',
        Icons.route_rounded,
        AppColors.info,
        '/learning-roadmap',
      ),
      (
        'Learning Resources',
        'Find courses, guides, videos, and books tailored to any skill.',
        Icons.menu_book_rounded,
        AppColors.success,
        '/learning-resources',
      ),
      (
        'Progress Tracking',
        'Monitor completion metrics and phase-by-phase momentum.',
        Icons.bar_chart_rounded,
        AppColors.primaryDark,
        '/progress-tracking',
      ),
      (
        'My Profile',
        'Update institution, degree, interests, and learning goals.',
        Icons.person_outline_rounded,
        AppColors.secondary,
        '/profile',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900 ? 3 : (width >= 560 ? 2 : 1);
        final cardWidth = (width - (16 * (columns - 1))) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: actions.map((item) {
            return SizedBox(
              width: cardWidth,
              child: _ActionTileCard(
                title: item.$1,
                description: item.$2,
                icon: item.$3,
                color: item.$4,
                onTap: () => context.go(item.$5),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? progress;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionTileCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTileCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
