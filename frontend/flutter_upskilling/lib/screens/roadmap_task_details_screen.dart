import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class RoadmapTaskDetailsScreen extends StatefulWidget {
  const RoadmapTaskDetailsScreen({super.key});

  @override
  State<RoadmapTaskDetailsScreen> createState() =>
      _RoadmapTaskDetailsScreenState();
}

class _RoadmapTaskDetailsScreenState extends State<RoadmapTaskDetailsScreen> {
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _initialized = false;
  String? _error;

  int? _taskId;
  String _taskName = '';
  String _phaseName = '';
  String _skillFocus = '';
  String _estimatedDuration = '';
  String _taskDescription = '';
  String _completionCriteria = '';
  String _status = 'not_started';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (args != null && args['task'] is Map) {
        final task = args['task'] as Map<String, dynamic>;
        _applyTaskData(
          task: task,
          phaseName: (args['phaseName'] ?? 'Learning Phase').toString(),
        );
        _isLoading = false;
      } else {
        _loadLatestRoadmapTask();
      }
    }
  }

  void _applyTaskData({
    required Map<String, dynamic> task,
    required String phaseName,
  }) {
    _taskId = (task['id'] as num?)?.toInt();
    _taskName = (task['task_name'] ?? 'Learning Task').toString();
    _phaseName = phaseName;
    _skillFocus = (task['skill_focus'] ?? '').toString();
    _estimatedDuration =
        (task['estimated_duration'] ?? '1-2 weeks').toString();
    _taskDescription = (task['task_description'] ?? '').toString();
    _completionCriteria = (task['completion_criteria'] ?? '').toString();
    _status = (task['status'] ?? 'not_started').toString();
  }

  Future<void> _loadLatestRoadmapTask() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await APIClient.getRoadmap();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final roadmap = data['roadmap'] as Map<String, dynamic>?;
      final phases = roadmap?['phases'] as List<dynamic>? ?? [];

      Map<String, dynamic>? chosenTask;
      var chosenPhase = 'Learning Phase';
      for (final phase in phases) {
        final phaseName = (phase['phase_name'] ?? 'Learning Phase').toString();
        final tasks = phase['tasks'] as List<dynamic>? ?? [];
        for (final t in tasks) {
          if (t is Map<String, dynamic>) {
            if (chosenTask == null) {
              chosenTask = t;
              chosenPhase = phaseName;
            }
            if (t['status'] != 'completed') {
              chosenTask = t;
              chosenPhase = phaseName;
              break;
            }
          }
        }
        if (chosenTask != null && chosenTask['status'] != 'completed') {
          break;
        }
      }

      if (!mounted) return;
      if (chosenTask != null) {
        setState(() {
          _applyTaskData(task: chosenTask!, phaseName: chosenPhase);
        });
      }
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

  Future<void> _updateStatus(String newStatus) async {
    if (_taskId == null) return;
    setState(() => _isUpdating = true);
    try {
      await APIClient.updateTaskProgress(
        taskId: _taskId.toString(),
        status: newStatus,
      );
      if (!mounted) return;
      setState(() => _status = newStatus);
      final label = newStatus == 'completed'
          ? 'completed'
          : newStatus == 'in_progress'
              ? 'in progress'
              : 'not started';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task marked as $label'),
          backgroundColor: AppColors.primary,
        ),
      );
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
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Task Details',
        onLeading: () => context.go('/learning-roadmap'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading task details...')
          : _error != null
              ? ErrorMessage(
                  message: _error!, onRetry: _loadLatestRoadmapTask)
              : _taskId == null
                  ? _buildEmptyState()
                  : PageContainer(
                      maxWidth: 880,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 22),
                          _buildTaskProgressCard(),
                          const SizedBox(height: 20),
                          _buildTaskDetailsCard(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeader() {
    final statusColor = _status == 'completed'
        ? AppColors.success
        : _status == 'in_progress'
            ? AppColors.warning
            : AppColors.textMuted;
    final statusLabel = _status == 'completed'
        ? 'Completed'
        : _status == 'in_progress'
            ? 'In Progress'
            : 'Not Started';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(
              label: _phaseName,
              color: AppColors.primary,
              icon: Icons.layers_outlined,
            ),
            StatusPill(
              label: statusLabel,
              color: statusColor,
              icon: _status == 'completed'
                  ? Icons.check_circle_outline_rounded
                  : _status == 'in_progress'
                      ? Icons.timelapse_rounded
                      : Icons.radio_button_unchecked_rounded,
            ),
            if (_skillFocus.isNotEmpty)
              StatusPill(
                label: _skillFocus,
                color: AppColors.secondary,
                icon: Icons.code_rounded,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _taskName,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return PageContainer(
      maxWidth: 640,
      child: AppCard(
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
                Icons.task_alt_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Roadmap Tasks Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate a learning roadmap first to view and track individual learning tasks.',
              style: TextStyle(
                fontSize: 14.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/learning-roadmap'),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Go to Learning Roadmap'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskProgressCard() {
    final progressValue = _status == 'completed'
        ? 1.0
        : _status == 'in_progress'
            ? 0.5
            : 0.0;
    final pctText = _status == 'completed'
        ? '100%'
        : _status == 'in_progress'
            ? '50%'
            : '0%';
    final statusDescription = _status == 'completed'
        ? 'Great work! This task is completed and counted toward your roadmap progress.'
        : _status == 'in_progress'
            ? 'Currently in progress. Review the criteria below and mark completed when ready.'
            : 'Ready to begin. Mark this task In Progress once you start working on it.';
    final progressColor = _status == 'completed'
        ? AppColors.success
        : _status == 'in_progress'
            ? AppColors.warning
            : AppColors.primary;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progress Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                pctText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: AppColors.background,
              color: progressColor,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statusDescription,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDetailsCard() {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Breakdown',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.layers_outlined,
            label: 'Roadmap Phase',
            value: _phaseName,
          ),
          if (_skillFocus.isNotEmpty)
            _buildInfoRow(
              icon: Icons.code_rounded,
              label: 'Skill Focus',
              value: _skillFocus,
            ),
          _buildInfoRow(
            icon: Icons.schedule_rounded,
            label: 'Estimated Duration',
            value: _estimatedDuration.isNotEmpty
                ? _estimatedDuration
                : 'Flexible',
          ),
          if (_taskDescription.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCalloutBox(
              title: 'Learning Objectives',
              content: _taskDescription,
              icon: Icons.menu_book_rounded,
              color: AppColors.primary,
            ),
          ],
          if (_completionCriteria.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCalloutBox(
              title: 'Completion Criteria',
              content: _completionCriteria,
              icon: Icons.verified_outlined,
              color: AppColors.secondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.7),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalloutBox({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final focusTopic = _skillFocus.isNotEmpty ? _skillFocus : _taskName;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (_status != 'completed')
          ElevatedButton.icon(
            onPressed:
                _isUpdating ? null : () => _updateStatus('completed'),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(_isUpdating ? 'Updating...' : 'Mark as Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        if (_status != 'in_progress')
          OutlinedButton.icon(
            onPressed:
                _isUpdating ? null : () => _updateStatus('in_progress'),
            icon: const Icon(Icons.timelapse_rounded, size: 18),
            label: const Text('Mark In Progress'),
          ),
        if (_status == 'completed')
          OutlinedButton.icon(
            onPressed:
                _isUpdating ? null : () => _updateStatus('not_started'),
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Reset to Not Started'),
          ),
        OutlinedButton.icon(
          onPressed: () => context.go(
            '/learning-resources',
            extra: {
              'skillFocus': focusTopic,
              'taskDescription': _taskDescription.isNotEmpty
                  ? _taskDescription
                  : 'Resources to master $focusTopic',
            },
          ),
          icon: const Icon(Icons.menu_book_rounded, size: 18),
          label: const Text('Find Resources'),
        ),
        TextButton.icon(
          onPressed: () => context.go('/learning-roadmap'),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to Roadmap'),
        ),
      ],
    );
  }
}
