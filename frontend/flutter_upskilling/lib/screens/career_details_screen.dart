import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';

class CareerDetailsScreen extends StatelessWidget {
  const CareerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final careerName = (args != null && args['career'] != null)
        ? args['career'].toString()
        : 'Software Engineer';

    final fallback = _getCareerDetails(careerName);
    final description = (args != null &&
            args['description'] != null &&
            args['description'].toString().isNotEmpty)
        ? args['description'].toString()
        : fallback['description'] as String;
    final requiredSkills = (args != null &&
            args['requiredSkills'] is List &&
            (args['requiredSkills'] as List).isNotEmpty)
        ? (args['requiredSkills'] as List).map((e) => e.toString()).toList()
        : fallback['requiredSkills'] as List<String>;
    final matchScore =
        (args != null && args['matchScore'] is num)
            ? (args['matchScore'] as num).toInt()
            : 75;

    return Scaffold(
      appBar: AppBarWidget(
        title: careerName,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/career-recommendations'),
        ),
      ),
      body: PageContainer(
        maxWidth: 920,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCareerHero(context, careerName, matchScore, requiredSkills),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Role Overview',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Required Competencies',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      StatusPill(
                        label: '${requiredSkills.length} skills',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: requiredSkills
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildMatchAssessment(matchScore),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.go(
                    '/skill-gap-analysis',
                    extra: {
                      'career': careerName,
                      'requiredSkills': requiredSkills,
                    },
                  ),
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Assess My Skills'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/career-recommendations'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Recommendations'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getCareerDetails(String careerName) {
    final Map<String, Map<String, dynamic>> careers = {
      'Software Engineer': {
        'description':
            'Build and maintain software applications, systems, and platforms using modern programming languages, architecture patterns, and testing practices.',
        'requiredSkills': [
          'Python',
          'JavaScript',
          'Data Structures',
          'SQL',
          'Git',
          'System Design',
          'DevOps'
        ],
      },
      'Data Scientist': {
        'description':
            'Analyze complex data to uncover trends, train statistical and predictive models, and communicate actionable insights.',
        'requiredSkills': [
          'Python',
          'SQL',
          'Statistics',
          'Data Analysis',
          'Machine Learning',
          'Data Visualization'
        ],
      },
      'Machine Learning Engineer': {
        'description':
            'Develop and deploy machine learning models at scale using deep learning frameworks and production ML pipelines.',
        'requiredSkills': [
          'Python',
          'Machine Learning',
          'Deep Learning',
          'PyTorch',
          'TensorFlow',
          'Data Structures',
          'Docker'
        ],
      },
    };

    return careers[careerName] ?? careers['Software Engineer']!;
  }

  Widget _buildCareerHero(
    BuildContext context,
    String careerName,
    int matchScore,
    List<String> requiredSkills,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;
          final titleCol = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$matchScore% ROLE FIT',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                careerName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          );

          final cta = ElevatedButton.icon(
            onPressed: () => context.go(
              '/skill-gap-analysis',
              extra: {
                'career': careerName,
                'requiredSkills': requiredSkills,
              },
            ),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Run Skill Gap'),
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: Colors.white,
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: titleCol),
                const SizedBox(width: 20),
                cta,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleCol, const SizedBox(height: 16), cta],
          );
        },
      ),
    );
  }

  Widget _buildMatchAssessment(int matchScore) {
    final label = matchScore >= 75
        ? 'Strong match'
        : matchScore >= 50
            ? 'Moderate match'
            : 'Developing match';
    final color = matchScore >= 75
        ? AppColors.success
        : matchScore >= 50
            ? AppColors.primary
            : AppColors.warning;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Skill Match Assessment',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              StatusPill(label: label, color: color),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: matchScore.clamp(0, 100) / 100.0,
              minHeight: 12,
              backgroundColor: AppColors.background,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$matchScore% readiness based on your current saved skills',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
