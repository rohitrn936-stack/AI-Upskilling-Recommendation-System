import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class SkillManagementScreen extends StatelessWidget {
  const SkillManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Skill Management',
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
              'Manage Skills',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildExistingSkills(),
            const SizedBox(height: 30),
            _addNewSkill(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingSkills() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: const [
                SkillChipWidget(
                  skillName: 'Python',
                  proficiency: 'Intermediate',
                  category: 'Programming',
                  onDelete: null,
                ),
                SkillChipWidget(
                  skillName: 'JavaScript',
                  proficiency: 'Beginner',
                  category: 'Programming',
                  onDelete: null,
                ),
                SkillChipWidget(
                  skillName: 'SQL',
                  proficiency: 'Intermediate',
                  category: 'Database',
                  onDelete: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _addNewSkill(BuildContext ctx) {
    final skillController = TextEditingController();
    final proficiencyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Skill',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: skillController,
                    decoration: const InputDecoration(
                      labelText: 'Skill Name',
                      prefixIcon: Icon(Icons.code),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a skill name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: proficiencyController.text.isNotEmpty
                        ? proficiencyController.text
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Proficiency Level',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Beginner',
                        child: Text('Beginner'),
                      ),
                      DropdownMenuItem(
                        value: 'Intermediate',
                        child: Text('Intermediate'),
                      ),
                      DropdownMenuItem(
                        value: 'Advanced',
                        child: Text('Advanced'),
                      ),
                      DropdownMenuItem(
                        value: 'Expert',
                        child: Text('Expert'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        proficiencyController.text = newValue;
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        // TODO: Add skill to database
                        skillController.clear();
                        proficiencyController.clear();
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Skill added successfully'),
                              backgroundColor: Color(0xFF6750A4),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF6750A4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add Skill'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}class SkillChipWidget extends StatefulWidget {
  final String skillName;
  final String proficiency;
  final String category;
  final VoidCallback? onDelete;

  const SkillChipWidget({
    required this.skillName,
    required this.proficiency,
    required this.category,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  State<SkillChipWidget> createState() => _SkillChipWidgetState();
}

class _SkillChipWidgetState extends State<SkillChipWidget> {
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Row(
        children: [
          Text(widget.skillName),
          const Spacer(),
          Text(
            widget.proficiency,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
      avatar: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF6750A4),
          shape: BoxShape.circle,
        ),
      ),
      deleteIcon: widget.onDelete != null
          ? IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: widget.onDelete,
              tooltip: 'Remove skill',
            )
          : null,
      onDeleted: widget.onDelete,
      backgroundColor: Color(0xFF6750A4).withValues(alpha: 0.1),
    );
  }
}
