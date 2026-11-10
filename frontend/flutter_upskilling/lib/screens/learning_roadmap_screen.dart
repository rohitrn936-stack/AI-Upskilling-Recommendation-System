import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class LearningRoadmapScreen extends StatelessWidget {
  const LearningRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Learning Roadmap',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pushNamed('/progress-tracking'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Learning Roadmap',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildRoadmapOverview(context),
            const Spacer(),
            _navigateToTask(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapOverview(BuildContext ctx) {
    // Sample roadmap phases
    final phases = [
      {
        'phaseName': 'Phase 1: Python Fundamentals',
        'order': 1,
        'description': 'Master Python programming basics including syntax, data structures, and control flow',
        'duration': '4 weeks',
        'completed': true,
      },
      {
        'phaseName': 'Phase 2: Mathematics for ML',
        'order': 2,
        'description': 'Learn linear algebra, probability, and statistics essential for machine learning',
        'duration': '3 weeks',
        'completed': false,
      },
      {
        'phaseName': 'Phase 3: Machine Learning Basics',
        'order': 3,
        'description': 'Introduction to supervised and unsupervised learning, regression, and classification',
        'duration': '5 weeks',
        'completed': false,
      },
      {
        'phaseName': 'Phase 4: Deep Learning',
        'order': 4,
        'description': 'Neural networks, backpropagation, and introduction to CNN/RNN architectures',
        'duration': '6 weeks',
        'completed': false,
      },
      {
        'phaseName': 'Phase 5: PyTorch/TensorFlow',
        'order': 5,
        'description': 'Build and train models using PyTorch or TensorFlow frameworks',
        'duration': '5 weeks',
        'completed': false,
      },
      {
        'phaseName': 'Phase 6: Practical Projects',
        'order': 6,
        'description': 'Build 3 capstone projects to demonstrate your skills to employers',
        'duration': '6 weeks',
        'completed': false,
      },
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Roadmap Phases',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(phases.length, (index) {
              final phase = phases[index];
              return _PhaseItem(
                phaseName: phase['phaseName'] as String,
                description: phase['description'] as String,
                duration: phase['duration'] as String,
                isCompleted: phase['completed'] as bool,
                onTap: () {
                  final completed = phase['completed'] as bool;
                  if (!completed) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Starting phase...'),
                        backgroundColor: Color(0xFF6750A4),
                      ),
                    );
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _navigateToTask(BuildContext ctx) {
    return ElevatedButton.icon(
      onPressed: () {
        ctx.pushNamed('/roadmap-task-details');
      },
      icon: const Icon(Icons.arrow_forward),
      label: const Text('View All Tasks'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF6750A4),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
    );
  }
}

class _PhaseItem extends StatelessWidget {
  final String phaseName;
  final String description;
  final String duration;
  final bool isCompleted;
  final VoidCallback onTap;

  const _PhaseItem({
    required this.phaseName,
    required this.description,
    required this.duration,
    required this.isCompleted,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? Color(0xFF00C853) : Color(0xFF6750A4);
    final textColor = isCompleted ? Color(0xFF00C853) : Color(0xFF333333);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            // Phase number circle
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                phaseName.split(' ')[1],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Phase details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phaseName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Duration and status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'Upcoming',
                        style: TextStyle(
                          fontSize: 8,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}