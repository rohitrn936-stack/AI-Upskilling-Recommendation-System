import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  String _name = '';
  String _email = '';
  String _institution = '';
  String _degree = '';
  String _academicYear = '';
  String _interests = '';
  String _learningGoals = '';
  List<dynamic> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        APIClient.getProfile(),
        APIClient.getSkills(),
      ]);
      final profile =
          (results[0] as Map<String, dynamic>)['data'] as Map<String, dynamic>? ??
              {};
      final skills = results[1] as List<dynamic>;

      if (!mounted) return;
      setState(() {
        _name = (profile['name'] ?? '').toString();
        _email = (profile['email'] ?? '').toString();
        _institution = (profile['institution'] ?? '').toString();
        _degree = (profile['degree'] ?? '').toString();
        _academicYear = (profile['academic_year'] ?? '').toString();
        _interests = (profile['interests'] ?? '').toString();
        _learningGoals = (profile['learning_goals'] ?? '').toString();
        _skills = skills;
      });
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

  Future<void> _showEditDialog() async {
    final nameCtrl = TextEditingController(text: _name);
    final instCtrl = TextEditingController(text: _institution);
    final degCtrl = TextEditingController(text: _degree);
    final yearCtrl = TextEditingController(text: _academicYear);
    final intCtrl = TextEditingController(text: _interests);
    final goalCtrl = TextEditingController(text: _learningGoals);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Educational Institution',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: degCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Degree',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yearCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Academic Year',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: intCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Career Interests',
                    prefixIcon: Icon(Icons.interests_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Learning Goals',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (saved == true) {
      setState(() => _isSaving = true);
      try {
        await APIClient.updateProfile(
          name: nameCtrl.text.trim(),
          institution: degCtrl.text.trim(),
          degree: instCtrl.text.trim(),
          academicYear: yearCtrl.text.trim(),
          interests: intCtrl.text.trim(),
          learningGoals: goalCtrl.text.trim(),
        );
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
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
          setState(() => _isSaving = false);
        }
      }
    }

    nameCtrl.dispose();
    instCtrl.dispose();
    degCtrl.dispose();
    yearCtrl.dispose();
    intCtrl.dispose();
    goalCtrl.dispose();
  }

  String _initials() {
    final trimmed = _name.trim();
    if (trimmed.isEmpty) return 'S';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'My Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Profile',
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading profile...')
          : _error != null
              ? ErrorMessage(message: _error!, onRetry: _loadProfile)
              : PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 820;
                          final leftCard = _buildProfileDetailsCard();
                          final rightCol = Column(
                            children: [
                              _buildGoalsCard(),
                              const SizedBox(height: 20),
                              _buildSkillsSection(),
                            ],
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: leftCard),
                                const SizedBox(width: 20),
                                Expanded(flex: 6, child: rightCol),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              leftCard,
                              const SizedBox(height: 20),
                              rightCol,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    final displayName = _name.isNotEmpty ? _name : 'Student';
    final subLabel = [_degree, _institution]
        .where((e) => e.trim().isNotEmpty)
        .join(' • ');

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;
          final profileIdentity = Row(
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _initials(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email.isNotEmpty ? _email : 'No email provided',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (subLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      StatusPill(
                        label: subLabel,
                        color: AppColors.primary,
                        icon: Icons.school_outlined,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final editButton = ElevatedButton.icon(
            onPressed: _isSaving ? null : _showEditDialog,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Edit Profile'),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: profileIdentity),
                const SizedBox(width: 16),
                editButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileIdentity,
              const SizedBox(height: 16),
              editButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileDetailsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic & Personal Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Full Name',
            value: _name.isNotEmpty ? _name : 'Not set',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: _email.isNotEmpty ? _email : 'Not set',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.account_balance_outlined,
            label: 'Institution',
            value: _institution.isNotEmpty ? _institution : 'Not set',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.school_outlined,
            label: 'Degree',
            value: _degree.isNotEmpty ? _degree : 'Not set',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Academic Year',
            value: _academicYear.isNotEmpty ? _academicYear : 'Not set',
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests & Learning Goals',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.interests_outlined,
            label: 'Career Interests',
            value: _interests.isNotEmpty ? _interests : 'Not set',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.flag_outlined,
            label: 'Learning Goals',
            value: _learningGoals.isNotEmpty ? _learningGoals : 'Not set',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isEmptyValue = value == 'Not set';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isEmptyValue ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skills (${_skills.length})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/skill-management'),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Manage Skills'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_skills.isEmpty)
            const Text(
              'No skills added yet. Click Manage Skills to add your first skill.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _skills.map((skill) {
                final name = (skill['skill_name'] ?? '').toString();
                final level = (skill['proficiency_level'] ?? '').toString();
                return Chip(
                  label: Text(
                    level.isNotEmpty ? '$name • $level' : name,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
