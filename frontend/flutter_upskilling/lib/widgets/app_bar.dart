import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/widgets/app_theme.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onLeading;
  final bool showNavLinks;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.onLeading,
    this.showNavLinks = true,
  });

  static const _navItems = [
    ('/dashboard', 'Dashboard'),
    ('/skill-management', 'Skills'),
    ('/career-recommendations', 'Careers'),
    ('/skill-gap-analysis', 'Skill Gap'),
    ('/learning-roadmap', 'Roadmap'),
    ('/learning-resources', 'Resources'),
    ('/progress-tracking', 'Progress'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final screenWidth = MediaQuery.of(context).size.width;
    final showDesktopLinks = showNavLinks && screenWidth >= 980;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: leading ??
            (onLeading != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: onLeading,
                  )
                : (currentPath != '/dashboard'
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Back to Dashboard',
                        onPressed: () => context.go('/dashboard'),
                      )
                    : null)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (showDesktopLinks) ...[
              const SizedBox(width: 24),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _navItems.map((item) {
                      final path = item.$1;
                      final label = item.$2;
                      final active = currentPath == path ||
                          (path == '/career-recommendations' &&
                              currentPath == '/career-details') ||
                          (path == '/learning-roadmap' &&
                              currentPath == '/roadmap-task-details');
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: TextButton(
                          onPressed: () => context.go(path),
                          style: TextButton.styleFrom(
                            foregroundColor: active
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            backgroundColor: active
                                ? AppColors.primaryLight
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ...?actions,
          if (!showDesktopLinks && showNavLinks && currentPath != '/dashboard')
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Dashboard',
              onPressed: () => context.go('/dashboard'),
            ),
          if (showNavLinks && currentPath != '/profile')
            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              tooltip: 'Profile',
              onPressed: () => context.go('/profile'),
            ),
          if (showNavLinks && currentPath != '/settings')
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.go('/settings'),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(62);
}
