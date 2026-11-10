import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class ProgressTrackingScreen extends StatelessWidget {
  const ProgressTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Progress Tracking',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pushNamed('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildOverallProgress(),
            const SizedBox(height: 30),
            _buildPhaseProgress(),
            const Spacer(),
            _navigateBack(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Overall Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ProgressCircle(
                  percentage: 35,
                  label: 'Completed',
                  color: Color(0xFF6750A4),
                ),
                _ProgressCircle(
                  percentage: 65,
                  label: 'Remaining',
                  color: Color(0xFFFFC107),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: 0.35,
              backgroundColor: Colors.grey[200],
              color: Color(0xFF6750A4),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            const Text(
              '35% complete',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseProgress() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phase Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 16),
            _PhaseRow(
              phaseName: 'Phase 1: Python Fundamentals',
              progress: 100,
              color: Color(0xFF00C853),
            ),
            _PhaseRow(
              phaseName: 'Phase 2: Mathematics for ML',
              progress: 20,
              color: Color(0xFF6750A4),
            ),
            _PhaseRow(
              phaseName: 'Phase 3: Machine Learning Basics',
              progress: 5,
              color: Color(0xFFFFC107),
            ),
            _PhaseRow(
              phaseName: 'Phase 4: Deep Learning',
              progress: 0,
              color: Color(0xFFE879F9),
            ),
            _PhaseRow(
              phaseName: 'Phase 5: PyTorch/TensorFlow',
              progress: 0,
              color: Color(0xFF6750A4),
            ),
            _PhaseRow(
              phaseName: 'Phase 6: Practical Projects',
              progress: 0,
              color: Color(0xFFFFC107),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigateBack(BuildContext ctx) {
    return ElevatedButton(
      onPressed: () => ctx.pushNamed('/dashboard'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF6750A4),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: const Text('Back to Dashboard'),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  final String phaseName;
  final int progress;
  final Color color;

  const _PhaseRow({
    required this.phaseName,
    required this.progress,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              phaseName,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Text(
            '$progress%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF6750A4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  final double percentage;
  final String label;
  final Color color;

  const _ProgressCircle({
    required this.percentage,
    required this.label,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '${percentage.floor()}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6750A4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}