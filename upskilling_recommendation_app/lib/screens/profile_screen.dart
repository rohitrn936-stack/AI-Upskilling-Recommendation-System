import 'package:flutter/material';
import 'models/student_profile.dart';
import 'models/skill.dart';
import 'models/career.dart';
import 'services/mock_service.dart';
import 'theme/app_theme.dart';
import 'widgets/primary_button.dart';
import 'widgets/outline_button.dart';
import 'widgets/empty_state.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState;
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _mockService = MockService();
  StudentProfile? _profile;
  List<Skill> _currentSkills = [];
  Career? _activeCareer;
  bool _isLoading = true;
  String? _errorMessage;

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

      final careers = await _mockService.fetchCareers();
      if (profile.activeCareerId != null) {
        _activeCareer = careers.firstWhere(
          (c) => c.id == profile.activeCareerId,
          orElse: () => Career.mock(title: 'Not selected'),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_profile != null) {
      await _mockService.saveProfile(_profile!);
      if (!mounted) return;
      showSnackbar(context, successSnackbar(message: 'Profile updated'));
    }
  }

  void _toggleTheme(String mode) {
    setState(() {
      // Theme mode handling - in a real app, persist this
    });
    showSnackbar(context, infoSnackbar(message: 'Theme set to $mode'));
  }

  void _editName(String newName) {
    setState(() {
      _profile = _profile!.copyWith(name: newName);
    });
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text(
          'Are you sure you want to sign out? Your progress will be saved locally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _mockService.saveProfile(StudentProfile.guest);
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/welcome', (route) => false);
            },
            child: const Text('Sign out',
                style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    if (_profile == null) {
      return const EmptyState(
        title: 'Profile',
        subtitle: 'Loading profile information...',
        icon: Icons.person,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _buildProfileContent(isDark),
    );
  }

  Widget _buildProfileContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFB84D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 64, color: Color(0xFFFFB84D)),
                ),
                const SizedBox(height: 16),
                Text(
                  _profile!.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _profile!.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildInfoCard(
            icon: Icons.school,
            title: 'Education & Interests',
            children: [
              _buildInfoRow(
                icon: Icons.graduation_cap,
                label: 'Education',
                value: _profile!.education ?? 'Not specified',
              ),
              _buildInfoRow(
                icon: Icons.favorite,
                label: 'Interests',
                value: _profile!.interests ?? 'Not specified',
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildInfoCard(
            icon: Icons.work,
            title: 'Active Career Goal',
            children: _activeCarey != null
                ? [
                    ListTile(
                      leading: Icon(
                        _getCareerIcon(_activeCarey!.title),
                        color: Color(0xFFFFB84D),
                        size: 24,
                      ),
                      title: Text(_activeCarey!.title),
                      subtitle: Text(
                        _activeCarey!.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () async {
                          final updatedProfile =
                              _profile!.copyWith(activeCareerId: null);
                          await _mockService.saveProfile(updatedProfile);
                          if (mounted) setState(() {});
                        },
                        tooltip: 'Remove career goal',
                      ),
                    ),
                  ]
                : [
                    const ListTile(
                      title: Text('No active career goal selected'),
                      subtitle: Text(
                        'Select a career in the dashboard to get started.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 24),

          _buildInfoCard(
            icon: Icons.brightness_6,
            title: 'Appearance',
            children: [
              DropdownButtonFormField<String>(
                value: _profile!.preferredTheme.toString().split('.').last,
                decoration: const InputDecoration(
                  labelText: 'Theme',
                  border: OutlineInputBorder(),
                ),
                items: ['system', 'light', 'dark'].map((mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode),
                )).toList(),
                onChanged: (String? newMode) {
                  if (newMode != null) _toggleTheme(newMode);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Preview: ',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  _buildThemeSwitcherTile(context, isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildInfoCard(
            icon: Icons.security,
            title: 'Account',
            children: [
              _buildActionButton(
                icon: Icons.logout,
                label: 'Sign out',
                color: Color(0xFFF87171),
                onPressed: _confirmSignOut,
              ),
              const Divider(height: 24),
              _buildActionButton(
                icon: Icons.edit,
                label: 'Edit profile',
                onPressed: () {
                  _showEditProfileDialog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: isDark ? Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFFFFB84D), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
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
          Icon(icon, size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextSize(
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: color ?? Color(0xFF3B82F6),
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

  Widget _buildThemeSwitcherTile(BuildContext context, bool isDark) {
    return Container(
      width: 60,
      height: 30,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF64748B) : Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Spacer(flex: 1),
          Expanded(
            child: Container(
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}