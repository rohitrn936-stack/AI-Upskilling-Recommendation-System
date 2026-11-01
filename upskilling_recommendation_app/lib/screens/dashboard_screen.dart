import 'package:flutter/material';
import 'models/student_profile.dart';
import 'models/skill.dart';
import 'models/career.dart';
import 'models/learning_plan_item.dart';
import 'services/mock_service.dart';
import 'theme/app_theme.dart';
import 'widgets/primary_button.dart';
import 'widgets/outline_button.dart';
import 'widgets/empty_state.dart';
import 'widgets/skill_chip.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/snackbar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _mockService = MockService();
  StudentProfile? _profile;
  List<Skill> _currentSkills = [];
  List<Career> _careers = [];
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
      _careers = await _mockService.fetchCareers();

      if (_profile!.activeCareerId != null && _careers.isNotEmpty) {
        final selectedCareer = _careers.firstWhere(
          (c) => c.id == _profile!.activeCareerId,
        );
        final plan = await _mockService.generateLearningPlan(
          selectedCareer: selectedCareer,
          currentSkills: _currentSkills,
        );
        setState(() => _learningPlan = plan);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToCareerSelection() {
    showSnackbar(context, successSnackbar(message: 'Opening career selection...'));
  }

  Widget _buildProgressCard() {
    final completedCount = _currentSkills.length;
    final totalCount = _currentSkills.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFFB84D).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.trending_up, color: Color(0xFFFFB84D), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Skills',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$completedCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Text(
                        '/',
                        style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                      ),
                      Text(
                        totalCount > 0 ? '$totalCount' : '0',
                        style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFFFB84D).withValues(alpha: 0.3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildProgressCard()),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Goal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _profile!.activeCareerId != null
                      ? _buildActiveCareerChip()
                      : const Text(
                          'No active career goal selected',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCareerChip() {
    final selectedCareer = _careers.firstWhere(
      (c) => c.id == _profile!.activeCareerId,
      orElse: () => Career.mock(title: 'Data Analyst'),
    );
    return Row(
      children: [
        Expanded(
          child: Chip(
            label: Text(selectedCareer.title),
            avatar: const Icon(Icons.work, size: 16),
            backgroundColor: Color(0xFFFFB84D).withValues(alpha: 0.1),
            labelStyle: const TextStyle(color: Color(0xFF3B82F6)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () async {
            final updatedProfile = _profile!.copyWith(activeCareerId: null);
            await _mockService.saveProfile(updatedProfile);
            if (mounted) setState(() {});
          },
          tooltip: 'Remove career goal',
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue learning',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                _learningPlan != null && _learningPlan!.isNotEmpty
                    ? _buildNextCourseItem()
                    : const Text(
                        'No active learning plan. "Build a learning plan" to get started.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Build a learning plan',
                  onPressed: _learningPlan == null ? _navigateToCareerSelection : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Check my status',
          onPressed: _checkStatus,
        ),
      ],
    );
  }

  Widget _buildNextCourseItem() {
    final nextItem = _learningPlan!.firstWhere(
      (item) => item.status != 'completed',
      orElse: () => _learningPlan!.first,
    );
    return Row(
      children: [
        Expanded(
          child: SkillChip(
            skill: Skill.mock(
              name: nextItem.skillName,
              proficiencyLevel: nextItem.status == 'completed' ? 'advanced' : null,
            ),
            isSelected: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${nextItem.priority == 'high' ? 'High' : nextItem.priority == 'medium' ? 'Medium' : 'Low'} priority',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${nextItem.recommendedCourses.isNotEmpty ? nextItem.recommendedCourses.first.title : 'No courses'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'Welcome to Upskilling Recommendation',
      subtitle:
          'Complete your profile, choose a career, and get started with learning.',
      icon: Icons.grass,
      hasButton: _profile == null || _profile!.id == 'guest',
      onButtonPressed: _navigateToCareerSelection,
    );
  }

  Widget _checkStatus() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
    showSnackbar(context, infoSnackbar(message: 'Status checked successfully'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    if (_profile == null || _profile!.id == 'guest') {
      return _buildEmptyState();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${_profile!.name}!'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200.0,
          floating: true,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Hello, ${_profile!.name}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Color(0xFF0F172A), Color(0xFF1E293B)]
                      : [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        SliverList.delegate(SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const Spacer(),
              ],
            ),
          ),
          childCount: 1,
        )),
      ]),
    );
  }
}