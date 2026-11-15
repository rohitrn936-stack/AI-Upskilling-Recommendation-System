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

  static const List<SupportedAIProvider> _supportedProviders = [
    SupportedAIProvider(
      id: 'gemini',
      name: 'Google Gemini',
      badge: 'Cloud AI',
      description: 'Google Cloud Gemini generative models (gemini-3-flash-preview)',
      defaultModel: 'gemini-3-flash-preview',
      icon: Icons.auto_awesome_rounded,
      requiresApiKey: true,
      requiresBaseUrl: false,
    ),
    SupportedAIProvider(
      id: 'ollama',
      name: 'Ollama',
      badge: 'Local & Private',
      description: 'Self-hosted LLMs running on localhost:11434 (llama3.2, mistral)',
      defaultModel: 'llama3.2',
      icon: Icons.memory_rounded,
      requiresApiKey: false,
      requiresBaseUrl: true,
    ),
    SupportedAIProvider(
      id: 'compatible',
      name: 'OpenAI-Compatible',
      badge: 'Universal API',
      description: 'OpenAI-compatible inference REST API (Groq, Together, vLLM)',
      defaultModel: 'gpt-4o-mini',
      icon: Icons.hub_outlined,
      requiresApiKey: true,
      requiresBaseUrl: true,
    ),
  ];

  SupportedAIProvider get _activeProvider {
    return _supportedProviders.firstWhere(
      (p) => p.id.toLowerCase() == _aiProvider.toLowerCase(),
      orElse: () => SupportedAIProvider(
        id: _aiProvider,
        name: _aiProvider.isEmpty ? 'Google Gemini' : _aiProvider.toUpperCase(),
        badge: 'Active',
        description: 'Active provider configured on backend',
        defaultModel: _aiModel,
        icon: Icons.auto_awesome_rounded,
        requiresApiKey: true,
        requiresBaseUrl: false,
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
                'Supported AI Providers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Currently Active: ${_activeProvider.name} (${_activeProvider.badge})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select from the supported AI providers below. Each provider supports distinct models and runtime environments:',
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
                ..._supportedProviders.map((provider) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildProviderSelectionTile(
                      provider: provider,
                      current: tempProvider,
                      isActive: provider.id.toLowerCase() == _aiProvider.toLowerCase(),
                      onSelect: () => setDialogState(() => tempProvider = provider.id),
                    ),
                  );
                }),
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
      setState(() => _isLoading = true);
      try {
        final res = await APIClient.setAiProvider(selected);
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final updatedProvider = (data['ai_provider'] ?? selected).toString();
        final msg = (data['message'] ??
                'AI provider updated to ${updatedProvider.toUpperCase()}')
            .toString();

        await _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
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
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildProviderSelectionTile({
    required SupportedAIProvider provider,
    required String current,
    required bool isActive,
    required VoidCallback onSelect,
  }) {
    final isSelected = provider.id == current;
    final badgeColor = provider.id == 'gemini'
        ? AppColors.primary
        : provider.id == 'ollama'
            ? AppColors.success
            : AppColors.secondary;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                provider.icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        provider.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        label: provider.badge,
                        color: badgeColor,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        const StatusPill(
                          label: 'ACTIVE',
                          color: AppColors.success,
                          icon: Icons.check_circle_rounded,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Default: ${provider.defaultModel}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      Text(
                        provider.requiresApiKey ? 'Requires API Key' : 'No Key Required',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: provider.requiresApiKey ? AppColors.info : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
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
    final active = _activeProvider;
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
          const SizedBox(height: 16),
          // Active AI Provider Highlight Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        active.icon,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                active.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const StatusPill(
                                label: 'ACTIVE',
                                color: AppColors.success,
                                icon: Icons.check_circle_rounded,
                              ),
                              const SizedBox(width: 6),
                              StatusPill(
                                label: active.badge,
                                color: active.id == 'gemini'
                                    ? AppColors.primary
                                    : active.id == 'ollama'
                                        ? AppColors.success
                                        : AppColors.secondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            active.description,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _showProviderSelectionDialog,
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Change Provider'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.smart_toy_outlined,
                            size: 15,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active Model: $_aiModel',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            active.requiresApiKey
                                ? Icons.vpn_key_outlined
                                : Icons.lock_open_rounded,
                            size: 15,
                            color: active.requiresApiKey && _demoMode
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            active.requiresApiKey
                                ? (_demoMode
                                    ? 'Key Required (Demo Mode)'
                                    : 'Key Configured')
                                : 'No API Key Required',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: active.requiresApiKey && _demoMode
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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

class SupportedAIProvider {
  final String id;
  final String name;
  final String badge;
  final String description;
  final String defaultModel;
  final IconData icon;
  final bool requiresApiKey;
  final bool requiresBaseUrl;

  const SupportedAIProvider({
    required this.id,
    required this.name,
    required this.badge,
    required this.description,
    required this.defaultModel,
    required this.icon,
    this.requiresApiKey = false,
    this.requiresBaseUrl = false,
  });
}
