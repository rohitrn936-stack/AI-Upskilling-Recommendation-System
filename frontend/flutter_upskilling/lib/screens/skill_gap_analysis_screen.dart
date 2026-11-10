import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/main.dart';

class SkillGapAnalysisScreen extends StatefulWidget {
  const SkillGapAnalysisScreen({super.key});

  @override
  State<SkillGapAnalysisScreen> createState() => _SkillGapAnalysisScreenState();
}

class _SkillGapAnalysisScreenState extends State<SkillGapAnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Gap Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/career-details'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skill Gap Analysis',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildMatchPercentage(),
            const SizedBox(height: 30),
            _buildSkillsComparison(),
            const SizedBox(height: 30),
            _buildAiInterpretation(),
            const Spacer(),
            _buildGenerateRoadmapButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchPercentage() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            const Text(
              'Skill Match Percentage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.58,
              backgroundColor: Colors.grey[200],
              color: Color(0xFF6750A4),
              minHeight: 20,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  '58%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Below average',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFFC107),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsComparison() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Skills Comparison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 16),
            _buildSkillColumn(
              title: 'Your Skills',
              skills: ['Python', 'JavaScript', 'SQL', 'Git'],
              color: Color(0xFF6750A4),
            ),
            const SizedBox(width: 16),
            _buildSkillColumn(
              title: 'Required Skills',
              skills: ['Python', 'Machine Learning', 'TensorFlow', 'Deep Learning', 'Data Visualization'],
              color: Color(0xFFFFC107),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillColumn({
    required String title,
    required List<String> skills,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4.0,
          runSpacing: 4.0,
          children: skills.map(
            (skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                skill,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildAiInterpretation() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'AI Interpretation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Based on your current skills and the requirements for your selected career, you have a 58% skill match. The main areas needing improvement are machine learning algorithms, deep learning frameworks, and data visualization techniques. Focus on building practical projects to strengthen these areas.',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF616161),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateRoadmapButton() {
    return ElevatedButton(
      onPressed: () {
        // TODO: Generate learning roadmap
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF6750A4),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      ),
      child: const Text('Generate Learning Roadmap'),
    );
  }
}