import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class CareerDetailsScreen extends StatelessWidget {
  const CareerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get career name from route arguments
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final careerName = args != null && args['career'] != null
        ? args['career'] as String
        : 'Software Engineer';

    // Career details based on the selected career
    final careerDetails = _getCareerDetails(careerName);

    return Scaffold(
      appBar: AppBarWidget(
        title: careerName,
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
            // Career image/placeholder
            _buildCareerHeader(careerName),
            const SizedBox(height: 30),
            // Description
            _buildSectionTitle('Description'),
            _buildDescription(careerDetails['description'] as String),
            const SizedBox(height: 20),
            // Required skills
            _buildSectionTitle('Required Skills'),
            _buildRequiredSkills(careerDetails['requiredSkills'] as List<String>),
            const SizedBox(height: 20),
            // Match assessment
            _buildSectionTitle('Skill Match Assessment'),
            _buildMatchAssessment(),
            const SizedBox(height: 30),
            // Action button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Analyze skill gap and generate roadmap
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Starting skill gap analysis...'),
                      backgroundColor: Color(0xFF6750A4),
                    ),
                  );
                  context.go('/skill-gap-analysis');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF6750A4),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text('Assess My Skills'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getCareerDetails(String careerName) {
    final Map<String, dynamic> careers = {
      'Software Engineer': {
        'description': 'Build and maintain software applications, systems, and platforms. Works with various programming languages, frameworks, and tools to develop solutions that meet user needs.',
        'requiredSkills': 'Programming languages (Python, Java, JavaScript, C++); Data structures and algorithms; Version control (Git); Problem-solving; Debugging',
      },
      'Data Scientist': {
        'description': 'Analyze complex extracts data to identify trends, build predictive models, and provide actionable insights. Uses statistical analysis, machine learning, and data visualization.',
        'requiredSkills': 'Statistics and probability; Python or R programming; Machine learning algorithms; Data visualization; SQL',
      },
      'Machine Learning Engineer': {
        'description': 'Develop and deploy machine learning models at scale. Works with ML frameworks, optimizes model performance, and implements ML pipelines in production environments.',
        'requiredSkills': 'Machine learning algorithms; Deep learning frameworks (PyTorch, TensorFlow); Python programming; Data modeling; Model deployment; Software engineering',
      },
    };

    return careers[careerName] ?? careers['Software Engineer'];
  }

  Widget _buildCareerHeader(String careerName) {
    final colors = {
      'Software Engineer': Color(0xFF6750A4),
      'Data Scientist': Color(0xFF119DFF),
      'Machine Learning Engineer': Color(0xFF00D1C1),
    };

    final color = colors[careerName] ?? Color(0xFF6750A4);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          careerName,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6750A4),
        ),
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Text(
      description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
        height: 1.5,
      ),
    );
  }

  Widget _buildRequiredSkills(List<String> skills) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: skills.map(
        (skill) => Chip(
          label: Text(skill),
          backgroundColor: Color(0xFF6750A4).withValues(alpha: 0.1),
        ),
      ).toList(),
    );
  }

  Widget _buildMatchAssessment() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Skill Match',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.grey[200],
              color: Color(0xFF6750A4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '75% match',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Text(
                  'Strong match',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6750A4),
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