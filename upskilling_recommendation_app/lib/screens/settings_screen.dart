import 'package:flutter/material';
import 'models/settings.dart';
import 'services/mock_service.dart';
import 'theme/app_theme.dart';
import 'widgets/primary_button.dart';
import 'widgets/outline_button.dart';
import 'widgets/empty_state.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState;
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _mockService = MockService();
  AppSettings _settings = AppSettings.mock();
  StudentProfile? _profile;
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
      if (profile != null) {
        final combinedSettings =
            AppSettings.mock(themeMode: ThemeMode.values.byName(
                profile.preferredTheme.toString().split('.').last));
        setState(() => _settings = combinedSettings);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    await _mockService.saveProfile(_profile!.copyWith(
      preferredTheme: ThemeMode.values.byName(_settings.themeMode!),
    ));
    if (!mounted) return;
    showSnackbar(context, successSnackbar(message: 'Settings saved'));
  }

  void _setThemeMode(String mode) {
    setState(() {
      _settings = _settings.copyWith(themeMode: mode);
    });
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _settings = _settings.copyWith(notificationsEnabled: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _buildSettingsContent(isDark),
    );
  }

  Widget _buildSettingsContent(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        _buildSectionHeader(title: 'Appearance', icon: Icons.brightness_6,
            color: Color(0xFFFFB84D)),
        const SizedBox(height: 8),
        _buildSettingTile(
          title: 'Theme',
          subtitle: _settings.themeMode ?? 'system',
          leading: Icons.brightness_6,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showThemeDialog(context),
          isDark: isDark,
        ),
        const Divider(height: 24),

        _buildSectionHeader(title: 'Notifications', icon: Icons.notifications,
            color: Color(0xFF3B82F6)),
        const SizedBox(height: 8),
        _buildSettingTile(
          title: 'Learning reminders',
          subtitle: _settings.notificationsEnabled ?? false ? 'Enabled' : 'Disabled',
          leading: Icons.notifications,
          trailing: Switch(
            value: _settings.notificationsEnabled ?? false,
            activeColor: Color(0xFFFFB84D),
            onChanged: _toggleNotifications,
          ),
        ),
        const Divider(height: 24),

        _buildSectionHeader(title: 'Account', icon: Icons.security,
            color: Color(0xFFF87171)),
        const SizedBox(height: 8),
        _buildSettingTile(
          title: 'Sign out',
          subtitle: 'Log out of your account',
          leading: Icons.logout,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _confirmSignOut,
          isDestructive: true,
        ),
        const Divider(height: 24),

        _buildSectionHeader(title: 'Privacy', icon: Icons.shield,
            color: Color(0xFF6B7280)),
        const SizedBox(height: 8),
        _buildSettingTile(
          title: 'Privacy policy',
          leading: Icons.remove_red_eye,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () =>
              showSnackbar(context, infoSnackbar(message: 'Privacy policy placeholder')),
        ),
        _buildSettingTile(
          title: 'Terms of service',
          leading: Icons.gavel,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () =>
              showSnackbar(context, infoSnackbar(message: 'Terms placeholder')),
        ),
        const Divider(height: 24),

        _buildSectionHeader(title: 'About', icon: Icons.info,
            color: Color(0xFF8B5CF6)),
        const SizedBox(height: 8),
        _buildSettingTile(
          title: 'Upskilling Recommendation',
          subtitle: 'Version 1.0.0',
          leading: Icons.menu_book,
          trailing: const SizedBox.shrink(),
        ),
        _buildSettingTile(
          title: 'Learn more',
          leading: Icons.open_in_new,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () =>
              showSnackbar(context, infoSnackbar(message: 'More information')),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData leading,
    required Widget trailing,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      leading: Icon(leading, color: Color(0xFF64748B)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showThemeDialog(BuildContext context) {
    final currentMode = _settings.themeMode ?? 'system';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(context, 'system', currentMode),
            const Divider(height: 12),
            _buildThemeOption(context, 'light', currentMode),
            const Divider(height: 12),
            _buildThemeOption(context, 'dark', currentMode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _setThemeMode(_settings.themeMode ?? 'system');
              _saveSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String mode, String currentMode) {
    final isSelected = mode == currentMode;
    return RadioListTile<String>(
      value: mode,
      groupValue: currentMode,
      activeColor: Color(0xFFFFB84D),
      title: Text(
        mode,
        style: TextStyle(
          color: isSelected ? Color(0xFF1E293B) : Color(0xFF64748B),
        ),
      ),
      onChanged: (String? newValue) {
        if (newValue != null) _setThemeMode(newValue);
      },
    );
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
}