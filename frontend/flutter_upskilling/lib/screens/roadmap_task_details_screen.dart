import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class RoadmapTaskDetailsScreen extends StatelessWidget {
  const RoadmapTaskDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Task Details',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pushNamed('/learning-roadmap'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildTaskInfo(),
            const SizedBox(height: 30),
            _buildTaskProgress(),
            const Spacer(),
            _markTaskCompleted(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              icon: Icons.task,
              label: 'Task Name',
              value: 'Introduction to Machine Learning',
            ),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Phase',
              value: 'Phase 3: Machine Learning Basics',
            ),
            _buildInfoRow(
              icon: Icons.schedule,
              label: 'Estimated Duration',
              value: '2 weeks',
            ),
            _buildInfoRow(
              icon: Icons.book,
              label: 'Learning Objectives',
              value: 'Understand supervised vs unsupervised learning, implement regression and classification algorithms',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskProgress() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Tracking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.4,
              backgroundColor: Colors.grey[200],
              color: Color(0xFF6750A4),
              minHeight: 20,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '40% complete',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Update progress'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _markTaskCompleted(BuildContext ctx) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Mark task as completed
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Task marked as completed'),
            backgroundColor: Color(0xFF6750A4),
          ),
        );
      },
      icon: const Icon(Icons.check_circle),
      label: const Text('Mark as Completed'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF00C853),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
    );
  }
}