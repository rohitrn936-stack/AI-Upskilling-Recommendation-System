import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pushNamed('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Application Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 30),
            _buildApiSettings(context),
            const Divider(height: 32),
            _buildGeneralSettings(context),
          ],
        ),
      ),
    );
  }

  Widget _buildApiSettings(BuildContext ctx) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              ctx: ctx,
              icon: Icons.flash_on,
              title: 'AI Provider',
              subtitle: 'Gemini (configured)',
              onTap: () {
                // TODO: Open AI provider selection
              },
            ),
            _buildSettingTile(
              ctx: ctx,
              icon: Icons.key,
              title: 'API Key',
              subtitle: 'Not configured (demo mode)',
              onTap: () {
                // TODO: Open API key configuration
              },
            ),
            _buildSettingTile(
              ctx: ctx,
              icon: Icons.smart_toy,
              title: 'Model',
              subtitle: 'gemini-pro',
              onTap: () {
                // TODO: Change model selection
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext ctx) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              ctx: ctx,
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'System default',
              trailing: const Icon(Icons.check_circle, color: Color(0xFF00C853)),
              onTap: () {
                // TODO: Toggle dark mode
              },
            ),
            _buildSettingTile(
              ctx: ctx,
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Enabled',
              trailing: const Icon(Icons.check_circle, color: Color(0xFF00C853)),
              onTap: () {
                // TODO: Toggle notifications
              },
            ),
            _buildSettingTile(
              ctx: ctx,
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of account',
              trailing: const Icon(Icons.arrow_forward, color: Colors.grey),
              onTap: () {
                ctx.pushNamed('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF6750A4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Color(0xFF6750A4), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}