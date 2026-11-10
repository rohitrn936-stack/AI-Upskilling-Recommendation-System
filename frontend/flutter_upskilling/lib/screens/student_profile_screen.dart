import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'My Profile',
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
              'Your Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildProfileInfo(),
            const SizedBox(height: 30),
            _buildSkillsSection(),
            const SizedBox(height: 30),
            _buildEducationalInfo(),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF6750A4),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Name',
              value: 'Student Name',
            ),
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: 'student@example.com',
            ),
            _buildInfoRow(
              icon: Icons.school,
              label: 'Educational Institution',
              value: 'University Name',
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

  Widget _buildSkillsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Existing Skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,children: [
                  Chip(
                    label: Text('Python'),
                    backgroundColor: Color(0xFF6750A4).withValues(alpha: 0.1),
                  ),
                  Chip(
                    label: Text('JavaScript'),
                    backgroundColor: Color(0xFF6750A4).withValues(alpha: 0.1),
                  ),
                  Chip(
                    label: Text('SQL'),
                    backgroundColor: Color(0xFF6750A4).withValues(alpha: 0.1),
                  ),
                  Chip(
                    label: Text('Git'),
                    backgroundColor: Color(0xFF6750A4).withValues(alpha: 0.1),
                  ),
                ],

            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Educational Background',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.school,
              label: 'Degree',
              value: 'Bachelor of Science',
            ),
            _buildInfoRow(
              icon: Icons.school,
              label: 'Academic Year',
              value: '3rd Year',
            ),
            _buildInfoRow(
              icon: Icons.book,
              label: 'Interests',
              value: 'Software Development, AI',
            ),
          ],
        ),
      ),
    );
  }
}