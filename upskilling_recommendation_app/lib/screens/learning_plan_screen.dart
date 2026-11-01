import 'package:flutter/material';
import 'models/learning_plan_item.dart';
import 'models/course.dart';
import 'services/mock_service.dart';
import 'theme/app_theme.dart';
import 'widgets/primary_button.dart';
import 'widgets/outline_button.dart';
import 'widgets/empty_state.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/snackbar.dart';

class LearningPlanScreen extends StatefulWidget {
  const LearningPlanScreen({super.key});
  @override
  State<LearningPlanScreen> createState() => _LearningPlanScreenState;
}

class _LearningPlanScreenState extends State<LearningPlanScreen> {
  final _mockService = MockService();
  StudentProfile? _profile;
  List<Skill> _currentSkills = [];
  LearningPlanItem? _learningPlan;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _mockService.fetchStudentProfile();
      setState(() => _profile = profile);
      _currentSkills = profile.getCurrentSkills();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    if (_learningPlan == null) {
      return const EmptyState(
        title: 'No learning plan',
        subtitle:
            'Select a career and skills to generate a learning plan.',
        icon: Icons.menu_book,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _buildLearningPlanContent(isDark),
    );
  }

  Widget _buildLearningPlanContent(bool isDark) {
    final careerTitle = _learningPlan!.isNotEmpty
        ? _learningPlan!.first.whyItMatters
            .replaceAll(RegExp(r'This skill is important for building a strong foundation as a'), '')
            .replaceAll(RegExp(r'\.$'), '')
        : 'Your selected career';

    return CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 120.0,
        floating: true,
        pinned: true,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(
            'Learning Plan: $careerTitle',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          background: Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF0F172A) : Color(0xFFFFFFFF),
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
          ),
        ),
      ),
      SliverList.delegate(SliverChildBuilderDelegate(
        (context, index) => _buildPlanItem(_learningPlan![index], isDark),
        childCount: _learningPlan!.length,
      )),
    ]);
  }

  Widget _buildPlanItem(LearningPlanItem item, bool isDark) {
    final isCompleted = item.status == 'completed';
    final isInProgress = item.status == 'in_progress';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.skillName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(item.priority, isDark)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.priority[0].toUpperCase() +
                              item.priority.substring(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(item.priority, isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status, isDark)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(item.status),
                    size: 20,
                    color: _getStatusColor(item.status, isDark),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            Text(
              'Why it matters: ${item.whyItMatters}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Color(0xFF94A3B8) : Color(0xFF64748B),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            if (item.recommendedCourses.isNotEmpty)...[
              const Text(
                'Recommended courses:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              ...item.recommendedCourses.map((course) => _buildCourseCard(course, isDark)),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isCompleted
                        ? null
                        : () async {
                            await _mockService.updateProgress(
                              planItemId: item.id,
                              status: 'planned',
                            );
                            if (mounted) setState(() {});
                            showSnackbar(context, successSnackbar(
                              message: 'Marked as planned',
                            ));
                          },
                    child: Text(isCompleted ? 'Planned' : 'Plan',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isInProgress
                        ? null
                        : () async {
                            await _mockService.updateProgress(
                              planItemId: item.id,
                              status: 'in_progress',
                            );
                            if (mounted) setState(() {});
                            showSnackbar(context, successSnackbar(
                              message: 'Marked as in progress',
                            ));
                          },
                    child: Text(isInProgress ? 'In progress' : 'In progress',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isCompleted
                        ? null
                        : () async {
                            await _mockService.updateProgress(
                              planItemId: item.id,
                              status: 'completed',
                            );
                            if (mounted) setState(() {});
                            showSnackbar(context, successSnackbar(
                              message: 'Marked as completed',
                            ));
                          },
                    child: Text(isCompleted ? 'Completed' : 'Completed',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority, bool isDark) {
    if (priority == 'high') return Color(0xFFFFB84D);
    if (priority == 'medium') return Color(0xFF84CC16);
    return Color(0xFFEF4444);
  }

  Color _getStatusColor(String status, bool isDark) {
    if (status == 'completed') return Color(0xFF10B981);
    if (status == 'in_progress') return Color(0xFF84CC16);
    return Color(0xFF6B7280);
  }

  IconData _getStatusIcon(String status) {
    if (status == 'completed') return Icons.check_circle;
    if (status == 'in_progress') return Icons.play_arrow;
    return Icons.radio;
  }

  Widget _buildCourseCard(Course course, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.provider} • ${course.estimatedDuration} • ${course.level}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Color(0xFF94A3B8) : Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                showSnackbar(context, infoSnackbar(
                  message: 'Opening ${course.title} on ${course.provider}',
                ));
              },
              child: const Text(
                'Open resource',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}