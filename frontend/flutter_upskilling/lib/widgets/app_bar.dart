import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onLeading;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.onLeading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0,
      backgroundColor: const Color(0xFF6750A4),
      foregroundColor: Colors.white,
      actions: actions,
      leading: leading ??
          (onLeading != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onLeading,
                )
              : null),
    );
  }

  @override
  Size get preferredSize => const Size(36.0, kToolbarHeight);
}