import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  String? _error;

  bool _demoMode = true;
  String _aiProvider = 'gemini';
  String _aiModel = 'gemini-pro';
  String _environment = 'development';
  String _backendStatus = 'healthy';
  String _statusMessage = '';

  // API key configuration state
  bool _isConfiguring = false;
  String _apiKey = '';
  bool _isKeyVisible = false;
  String? _apiKeyStatusMessage;
  bool _apiKeyConfigured = false;
  bool _apiKeyValid = false;
  String _apiProvider = 'gemini';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        APIClient.getDemoMode(),
        APIClient.getHealth(),
      ]);

      final demoData = results[0];
      final healthData = results[1];

      if (!mounted) return;
      setState(() {
        _demoMode = demoData['demo_mode'] == true;
        _aiProvider = (demoData['ai_provider'] ??
                healthData['ai_provider'] ??
                'gemini')
            .toString();
        _aiModel = (demoData['ai_model'] ?? 'gemini-pro').toString();
        _statusMessage = (demoData['message'] ?? '').toString();
        _environment =
            (healthData['environment'] ?? 'development').toString();
        _backendStatus = (healthData['status'] ?? 'healthy').toString();
      });

      // Fetch API key status
      await _fetchApiKeyStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchApiKeyStatus() async {
    try {
      final result = await APIClient.getApiKeyStatus();
      if (!mounted) return;
      setState(() {
        _apiKeyConfigured = result['configured'] ?? false;
        _apiKeyValid = result['valid'] ?? false;
        _apiProvider = result['provider'] ?? 'gemini';
        _apiKeyStatusMessage = result['message'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiKeyStatusMessage = 'Failed to fetch API key status: $e';
      });
    }
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // Toggle API key visibility
  void _toggleKeyVisibility() {
    setState(() => _isKeyVisible = !_isKeyVisible);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Settings',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: _loadSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Checking backend settings...')
          : PageContainer(
              maxWidth: 840,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Application Settings',
                    subtitle:
                        'Inspect AI service configuration, backend health, and manage your session.',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Backend check failed: $_error',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadSettings,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildApiSettings(),
                  const SizedBox(height: 20),
                  _buildGeneralSettings(context),
                ],
              ),
            ),
    );
  }

  Widget _buildApiSettings() {
    final providerLabel = _aiProvider.toUpperCase();
    final modeSubtitle = _demoMode
        ? 'Demo mode active (configured in backend/.env)'
        : 'API key configured on backend';

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AI Configuration',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusPill(
                label: _demoMode ? 'Demo Mode' : 'Live AI',
                color: _demoMode ? AppColors.primary : AppColors.success,
                icon: Icons.auto_awesome_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSettingTile(
            icon: Icons.flash_on_rounded,
            title: 'AI Provider',
            subtitle:
                '$providerLabel (${_demoMode ? 'demo mode' : 'configured'})',
            trailing: StatusPill(
              label: providerLabel,
              color: _demoMode ? AppColors.primary : AppColors.success,
            ),
            onTap: () => _showInfo(
              _statusMessage.isNotEmpty
                  ? _statusMessage
                  : 'Configured via backend/.env AI_PROVIDER setting.',
            ),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.vpn_key_outlined,
            title: 'AI API Key Status',
            subtitle: modeSubtitle,
            onTap: _demoMode
                ? null
                : () {
                    // Show the API key configuration interface
                    _showApiKeyConfigurationDialog();
                  },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.smart_toy_outlined,
            title: 'Active Model',
            subtitle: _aiModel,
            onTap: () => _showInfo('Active backend AI model: $_aiModel'),
          ),
          // API Key Configuration Section
          if (!_demoMode) ...[
            const Divider(height: 24),
            AppCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Key Configuration',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Status summary
                  if (_apiKeyConfigured || _apiKeyStatusMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(
                            _apiKeyValid
                                ? Icons.check_circle_rounded
                                : _apiKeyConfigured
                                    ? Icons.warning_amber_rounded
                                    : Icons.error_rounded,
                            color: _apiKeyValid
                                ? AppColors.success
                                : _apiKeyConfigured
                                    ? AppColors.warning
                                    : AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _apiKeyStatusMessage ??
                                  'No API key configured',
                              style: TextStyle(
                                fontSize: 13,
                                color: _apiKeyValid
                                    ? AppColors.success
                                    : _apiKeyConfigured
                                        ? AppColors.warning
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // API key input field
                  TextField(
                    controller: TextEditingController()
                      ..text = _apiKey.isNotEmpty ? '••••••••••' : '',
                    obscure: !_isKeyVisible,
                    obscuringCharacter: '•',
                    enableSuggestions: false,
                    autocorrect: false,
                    enableInteractiveSelection: false,
                    decoration: InputDecoration(
                      labelText: 'AI API Key',
                      hintText: 'Enter your AI provider API key',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isKeyVisible
                          ? const Icon(Icons.visibility_off_rounded)
                          : const Icon(Icons.visibility_rounded),
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _apiKey = value);
                    },
                    maxLines: 1,
                  ),
                  const SizedBox(height: 20),
                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isConfiguring ? null : _configureApiKey,
                          child: _isConfiguring
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _apiKey = '');
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Validation toggle
                  SwitchListTile(
                    title: const Text('Validate key with provider'),
                    value: true,
                    onChanged: (bool value) {
                      // Validation is always performed; this is for future UI
                      setState(() {});
                    },
                    subtitle: const Text(
                      'Check if the key works with the selected AI provider',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext ctx) {
    final isHealthy = _backendStatus.toLowerCase() == 'healthy' ||
        _backendStatus.toLowerCase() == 'ok';

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General & Account',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _buildSettingTile(
            icon: Icons.cloud_done_outlined,
            title: 'Backend Service',
            subtitle: 'Status: $_backendStatus • Environment: $_environment',
            trailing: StatusPill(
              label: _backendStatus.toUpperCase(),
              color: isHealthy ? AppColors.success : AppColors.warning,
            ),
            onTap: _loadSettings,
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.light_mode_outlined,
            title: 'Appearance Theme',
            subtitle: 'Clean Light Workspace',
            trailing: const StatusPill(label: 'Light', color: AppColors.info),
            onTap: () => _showInfo(
              'Clean Light Workspace theme is active for high contrast.',
            ),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.danger,
            title: 'Sign Out',
            subtitle: 'End your current session and return to login',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: () async {
              await APIClient.removeToken();
              if (!ctx.mounted) return;
              ctx.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    Color iconColor = AppColors.primary,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  // Configure the API key via backend
  Future<void> _configureApiKey() async {
    setState(() => _isConfiguring = true);

    try {
      // Validate that a key was entered
      if (_apiKey.trim().isEmpty) {
        setState(() {
          _apiKeyStatusMessage = 'Please enter an API key';
          _apiKeyConfigured = false;
          _apiKeyValid = false;
        });
        _showInfo('Please enter an API key');
        return;
      }

      // Call the backend to configure the key
      final result = await APIClient.configureApiKey(
        apiKey: _apiKey.trim(),
        validate: true,
      );

      if (!mounted) return;
      setState(() {
        _isConfiguring = false;
      });

      if (result['success'] ?? false) {
        setState(() {
          _apiKeyConfigured = result['configured'] ?? false;
          _apiKeyValid = result['valid'] ?? false;
          _apiProvider = result['provider'] ?? 'gemini';
          _apiKeyStatusMessage = result['message'] ?? 'API key configured';
          _apiKey = ''; // Clear the input field after successful save
        });
        _showInfo(_apiKeyStatusMessage ?? 'API key configured successfully');
      } else {
        setState(() {
          _apiKeyConfigured = false;
          _apiKeyValid = false;
          _apiKeyStatusMessage = result['detail'] ?? 'Unknown error';
        });
        _showInfo(_apiKeyStatusMessage ?? 'Failed to configure API key');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfiguring = false);
      setState(() {
        _apiKeyConfigured = false;
        _apiKeyValid = false;
        _apiKeyStatusMessage = 'Error configuring API key: $e';
      });
      _showInfo('Error configuring API key: $e');
    }
  }
}