import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class CareerRecommendationsScreen extends StatefulWidget {
  const CareerRecommendationsScreen({super.key});

  @override
  State<CareerRecommendationsScreen> createState() =>
      _CareerRecommendationsScreenState();
}

class _CareerRecommendationsScreenState
    extends State<CareerRecommendationsScreen> {
  bool _isLoading = true;
  String? _error;
  bool _demoMode = false;
  List<dynamic> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        APIClient.getSkills(),
        APIClient.getProfile(),
      ]);
      final skillsRaw = results[0] as List<dynamic>;
      final profileData =
          (results[1] as Map<String, dynamic>)['data'] as Map<String, dynamic>? ??
              {};

      final skillNames = <String>[];
      final proficiencyMap = <String, String>{};
      for (final s in skillsRaw) {
        final name = (s['skill_name'] ?? '').toString();
        if (name.isNotEmpty) {
          skillNames.add(name);
          proficiencyMap[name] =
              (s['proficiency_level'] ?? 'Intermediate').toString();
        }
      }

      final degree = (profileData['degree'] ?? '').toString();
      final year = (profileData['academic_year'] ?? '').toString();
      final academicBg = [degree, year].where((e) => e.isNotEmpty).join(', ');
      final interests = (profileData['interests'] ?? '').toString();

      final response = await APIClient.getCareerRecommendations(
        skills: skillNames,
        proficiency: proficiencyMap,
        interests: interests,
        academicBackground: academicBg,
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final recs =
          (data['recommendations'] ?? data['careers'] ?? []) as List<dynamic>;

      if (!mounted) return;
      setState(() {
        _demoMode = data['demo_mode'] == true;
        _recommendations = recs;
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
        title: 'Career Recommendations',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Recommendations',
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Matching roles to your skills...')
          : _error != null
              ? ErrorMessage(message: _error!, onRetry: _loadRecommendations)
              : PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Recommended Career Paths',
                        subtitle:
                            'Select any role to inspect required competencies and run a skill gap analysis.',
                        trailing: _demoMode
                            ? const StatusPill(
                                label: 'Demo AI Mode',
                                color: AppColors.primary,
                                icon: Icons.auto_awesome_rounded,
                              )
                            : null,
                      ),
                      const SizedBox(height: 24),
                      if (_recommendations.isEmpty)
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'No career recommendations yet',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add some skills to your profile to generate personalized career matches.',
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/skill-management'),
                                child: const Text('Manage Skills'),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._recommendations.map((rec) {
                          final careerName =
                              (rec['career'] ?? rec['name'] ?? 'Software Engineer')
                                  .toString();
                          final matchScore =
                              (rec['match_score'] as num?)?.toInt() ?? 75;
                          final reason =
                              (rec['reason'] ?? rec['description'] ?? '')
                                  .toString();
                          final matchingSkills =
                              (rec['matching_skills'] as List<dynamic>? ?? [])
                                  .map((e) => e.toString())
                                  .toList();
                          final missingSkills =
                              (rec['missing_skills'] as List<dynamic>? ?? [])
                                  .map((e) => e.toString())
                                  .toList();
                          final requiredSkills =
                              (rec['required_skills'] as List<dynamic>? ??
                                      [...matchingSkills, ...missingSkills])
                                  .map((e) => e.toString())
                                  .toList();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _RecommendationCard(
                              career: careerName,
                              matchScore: matchScore,
                              reason: reason,
                              matchingSkills: matchingSkills,
                              missingSkills: missingSkills,
                              onSelect: () => context.go(
                                '/career-details',
                                extra: {
                                  'career': careerName,
                                  'description':
                                      (rec['description'] ?? reason).toString(),
                                  'matchScore': matchScore,
                                  'requiredSkills': requiredSkills,
                                  'matchingSkills': matchingSkills,
                                  'missingSkills': missingSkills,
                                },
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String career;
  final int matchScore;
  final String reason;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final VoidCallback onSelect;

  const _RecommendationCard({
    required this.career,
    required this.matchScore,
    required this.reason,
    required this.matchingSkills,
    required this.missingSkills,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = matchScore >= 75
        ? AppColors.success
        : matchScore >= 50
            ? AppColors.primary
            : AppColors.warning;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.work_outline_rounded,
                    color: scoreColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        career,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusPill(
                  label: '$matchScore% Match',
                  color: scoreColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: matchScore.clamp(0, 100) / 100.0,
                minHeight: 7,
                backgroundColor: AppColors.background,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 16),
            if (matchingSkills.isNotEmpty) ...[
              const Text(
                'Matching Skills',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: matchingSkills
                    .map(
                      (skill) => StatusPill(
                        label: skill,
                        color: AppColors.success,
                        icon: Icons.check_rounded,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (missingSkills.isNotEmpty) ...[
              const Text(
                'Skills to Develop',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: missingSkills
                    .map(
                      (skill) => StatusPill(
                        label: skill,
                        color: AppColors.warning,
                        icon: Icons.add_rounded,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View details & analyze gap',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
