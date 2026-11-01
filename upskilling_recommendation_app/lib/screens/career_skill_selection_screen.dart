import 'package:flutter/material';
import 'models/student_profile.dart';
import 'models/skill.dart';
import 'models/career.dart';
import 'services/mock_service.dart';
import 'theme/app_theme.dart';
import 'widgets/primary_button.dart';
import 'widgets/outline_button.dart';
import 'widgets/empty_state.dart';
import 'widgets/skill_chip.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/snackbar.dart';

class CareerSkillSelectionScreen extends StatefulWidget {
  const CareerSkillSelectionScreen({super.key});
  @override
  State<CareerSkillSelectionScreen> createState() =>
      _CareerSkillSelectionScreenState();
}

class _CareerSkillSelectionScreenState
    extends State<CareerSkillSelectionScreen> {
  final _mockService = MockService();
  StudentProfile? _profile;
  List<Career> _careers = [];
  List<Skill> _currentSkills = [];
  Career? _selectedCareer;
  bool _isBeginner = false;
  final _searchController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _mockService.fetchStudentProfile();
      setState(() => _profile = profile);
      _currentSkills = profile.getCurrentSkills();
      _careers = await _mockService.fetchCareers();
      if (_profile!.activeCareerId != null && _careers.isNotEmpty) {
        _selectedCareer = _careers.firstWhere(
          (c) => c.id == _profile!.activeCareerId,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelection() async {
    if (_selectedCareer == null) {
      setState(() => _errorMessage = 'Please select a career');
      return;
    }
    final updatedProfile = _profile!.copyWith(activeCareerId: _selectedCareer!.id);
    await _mockService.saveProfile(updatedProfile);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  void _addSkillFromSearch(String skillName) {
    final newSkill = Skill.mock(name: skillName);
    setState(() {
      _currentSkills = List.from(_currentSkills)..add(newSkill);
    });
    _searchController.clear();
  }

  void _removeSkill(Skill skill) {
    setState(() {
      _currentSkills.removeWhere((s) => s.id == skill.id);
    });
  }

  void _toggleBeginnerStatus() {
    setState(() => _isBeginner = !_isBeginner);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    if (_profile == null) {
      return const EmptyState(
        title: 'Welcome',
        subtitle: 'Loading your profile...',
        icon: Icons.login,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Career & Skills'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSelection,
            tooltip: 'Save and continue',
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_careers.isEmpty) {
      return const EmptyState(
        title: 'No careers available',
        subtitle: 'Please try again later.',
        icon: Icons.error,
      );
    }

    if (_selectedCareer == null) {
      return _buildCareerSelectionSection(isDark);
    }

    if (_currentSkills.isEmpty && !_isBeginner) {
      return _buildSkillEntrySection(isDark, _selectedCareer!);
    }

    return _buildSummarySection(isDark);
  }

  Widget _buildCareerSelectionSection(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a career path',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose the career you want to pursue:',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ..._careers.map((career) => _buildCareerOption(career, isDark)).toList(),
          const SizedBox(height: 24),
          _buildBeginnerOption(isDark),
        ],
      ),
    );
  }

  Widget _buildCareerOption(Career career, bool isDark) {
    final isSelected = _selectedCareer?.id == career.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCareer = career);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Color(0xFF1E293B).withValues(alpha: 0.3)
                : Colors.white,
            border: Border.all(
              color: isSelected ? Color(0xFFFFB84D) : Colors.transparent,
              width: isSelected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(0xFFFFB84D).withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCareerIcon(career.title),
                  size: 20,
                  color: isSelected ? Color(0xFFFFB84D) : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      career.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Color(0xFF1E293B) : Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      career.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Color(0xFFFFB84D) : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCareerIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('data') || lower.contains('analyst')) return Icons.insert_chart;
    if (lower.contains('web') || lower.contains('developer') || lower.contains('frontend'))
      return Icons.code;
    if (lower.contains('ux') || lower.contains('designer')) return Icons.favorite;
    if (lower.contains('cyber') || lower.contains('security')) return Icons.shield;
    return Icons.work;
  }

  Widget _buildBeginnerOption(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCareer = null;
            _isBeginner = true;
            _currentSkills = [];
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Color(0xFF1E293B).withValues(alpha: 0.3)
                : Color(0xFFF8FAFC),
            border: Border.all(
              color: Color(0xFFE2E8F0),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.star_outline, size: 24, color: Color(0xFFFFB84D)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'I\'m a beginner / no skills yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Start from the basics and build your skills',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.radio_button_checked,
                color: Color(0xFFFFB84D),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillEntrySection(bool isDark, Career selectedCareer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    _getCareerIcon(selectedCareer.title),
                    size: 28,
                    color: Color(0xFFFFB84D),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected: ${selectedCareer.title}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          selectedCareer.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ListTile(
            title: const Text("I'm a beginner / no skills yet"),
            leading: _isBeginner
                ? const Icon(Icons.star_half, color: Color(0xFFFFB84D))
                : const Icon(Icons.star_outline),
            trailing: _isBeginner
                ? const Icon(Icons.radio_button_checked, color: Color(0xFFFFB84D))
                : const Icon(Icons.radio_button_unchecked),
            onTap: _toggleBeginnerStatus,
          ),
          const Divider(height: 32),

          const Text(
            'Enter skills you already have:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search skills...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _addSkillFromSearch(_searchController.text),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _currentSkills.map((skill) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SkillChip(
                skill: skill,
                isSelected: true,
                showRemove: true,
                onRemoved: _removeSkill,
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),

          if (_isBeginner)...[
            const Text(
              'Since you\'re a beginner, the learning plan will start with fundamentals.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Add a custom skill',
                    prefixIcon: const Icon(Icons.add),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _searchController.text.isNotEmpty
                    ? () => _addSkillFromSearch(_searchController.text)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),

          const Spacer(),

          PrimaryButton(
            label: 'Generate my learning plan',
            onPressed: _currentSkills.isNotEmpty || _isBeginner
                ? () {
                    _generateLearningPlan();
                  }
                : null,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icons.celebration,
                      const SizedBox(width: 8),
                      const Text(
                        'All set!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You're ready to start your learning journey!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSummaryItem(
            icon: Icons.work,
            label: 'Selected Career',
            value: _selectedCarey!.title,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildSummaryItem(
            icon: Icons.school,
            label: 'Current Skills',
            value:
                '${_currentSkills.length} skill${_currentSkills.length != 1 ? 's' : ''}',
            isDark: isDark,
          ),
          if (_isBeginner)...[
            const SizedBox(height: 12),
            _buildSummaryItem(
              icon: Icons.star_outline,
              label: 'Skill Level',
              value: 'Beginner',
              isDark: isDark,
            ),
          ],

          const SizedBox(height: 24),

          PrimaryButton(
            label: 'Generate my learning plan',
            onPressed: _currentSkills.isNotEmpty || _isBeginner
                ? _generateLearningPlan
                : null,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFFB84D), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  void _generateLearningPlan() {
    if (_selectedCarey == null) {
      setState(() => _errorMessage = 'Please select a career first');
      return;
    }
    _mockService.generateLearningPlan(
      selectedCareer: _selectedCarey!,
      currentSkills: _currentSkills,
    );
    if (!mounted) return;
    Navigator.of(context).pushNamed('/learning-plan');
  }
}