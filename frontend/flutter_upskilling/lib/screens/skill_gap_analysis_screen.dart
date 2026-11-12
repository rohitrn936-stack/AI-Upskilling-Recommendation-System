import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class SkillGapAnalysisScreen extends StatefulWidget {
  const SkillGapAnalysisScreen({super.key});

  @override
  State<SkillGapAnalysisScreen> createState() => _SkillGapAnalysisScreenState();
}

class _SkillGapAnalysisScreenState extends State<SkillGapAnalysisScreen> {
  bool _isLoading = true;
  bool _isGeneratingRoadmap = false;
  bool _initialized = false;
  String? _error;

  String _targetCareer = 'Software Engineer';
  int _matchPercentage = 0;
  List<String> _studentSkillNames = [];
  List<Map<String, String>> _studentSkillObjects = [];
  List<Map<String, String>> _requiredSkillObjects = [];
  List<String> _existingSkills = [];
  List<String> _requiredSkills = [];
  List<String> _missingSkills = [];
  String _aiInterpretation = '';
  String _interests = '';
  String _academicBackground = '';
  String _learningGoals = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (args != null) {
        if (args['career'] != null) {
          _targetCareer = args['career'].toString();
        }
        if (args['requiredSkills'] is List) {
          _requiredSkills =
              (args['requiredSkills'] as List).map((e) => e.toString()).toList();
        }
      }
      if (_requiredSkills.isEmpty) {
        _requiredSkills = [
          'Python',
          'JavaScript',
          'Data Structures',
          'SQL',
          'Git',
          'System Design'
        ];
      }
      _loadAnalysis();
    }
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        APIClient.getSkills(),
        APIClient.getProfile(),
      ]);

      final rawSkills = results[0] as List<dynamic>;
      final profile =
          (results[1] as Map<String, dynamic>)['data'] as Map<String, dynamic>? ??
              {};

      _studentSkillNames = rawSkills
          .map((s) => (s['skill_name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
      _studentSkillObjects = rawSkills
          .map((s) => {
                'skill_name': (s['skill_name'] ?? '').toString(),
                'proficiency':
                    (s['proficiency_level'] ?? 'Intermediate').toString(),
              })
          .where((m) => m['skill_name']!.isNotEmpty)
          .toList();

      _requiredSkillObjects = _requiredSkills
          .map((r) => {'skill_name': r, 'proficiency_required': 'Intermediate'})
          .toList();

      _interests = (profile['interests'] ?? '').toString();
      _learningGoals = (profile['learning_goals'] ?? '').toString();
      final degree = (profile['degree'] ?? '').toString();
      final year = (profile['academic_year'] ?? '').toString();
      _academicBackground =
          [degree, year].where((e) => e.isNotEmpty).join(', ');

      final response = await APIClient.getSkillGapAnalysis(
        studentSkills: _studentSkillObjects,
        requiredSkills: _requiredSkillObjects,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;
      setState(() {
        _matchPercentage = (data['match_percentage'] as num?)?.toInt() ?? 0;
        _existingSkills = (data['existing_skills'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        _missingSkills = (data['missing_skills'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        _aiInterpretation = (data['ai_interpretation'] ?? '').toString();
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

  Future<void> _generateRoadmap() async {
    setState(() => _isGeneratingRoadmap = true);
    try {
      await APIClient.generateRoadmap(
        studentSkills: _studentSkillObjects,
        careerRequirements: _requiredSkillObjects,
        interests: _interests,
        academicBackground: _academicBackground,
        learningGoals: _learningGoals.isNotEmpty
            ? _learningGoals
            : 'Prepare for $_targetCareer',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Learning roadmap generated!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/learning-roadmap');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingRoadmap = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Skill Gap Analysis',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Re-run Analysis',
            onPressed: _loadAnalysis,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Analyzing skill gaps...')
          : _error != null
              ? ErrorMessage(message: _error!, onRetry: _loadAnalysis)
              : PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Skill Gap: $_targetCareer',
                        subtitle:
                            'Comparison of your saved competencies against target role requirements.',
                      ),
                      const SizedBox(height: 24),
                      _buildMatchPercentageCard(),
                      const SizedBox(height: 20),
                      _buildSkillsComparison(),
                      const SizedBox(height: 20),
                      _buildAiInterpretation(),
                      const SizedBox(height: 24),
                      _buildActionRow(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMatchPercentageCard() {
    final label = _matchPercentage >= 75
        ? 'Strong match'
        : _matchPercentage >= 50
            ? 'Moderate match'
            : 'Needs upskilling';
    final labelColor = _matchPercentage >= 75
        ? AppColors.success
        : _matchPercentage >= 50
            ? AppColors.secondary
            : AppColors.warning;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Role Readiness Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_existingSkills.length} matching • ${_missingSkills.length} to learn',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$_matchPercentage%',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                ),
              ),
              const SizedBox(width: 12),
              StatusPill(label: label, color: labelColor),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _matchPercentage.clamp(0, 100) / 100.0,
              minHeight: 14,
              backgroundColor: AppColors.background,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsComparison() {
    final matched =
        _existingSkills.isNotEmpty ? _existingSkills : _studentSkillNames;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 740;
        final matchedCard = _buildSkillGroupCard(
          title: 'Your Matching Skills',
          icon: Icons.check_circle_outline_rounded,
          skills: matched,
          color: AppColors.success,
          emptyText: 'No matching required skills saved yet.',
        );
        final missingCard = _buildSkillGroupCard(
          title: 'Missing Skills to Learn',
          icon: Icons.lightbulb_outline_rounded,
          skills: _missingSkills,
          color: AppColors.warning,
          emptyText: 'None — you cover all listed skills for this role!',
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: matchedCard),
              const SizedBox(width: 20),
              Expanded(child: missingCard),
            ],
          );
        }

        return Column(
          children: [
            matchedCard,
            const SizedBox(height: 16),
            missingCard,
          ],
        );
      },
    );
  }

  Widget _buildSkillGroupCard({
    required String title,
    required IconData icon,
    required List<String> skills,
    required Color color,
    required String emptyText,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusPill(label: '${skills.length}', color: color),
            ],
          ),
          const SizedBox(height: 14),
          if (skills.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: skills
                  .map((skill) => StatusPill(label: skill, color: color))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAiInterpretation() {
    return AppCard(
      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.45),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Coach Interpretation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _aiInterpretation.isNotEmpty
                      ? _aiInterpretation
                      : 'Focus on building practical projects in your missing skills.',
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: _isGeneratingRoadmap ? null : _generateRoadmap,
          icon: const Icon(Icons.route_rounded, size: 18),
          label: Text(_isGeneratingRoadmap
              ? 'Generating Roadmap...'
              : 'Generate Learning Roadmap'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go(
            '/personalized-skills',
            extra: {
              'targetCareer': _targetCareer,
              'existingSkills': _studentSkillNames,
              'missingSkills': _missingSkills,
              'learningGoals': _learningGoals,
            },
          ),
          icon: const Icon(Icons.tips_and_updates_outlined, size: 18),
          label: const Text('View Skill Suggestions'),
        ),
      ],
    );
  }
}
