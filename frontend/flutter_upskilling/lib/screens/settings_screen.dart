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
  bool _hasSavedSelection = false;
  String _environment = 'development';
  String _backendStatus = 'healthy';
  String _statusMessage = '';

  static const Map<String, List<String>> _aiModelsByProvider = {
    'gemini': ['gemini-pro', 'gemini-1.5-pro', 'gemini-1.5-flash'],
    'ollama': ['llama3', 'mistral', 'codellama'],
    'compatible': ['gpt-3.5-turbo', 'gpt-4', 'claude-3-haiku'],
  };

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
      // Load saved selection first, fall back to backend-reported config
      final savedProvider = await APIClient.getSavedAiProvider();
      final savedModel = await APIClient.getSavedAiModel();
      final hasSaved = savedProvider != null && savedModel != null;

      final results = await Future.wait([
        APIClient.getDemoMode(),
        APIClient.getHealth(),
      ]);

      final demoData = results[0];
      final healthData = results[1];

      if (!mounted) return;
      setState(() {
        _demoMode = demoData['demo_mode'] == true;
        if (hasSaved) {
          _aiProvider = savedProvider;
          _aiModel = savedModel;
          _hasSavedSelection = true;
        } else {
          _aiProvider = (demoData['ai_provider'] ??
                  healthData['ai_provider'] ??
                  'gemini')
              .toString();
          _aiModel = (demoData['ai_model'] ?? 'gemini-pro').toString();
          _hasSavedSelection = false;
        }
        _statusMessage = (demoData['message'] ?? '').toString();
        _environment =
            (healthData['environment'] ?? 'development').toString();
        _backendStatus = (healthData['status'] ?? 'healthy').toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          _buildAiProviderDropdown(),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.vpn_key_outlined,
            title: 'AI API Key Status',
            subtitle: modeSubtitle,
            onTap: () => _showInfo(
              'Set AI_API_KEY in backend/.env and restart the backend server to enable live LLM generation.',
            ),
          ),
          const Divider(height: 1),
          _buildAiModelDropdown(),
        ],
      ),
    );
  }

  Widget _buildAiProviderDropdown() {
    final providerLabel = _aiProvider.toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Provider',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _aiProvider,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
              DropdownMenuItem(value: 'ollama', child: Text('Ollama')),
              DropdownMenuItem(
                  value: 'compatible', child: Text('Compatible')),
            ],
            onChanged: (value) async {
              if (value == null) return;
              await APIClient.saveAiProvider(value);
              final models = _aiModelsByProvider[value] ?? [];
              final newModel = models.isNotEmpty ? models.first : _aiModel;
              await APIClient.saveAiModel(newModel);
              if (!mounted) return;
              setState(() {
                _aiProvider = value;
                _aiModel = newModel;
                _hasSavedSelection = true;
              });
            },
          ),
          const SizedBox(height: 6),
          Text(
            '$providerLabel ${_demoMode ? '(demo mode)' : '(configured)'}. Saved to device.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiModelDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Model',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('model_dropdown_$_aiProvider'),
            initialValue: _aiModel,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            items: _aiModelsByProvider[_aiProvider]!
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (value) async {
              if (value == null) return;
              await APIClient.saveAiModel(value);
              if (!mounted) return;
              setState(() {
                _aiModel = value;
                _hasSavedSelection = true;
              });
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Active model: $_aiModel${_hasSavedSelection ? ' (saved)' : ' (from backend)'}.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
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
}
