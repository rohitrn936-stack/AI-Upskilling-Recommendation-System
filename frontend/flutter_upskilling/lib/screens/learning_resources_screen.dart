import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class LearningResourcesScreen extends StatelessWidget {
  const LearningResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Learning Resources',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pushNamed('/personalized-skills'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommended Resources',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildResourceCategories(),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCategories() {
    final resources = [
      {
        'category': 'Video Courses',
        'resources': [
          {'name': 'TensorFlow in Practice', 'platform': 'Coursera', 'type': 'Course', 'duration': '4 weeks'},
          {'name': 'Python for Everybody', 'platform': 'Coursera', 'type': 'Course', 'duration': '6 weeks'},
          {'name': 'Machine Learning Andrew Ng', 'platform': 'Coursera', 'type': 'Course', 'duration': '11 weeks'},
        ],
      },
      {
        'category': 'Articles & Tutorials',
        'resources': [
          {'name': 'Deep Learning Papers', 'platform': 'Distill.pub', 'type': 'Article', 'duration': 'Ongoing'},
          {'name': 'Python Documentation', 'platform': 'python.org', 'type': 'Documentation', 'duration': 'As needed'},
        ],
      },
      {
        'category': 'Books',
        'resources': [
          {'name': 'Hands-On Machine Learning with Scikit-Learn, Keras & TensorFlow', 'platform': 'OReilly', 'type': 'Book', 'duration': '3-4 months'},
          {'name': 'Python Crash Course', 'platform': 'OReilly', 'type': 'Book', 'duration': '2-3 months'},
        ],
      },
    ];

    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: _buildResourceCategoryChildren(resources),
    );
  }

  List<Widget> _buildResourceCategoryChildren(List<Map<String, dynamic>> resources) {
    final children = <Widget>[];
    for (final resource in resources) {
      final category = resource['category'] as String;
      final resList = resource['resources'] as List<Map<String, dynamic>>;
      children.add(_ResourceCategoryCard(
        category: category,
        resources: resList,
      ));
    }
    return children;
  }
}

class _ResourceCategoryCard extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> resources;

  const _ResourceCategoryCard({
    required this.category,
    required this.resources,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 16),
            ..._buildResourceItems(resources),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResourceItems(List<Map<String, dynamic>> resources) {
    final children = <Widget>[];
    for (final res in resources) {
      final resourceName = res['name'] as String;
      final platform = res['platform'] as String;
      final resourceType = res['type'] as String;
      final estimatedDuration = res['duration'] as String;
      children.add(_ResourceItem(
        resourceName: resourceName,
        platform: platform,
        resourceType: resourceType,
        estimatedDuration: estimatedDuration,
      ));
    }
    return children;
  }
}

class _ResourceItem extends StatelessWidget {
  final String resourceName;
  final String platform;
  final String resourceType;
  final String estimatedDuration;

  const _ResourceItem({
    required this.resourceName,
    required this.platform,
    required this.resourceType,
    required this.estimatedDuration,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeColors = {
      'Course': Color(0xFF6750A4),
      'Article': Color(0xFF119DFF),
      'Book': Color(0xFF00C853),
      'Tutorial': Color(0xFFFFC107),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: typeColors[resourceType] ?? Color(0xFF6750A4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resourceName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$platform • $resourceType',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated: $estimatedDuration',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}