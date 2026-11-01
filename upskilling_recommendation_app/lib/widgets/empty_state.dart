import 'package:flutter/material';
import 'package:upskilling_recommendation_app/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? action;
  final Color? accentColor;
  final bool hasButton;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    required this.title,
    required this.subtitle,
    this.icon,
    this.action,
    this.accentColor,
    this.hasButton = false,
    this.onButtonPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = accentColor ?? Color(0xFFFFB84D);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.grass,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Color(0xFF94A3B8) : Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasButton && onButtonPressed != null) ...[
              PrimaryButton(
                label: 'Get Started',
                onPressed: onButtonPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}