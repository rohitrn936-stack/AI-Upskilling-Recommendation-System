import 'package:flutter/material';
import 'package:upskilling_recommendation_app/theme/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double? strokeWidth;
  final Color? color;

  const LoadingIndicator({
    this.message,
    this.strokeWidth = 3,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorValue = color ?? Color(0xFFFFB84D);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth!,
              valueColor: AlwaysStoppedAnimation<Color>(colorValue),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}