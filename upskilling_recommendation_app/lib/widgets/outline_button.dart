import 'package:flutter/material';
import 'package:upskilling_recommendation_app/theme/app_theme.dart';

class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const OutlineButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Color(0xFF60A5FA) : Color(0xFF3B82F6);

    return OutlinedButton.onPressed(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}