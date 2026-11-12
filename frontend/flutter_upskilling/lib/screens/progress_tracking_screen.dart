import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  bool _isLoading = true;
  String? _error;

  int _completed = 0;
  int _total = 0;
  int _percentage = 0;
  int _roadmapCount = 0;
  List<dynamic> _phases = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await APIClient.getProgress();
      final data = response['data'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;
      setState(() {
        _completed = (data['completed'] as num?)?.toInt() ?? 0;
        _total = (data['total'] as num?)?.toInt() ?? 0;
        _percentage = (data['percentage'] as num?)?.toInt() ?? 0;
        _roadmapCount = (data['roadmap_count'] as num?)?.toInt() ?? 0;
        _phases = data['phases'] as List<dynamic>? ?? [];
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
        title: 'Progress Tracking',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Progress',
            onPressed: _loadProgress,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading your progress...')
          : _error != null
              ? ErrorMessage(message: _error!, onRetry: _loadProgress)
              : PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Progress Tracking',
                        subtitle:
                            'Monitor overall roadmap completion and phase-by-phase task momentum.',
                      ),
                      const SizedBox(height: 24),
                      _buildOverallProgress(),
                      const SizedBox(height: 20),
                      _buildPhaseProgress(),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go('/learning-roadmap'),
                            icon: const Icon(Icons.route_rounded, size: 18),
                            label: const Text('Open Learning Roadmap'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/dashboard'),
                            icon: const Icon(Icons.dashboard_outlined, size: 18),
                            label: const Text('Back to Dashboard'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverallProgress() {
    final completedPct = _percentage.clamp(0, 100).toDouble();
    final remainingPct =
        _total == 0 ? 0.0 : (100 - _percentage).clamp(0, 100).toDouble();
    final remainingTasks = (_total - _completed).clamp(0, _total);

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overall Roadmap Completion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusPill(
                label: '$_roadmapCount roadmap(s)',
                color: AppColors.primary,
                icon: Icons.map_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final rings = Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ProgressRing(
                    percentage: completedPct,
                    label: 'Completed',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 24),
                  _ProgressRing(
                    percentage: remainingPct,
                    label: 'Remaining',
                    color: AppColors.warning,
                  ),
                ],
              );

              final summaryStats = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniStatRow(
                    label: 'Completed Tasks',
                    value: '$_completed',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 10),
                  _MiniStatRow(
                    label: 'Remaining Tasks',
                    value: '$remainingTasks',
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 10),
                  _MiniStatRow(
                    label: 'Total Tracked Tasks',
                    value: '$_total',
                    color: AppColors.primary,
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  children: [
                    rings,
                    const SizedBox(width: 36),
                    Expanded(child: summaryStats),
                  ],
                );
              }

              return Column(
                children: [
                  rings,
                  const SizedBox(height: 20),
                  summaryStats,
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completedPct / 100.0,
              backgroundColor: AppColors.background,
              color:
                  _percentage == 100 ? AppColors.success : AppColors.primary,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _total == 0
                ? 'No roadmap tasks started yet. Generate a roadmap to track progress.'
                : '$_percentage% complete • $_completed of $_total tasks finished',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseProgress() {
    const phasePalette = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.warning,
    ];

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phase Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_phases.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generate a learning roadmap to track per-phase task completion.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/learning-roadmap'),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Go to Learning Roadmap'),
                  ),
                ],
              ),
            )
          else
            ..._phases.asMap().entries.map((entry) {
              final phase = entry.value as Map<String, dynamic>;
              final pct = (phase['percentage'] as num?)?.toInt() ?? 0;
              final done = (phase['completed'] as num?)?.toInt() ?? 0;
              final total = (phase['total'] as num?)?.toInt() ?? 0;
              final color = pct == 100
                  ? AppColors.success
                  : phasePalette[entry.key % phasePalette.length];

              return _PhaseRow(
                index: entry.key + 1,
                phaseName: (phase['phase_name'] ?? 'Phase').toString(),
                completed: done,
                total: total,
                progress: pct.clamp(0, 100),
                color: color,
              );
            }),
        ],
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  final int index;
  final String phaseName;
  final int completed;
  final int total;
  final int progress;
  final Color color;

  const _PhaseRow({
    required this.index,
    required this.phaseName,
    required this.completed,
    required this.total,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phaseName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completed of $total tasks completed',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: '$progress%', color: color),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.surface,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double percentage;
  final String label;
  final Color color;

  const _ProgressRing({
    required this.percentage,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: CircularProgressIndicator(
                  value: (percentage / 100.0).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${percentage.floor()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
