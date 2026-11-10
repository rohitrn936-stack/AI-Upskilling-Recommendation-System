import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class PersonalizedSkillSuggestionsScreen extends StatelessWidget {
  const PersonalizedSkillSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Personalized Skill Suggestions',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pushNamed('/skill-gap-analysis'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommended Skills',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildSuggestionCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCards() {
    final suggestions = [
      {
        'skill': 'Machine Learning',
        'reason': 'Essential for developing predictive models and AI solutions',
        'priority': 'high',
        'explanation': 'Connects directly with your Python foundation and opens doors to advanced AI careers',
      },
      {
        'skill': 'Python Advanced',
        'reason': 'Core language for AI/ML development and automation',
        'priority': 'high',
        'explanation': 'Strengthen your existing Python skills with advanced features and libraries',
      },
      {
        'skill': 'Data Visualization',
        'reason': 'Critical for communicating insights and model results',
        'priority': 'medium',
        'explanation': 'Builds on your SQL and Python skills to effectively present data',
      },
      {
        'skill': 'TensorFlow',
        'reason': 'Industry-standard framework for deep learning models',
        'priority': 'high',
        'explanation': 'Most widely used framework for building and deploying ML models',
      },
      {
        'skill': 'Git & Version Control',
        'reason': 'Essential for collaborative development and project management',
        'priority': 'medium',
        'explanation': 'Complements your existing Git knowledge with team workflows',
      },
    ];

    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: _buildSuggestionCardChildren(suggestions),
    );
  }

  List<Widget> _buildSuggestionCardChildren(List<Map<String, dynamic>> suggestions) {
    final children = <Widget>[];
    for (final sug in suggestions) {
      final skill = sug['skill'] as String;
      final reason = sug['reason'] as String;
      final priority = sug['priority'] as String;
      final explanation = sug['explanation'] as String;
      final priorityColors = {
        'high': Color(0xFF6750A4),
        'medium': Color(0xFF00D1C1),
        'low': Color(0xFFFFC107),
      };
      final color = priorityColors[priority] ?? Color(0xFF6750A4);
      children.add(_SkillSuggestionCard(
        skill: skill,
        reason: reason,
        priority: priority,
        explanation: explanation,
        color: color,
      ));
    }
    return children;
  }
}

class _SkillSuggestionCard extends StatelessWidget {
  final String skill;
  final String reason;
  final String priority;
  final String explanation;
  final Color color;

  const _SkillSuggestionCard({
    required this.skill,
    required this.reason,
    required this.priority,
    required this.explanation,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForSkill(skill),
                    color: color,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priority[0].toUpperCase() + priority.substring(1),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6750A4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reason,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              explanation,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSkill(String skill) {
    final icons = {
      'Machine Learning': Icons.science,
      'Python': Icons.code,
      'Data Visualization': Icons.bar_chart,
      'TensorFlow': Icons.widgets,
      'Git & Version Control': Icons.folder,
    };
    return icons[skill] ?? Icons.school;
  }
}