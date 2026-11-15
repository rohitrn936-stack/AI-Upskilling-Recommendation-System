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

  Future<void> _showProviderSelectionDialog() async {
    String tempProvider = _aiProvider;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text(
                'Select AI Provider',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select the active AI engine for career recommendations, skill gap analysis, and roadmap generation.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (_statusMessage.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Backend status: $_statusMessage',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildProviderSelectionTile(
                  id: 'gemini',
                  name: 'Google Gemini',
                  subtitle: 'Google Cloud Gemini generative models',
                  icon: Icons.auto_awesome_rounded,
                  current: tempProvider,
                  onSelect: () => setDialogState(() => tempProvider = 'gemini'),
                ),
                const SizedBox(height: 8),
                _buildProviderSelectionTile(
                  id: 'ollama',
                  name: 'Ollama (Local LLM)',
                  subtitle: 'Self-hosted LLMs running on localhost:11434',
                  icon: Icons.memory_rounded,
                  current: tempProvider,
                  onSelect: () => setDialogState(() => tempProvider = 'ollama'),
                ),
                const SizedBox(height: 8),
                _buildProviderSelectionTile(
                  id: 'compatible',
                  name: 'OpenAI-Compatible',
                  subtitle: 'OpenAI-compatible inference endpoint',
                  icon: Icons.hub_outlined,
                  current: tempProvider,
                  onSelect: () => setDialogState(() => tempProvider = 'compatible'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(tempProvider),
              child: const Text('Apply Selection'),
            ),
          ],
        ),
      ),
    );

    if (selected != null && selected != _aiProvider) {
      setState(() => _aiProvider = selected);
      _showInfo('Selected AI Provider: ${selected.toUpperCase()}');
    }
  }

  Widget _buildProviderSelectionTile({
    required String id,
    required String name,
    required String subtitle,
    required IconData icon,
    required String current,
    required VoidCallback onSelect,
  }) {
    final isSelected = id == current;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 6 : 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
            ),
          ],
        ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusPill(
                  label: providerLabel,
                  color: _demoMode ? AppColors.primary : AppColors.success,
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            onTap: _showProviderSelectionDialog,
          ),
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
          _buildSettingTile(
            icon: Icons.smart_toy_outlined,
            title: 'Active Model',
            subtitle: _aiModel,
            onTap: () => _showInfo('Active backend AI model: $_aiModel'),
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
