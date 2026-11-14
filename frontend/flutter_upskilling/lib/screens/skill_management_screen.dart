import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class SkillManagementScreen extends StatefulWidget {
  const SkillManagementScreen({super.key});

  @override
  State<SkillManagementScreen> createState() => _SkillManagementScreenState();
}

class _SkillManagementScreenState extends State<SkillManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skillController = TextEditingController();
  final _categoryController = TextEditingController();

  String _selectedProficiency = 'Intermediate';
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  List<dynamic> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  @override
  void dispose() {
    _skillController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final skills = await APIClient.getSkills();
      if (!mounted) return;
      setState(() => _skills = skills);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('unauthorized')) {
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() => _error = msg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSkill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await APIClient.addSkill(
        skillName: _skillController.text.trim(),
        proficiencyLevel: _selectedProficiency,
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : 'Technical',
      );
      _skillController.clear();
      _categoryController.clear();
      await _loadSkills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skill added successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteSkill(int skillId) async {
    try {
      await APIClient.deleteSkill(skillId);
      await _loadSkills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skill removed'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Skill Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Skills',
            onPressed: _loadSkills,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading your skills...')
          : _error != null
              ? ErrorMessage(message: _error!, onRetry: _loadSkills)
              : PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Manage Skills',
                        subtitle:
                            'Keep your skill inventory up to date to receive accurate career matches and roadmaps.',
                        trailing: ElevatedButton.icon(
                          onPressed: () => context.go('/career-recommendations'),
                          icon: const Icon(Icons.work_outline_rounded, size: 18),
                          label: const Text('Get Career Matches'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 840;
                          final existingCard = _buildExistingSkills();
                          final formCard = _buildAddSkillForm();

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: existingCard),
                                const SizedBox(width: 20),
                                Expanded(flex: 5, child: formCard),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              formCard,
                              const SizedBox(height: 20),
                              existingCard,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildExistingSkills() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Skill Inventory',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              StatusPill(
                label: '${_skills.length} total',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_skills.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.code_off_rounded,
                      size: 32, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text(
                    'No skills added yet. Add your first skill using the form!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _skills.map((skill) {
                final id = (skill['id'] as num?)?.toInt();
                final name = (skill['skill_name'] ?? '').toString();
                final proficiency =
                    (skill['proficiency_level'] ?? 'Beginner').toString();
                final category = (skill['category'] ?? 'General').toString();

                return _SkillListTile(
                  skillName: name,
                  proficiency: proficiency,
                  category: category,
                  onDelete: id != null ? () => _deleteSkill(id) : null,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAddSkillForm() {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Skill',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Include languages, frameworks, tools, or domain skills.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _skillController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Skill Name',
                hintText: 'e.g., Python, SQL, React',
                prefixIcon: Icon(Icons.code_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a skill name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedProficiency,
              decoration: const InputDecoration(
                labelText: 'Proficiency Level',
                prefixIcon: Icon(Icons.trending_up_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                DropdownMenuItem(
                    value: 'Intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                DropdownMenuItem(value: 'Expert', child: Text('Expert')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedProficiency = newValue);
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _categoryController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _isSubmitting ? null : _addSkill(),
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                hintText: 'e.g., Programming, Database, Cloud',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _addSkill,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(_isSubmitting ? 'Adding...' : 'Add Skill'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillListTile extends StatelessWidget {
  final String skillName;
  final String proficiency;
  final String category;
  final VoidCallback? onDelete;

  const _SkillListTile({
    required this.skillName,
    required this.proficiency,
    required this.category,
    this.onDelete,
  });

  Color _badgeColor() {
    switch (proficiency.toLowerCase()) {
      case 'expert':
        return AppColors.primary;
      case 'advanced':
        return AppColors.secondary;
      case 'intermediate':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skillName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (category.isNotEmpty)
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          StatusPill(label: proficiency, color: badgeColor),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.textMuted,
              tooltip: 'Remove skill',
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class SkillChipWidget extends StatelessWidget {
  final String skillName;
  final String proficiency;
  final String category;
  final VoidCallback? onDelete;

  const SkillChipWidget({
    required this.skillName,
    required this.proficiency,
    required this.category,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$skillName • $proficiency'),
      deleteIcon: onDelete != null ? const Icon(Icons.close, size: 16) : null,
      onDeleted: onDelete,
    );
  }
}
