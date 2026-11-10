import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class CareerRecommendationsScreen extends StatelessWidget {
  const CareerRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Career Recommendations',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Career Recommendations',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildRecommendationsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(BuildContext ctx) {
    // Sample career recommendations
    final recommendations = [
      {
        'career': 'Software Engineer',
        'matchScore': 92,
        'reason': 'Strong foundation in programming and problem-solving skills',
        'matchingSkills': ['Python', 'JavaScript', 'Data Structures'],
        'missingSkills': ['System Design', 'DevOps'],
      },
      {
        'career': 'Data Scientist',
        'matchScore': 78,
        'reason': 'Good analytical skills with foundation in statistics and Python',
        'matchingSkills': ['Python', 'Statistics', 'Data Analysis'],
        'missingSkills': ['Machine Learning', 'Deep Learning'],
      },
      {
        'career': 'Machine Learning Engineer',
        'matchScore': 65,
        'reason': 'Interest in AI with some programming experience',
        'matchingSkills': ['Python', 'Data Structures'],
        'missingSkills': ['Machine Learning', 'PyTorch', 'TensorFlow'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(recommendations.length, (index) {
          final rec = recommendations[index];
          return _RecommendationCard(
            career: rec['career'] as String,
            matchScore: rec['matchScore'] as int,
            reason: rec['reason'] as String,
            matchingSkills: rec['matchingSkills'] as List<String>,
            missingSkills: rec['missingSkills'] as List<String>,
            onSelect: () => ctx.go('/career-details'),
          );
        }),
      ],
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = matchScore >= 80 ? Color(0xFF6750A4) : matchScore >= 60 ? Color(0xFF00D1C1) : Color(0xFFFFC107);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  career,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$matchScore%',
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reason,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ...matchingSkills.map(
                  (skill) => Chip(
                    label: Text(skill),
                    backgroundColor: Color(0xFF6750A4).withValues(alpha: 0.1),
                  ),
                ),
                ...missingSkills.map(
                  (skill) => Chip(
                    label: Text(
                      skill,
                      style: const TextStyle(color: Color(0xFFFFC107)),
                    ),
                    backgroundColor: Color(0xFFFFC107).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}