import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class LearningRoadmapScreen extends StatefulWidget {
  const LearningRoadmapScreen({super.key});

  @override
  State<LearningRoadmapScreen> createState() => _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends State<LearningRoadmapScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;
  Map<String, dynamic>? _roadmap;
  List<dynamic> _phases = [];

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  Future<void> _loadRoadmap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await APIClient.getRoadmap();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final roadmap = data['roadmap'] as Map<String, dynamic>?;
      final phases = roadmap?['phases'] as List<dynamic>? ?? [];

      if (!mounted) return;
      setState(() {
        _roadmap = roadmap;
        _phases = phases;
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

  Future<void> _generateNewRoadmap() async {
    setState(() => _isGenerating = true);
    try {
      final results = await Future.wait([
        APIClient.getSkills(),
        APIClient.getProfile(),
      ]);
      final rawSkills = results[0] as List<dynamic>;
      final profile =
          (results[1] as Map<String, dynamic>)['data'] as Map<String, dynamic>? ??
              {};

      final studentSkills = rawSkills
          .map((s) => {
                'skill_name': (s['skill_name'] ?? '').toString(),
                'proficiency':
                    (s['proficiency_level'] ?? 'Intermediate').toString(),
              })
          .where((m) => m['skill_name']!.isNotEmpty)
          .toList();

      final degree = (profile['degree'] ?? '').toString();
      final year = (profile['academic_year'] ?? '').toString();
      final academicBg = [degree, year].where((e) => e.isNotEmpty).join(', ');
      final interests = (profile['interests'] ?? '').toString();
      final goals = (profile['learning_goals'] ?? '').toString();

      await APIClient.generateRoadmap(
        studentSkills: studentSkills,
        careerRequirements: const [
          {'skill_name': 'Python', 'proficiency_required': 'Intermediate'},
          {
            'skill_name': 'Data Structures',
            'proficiency_required': 'Intermediate'
          },
          {'skill_name': 'SQL', 'proficiency_required': 'Intermediate'},
          {
            'skill_name': 'System Design',
            'proficiency_required': 'Intermediate'
          },
          {'skill_name': 'Docker', 'proficiency_required': 'Beginner'},
        ],
        interests: interests,
        academicBackground: academicBg,
        learningGoals:
            goals.isNotEmpty ? goals : 'Build job-ready technical skills',
      );

      await _loadRoadmap();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New learning roadmap generated!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('unauthorized')) {
        if (mounted) context.go('/login');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Map<String, dynamic>? _findFirstActionableTask() {
    Map<String, dynamic>? firstTask;
    for (final phase in _phases) {
      final phaseName = (phase['phase_name'] ?? 'Roadmap Phase').toString();
      final tasks = phase['tasks'] as List<dynamic>? ?? [];
      for (final task in tasks) {
        if (task is Map<String, dynamic>) {
          firstTask ??= {'task': task, 'phaseName': phaseName};
          if (task['status'] != 'completed') {
            return {'task': task, 'phaseName': phaseName};
          }
        }
      }
    }
    return firstTask;
  }

  (int completed, int total) _computeOverallStats() {
    var total = 0;
    var completed = 0;
    for (final phase in _phases) {
      final tasks = phase['tasks'] as List<dynamic>? ?? [];
      total += tasks.length;
      completed +=
          tasks.where((t) => t is Map && t['status'] == 'completed').length;
    }
    return (completed, total);
  }

  @override
  Widget build(BuildContext context) {
    final nextTask = _findFirstActionableTask();

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Learning Roadmap',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Roadmap',
            onPressed: _loadRoadmap,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading your learning roadmap...')
          : _error != null
              ? ErrorMessage(message: _error!, onRetry: _loadRoadmap)
              : PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_roadmap == null || _phases.isEmpty) ...[
                        const SectionHeader(
                          title: 'Learning Roadmap',
                          subtitle:
                              'Build a structured, phase-by-phase plan tailored to your target role.',
                        ),
                        const SizedBox(height: 24),
                        _buildEmptyState(),
                      ] else ...[
                        _buildOverviewHeader(nextTask),
                        const SizedBox(height: 24),
                        ..._phases.asMap().entries.map((entry) {
                          final index = entry.key;
                          final phase = entry.value as Map<String, dynamic>;
                          return _buildPhaseCard(phase, index);
                        }),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewHeader(Map<String, dynamic>? nextTask) {
    final title = (_roadmap?['title'] ?? 'Your Learning Roadmap').toString();
    final description = (_roadmap?['description'] ?? '').toString();
    final stats = _computeOverallStats();
    final completed = stats.$1;
    final total = stats.$2;
    final pct = total > 0 ? ((completed / total) * 100).round() : 0;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusPill(
                label: '$pct% Complete',
                color: pct == 100 ? AppColors.success : AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    minHeight: 10,
                    backgroundColor: AppColors.background,
                    color: pct == 100 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$completed / $total tasks done',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (nextTask != null)
                ElevatedButton.icon(
                  onPressed: () => context.go(
                    '/roadmap-task-details',
                    extra: nextTask,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Open Next Task'),
                ),
              OutlinedButton.icon(
                onPressed: _isGenerating ? null : _generateNewRoadmap,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(_isGenerating
                    ? 'Generating...'
                    : 'Generate New Roadmap'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/progress-tracking'),
                icon: const Icon(Icons.bar_chart_rounded, size: 18),
                label: const Text('View Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.map_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Learning Roadmap Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate a personalized phase-by-phase roadmap based on your current skills and target career.',
            style: TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateNewRoadmap,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                    _isGenerating ? 'Generating...' : 'Generate Roadmap Now'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/career-recommendations'),
                icon: const Icon(Icons.work_outline_rounded, size: 18),
                label: const Text('Explore Careers First'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(Map<String, dynamic> phase, int index) {
    final phaseName =
        (phase['phase_name'] ?? 'Phase ${index + 1}').toString();
    final phaseOrder = (phase['phase_order'] as num?)?.toInt() ?? (index + 1);
    final description = (phase['description'] ?? '').toString();
    final duration = (phase['estimated_duration'] ?? '').toString();
    final tasks = phase['tasks'] as List<dynamic>? ?? [];
    final completedCount =
        tasks.where((t) => t is Map && t['status'] == 'completed').length;
    final allDone = tasks.isNotEmpty && completedCount == tasks.length;
    final accentColor = allDone ? AppColors.success : AppColors.primary;
    final phaseProgress =
        tasks.isNotEmpty ? completedCount / tasks.length : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AppCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: allDone
                      ? Icon(Icons.check_rounded, color: accentColor, size: 22)
                      : Text(
                          '$phaseOrder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phaseName,
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    if (duration.isNotEmpty)
                      StatusPill(
                        label: duration,
                        color: AppColors.secondary,
                        icon: Icons.schedule_rounded,
                      ),
                    StatusPill(
                      label: '$completedCount/${tasks.length} done',
                      color: accentColor,
                    ),
                  ],
                ),
              ],
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: phaseProgress,
                  minHeight: 6,
                  backgroundColor: AppColors.background,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 16),
              ...tasks.map((rawTask) {
                final task = rawTask as Map<String, dynamic>;
                final status = (task['status'] ?? 'not_started').toString();
                final isCompleted = status == 'completed';
                final isInProgress = status == 'in_progress';
                final statusColor = isCompleted
                    ? AppColors.success
                    : isInProgress
                        ? AppColors.warning
                        : AppColors.textMuted;
                final statusIcon = isCompleted
                    ? Icons.check_circle_rounded
                    : isInProgress
                        ? Icons.timelapse_rounded
                        : Icons.radio_button_unchecked_rounded;
                final statusLabel = isCompleted
                    ? 'Completed'
                    : isInProgress
                        ? 'In Progress'
                        : 'Not Started';

                final focus = (task['skill_focus'] ?? '').toString();
                final taskDuration =
                    (task['estimated_duration'] ?? '').toString();
                final metaParts = [
                  if (focus.isNotEmpty) 'Focus: $focus',
                  if (taskDuration.isNotEmpty) taskDuration,
                ];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isCompleted
                        ? AppColors.success.withValues(alpha: 0.04)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => context.go(
                        '/roadmap-task-details',
                        extra: {'task': task, 'phaseName': phaseName},
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.success.withValues(alpha: 0.25)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (task['task_name'] ?? 'Task').toString(),
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (metaParts.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      metaParts.join(' • '),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            StatusPill(
                              label: statusLabel,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
