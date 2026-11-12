import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class LearningResourcesScreen extends StatefulWidget {
  const LearningResourcesScreen({super.key});

  @override
  State<LearningResourcesScreen> createState() =>
      _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  final _topicController = TextEditingController();

  bool _isLoading = true;
  bool _initialized = false;
  String? _error;
  String _selectedType = 'mixed';
  String _taskDescription = '';
  List<dynamic> _resources = [];

  static const _quickTopics = [
    'Python',
    'SQL',
    'Data Structures',
    'System Design',
    'Machine Learning',
    'Docker',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (args != null) {
        if (args['skillFocus'] != null) {
          _topicController.text = args['skillFocus'].toString();
        }
        if (args['taskDescription'] != null) {
          _taskDescription = args['taskDescription'].toString();
        }
      }
      _initAndFetch();
    }
  }

  Future<void> _initAndFetch() async {
    if (_topicController.text.trim().isEmpty) {
      try {
        final skills = await APIClient.getSkills();
        if (skills.isNotEmpty) {
          final firstSkill = (skills.first['skill_name'] ?? '').toString();
          if (firstSkill.isNotEmpty) {
            _topicController.text = firstSkill;
          }
        }
      } catch (e) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.toLowerCase().contains('unauthorized')) {
          if (mounted) context.go('/login');
          return;
        }
      }
      if (_topicController.text.trim().isEmpty) {
        _topicController.text = 'Python';
      }
    }

    await _fetchResources();
  }

  Future<void> _fetchResources() async {
    final topic = _topicController.text.trim().isNotEmpty
        ? _topicController.text.trim()
        : 'Python';

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resources = await APIClient.getLearningResources(
        taskDescription:
            _taskDescription.isNotEmpty ? _taskDescription : 'Learn $topic',
        skillFocus: topic,
        resourceType: _selectedType,
      );
      if (!mounted) return;
      setState(() => _resources = resources);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('unauthorized')) {
        if (mounted) context.go('/login');
        return;
      }
      if (!mounted) return;
      setState(() => _error = msg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupResources() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final raw in _resources) {
      if (raw is! Map<String, dynamic>) continue;
      final typeRaw = (raw['resource_type'] ?? 'Course').toString().trim();
      final key = _categoryTitle(typeRaw);
      grouped.putIfAbsent(key, () => []).add(raw);
    }
    return grouped;
  }

  String _categoryTitle(String resourceType) {
    final lower = resourceType.toLowerCase();
    if (lower.contains('course') || lower.contains('video')) {
      return 'Courses & Videos';
    }
    if (lower.contains('article') || lower.contains('doc')) {
      return 'Articles & Guides';
    }
    if (lower.contains('tutorial')) {
      return 'Interactive Tutorials';
    }
    if (lower.contains('book')) {
      return 'Books';
    }
    return 'Recommended Resources';
  }

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resource URL copied to clipboard'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupResources();

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Learning Resources',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Resources',
            onPressed: _fetchResources,
          ),
        ],
      ),
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Recommended Learning Resources',
              subtitle:
                  'Search curated courses, articles, videos, and books tailored to any skill.',
            ),
            const SizedBox(height: 20),
            _buildSearchCard(),
            const SizedBox(height: 24),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child:
                    LoadingIndicator(message: 'Finding learning resources...'),
              )
            else if (_error != null)
              ErrorMessage(message: _error!, onRetry: _fetchResources)
            else if (grouped.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No matching resources found',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Try searching a broader topic or switching Type to All Types.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _selectedType = 'mixed');
                        _fetchResources();
                      },
                      child: const Text('Show All Types'),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final cardWidth = isWide
                      ? (constraints.maxWidth - 20) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: grouped.entries
                        .map(
                          (entry) => SizedBox(
                            width: cardWidth,
                            child: _ResourceCategoryCard(
                              category: entry.key,
                              resources: entry.value,
                              onCopyUrl: _copyUrl,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              final topicField = TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Skill or Topic (e.g., Python, ML, SQL)',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (_) {
                  _taskDescription = '';
                  _fetchResources();
                },
              );

              final typeField = DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Format',
                ),
                items: const [
                  DropdownMenuItem(value: 'mixed', child: Text('All Types')),
                  DropdownMenuItem(value: 'course', child: Text('Course')),
                  DropdownMenuItem(value: 'article', child: Text('Article')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'book', child: Text('Book')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              );

              final searchButton = SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _taskDescription = '';
                          _fetchResources();
                        },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Find Resources'),
                ),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: topicField),
                    const SizedBox(width: 12),
                    SizedBox(width: 170, child: typeField),
                    const SizedBox(width: 12),
                    searchButton,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  topicField,
                  const SizedBox(height: 12),
                  typeField,
                  const SizedBox(height: 12),
                  searchButton,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Popular:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              ..._quickTopics.map((topic) {
                return ActionChip(
                  label: Text(topic),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _topicController.text = topic;
                          _taskDescription = '';
                          _fetchResources();
                        },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceCategoryCard extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> resources;
  final Future<void> Function(String url) onCopyUrl;

  const _ResourceCategoryCard({
    required this.category,
    required this.resources,
    required this.onCopyUrl,
  });

  (IconData, Color) _categoryVisuals() {
    if (category.contains('Course')) {
      return (Icons.play_circle_outline_rounded, AppColors.primary);
    }
    if (category.contains('Article')) {
      return (Icons.article_outlined, AppColors.info);
    }
    if (category.contains('Tutorial')) {
      return (Icons.terminal_rounded, AppColors.warning);
    }
    if (category.contains('Book')) {
      return (Icons.menu_book_rounded, AppColors.success);
    }
    return (Icons.auto_stories_outlined, AppColors.secondary);
  }

  @override
  Widget build(BuildContext context) {
    final visuals = _categoryVisuals();
    final catIcon = visuals.$1;
    final catColor = visuals.$2;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(catIcon, size: 20, color: catColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusPill(label: '${resources.length}', color: catColor),
            ],
          ),
          const SizedBox(height: 16),
          ...resources.map((res) {
            final name =
                (res['resource_name'] ?? res['name'] ?? 'Learning Resource')
                    .toString();
            final platform = (res['platform'] ?? 'Online').toString();
            final type =
                (res['resource_type'] ?? res['type'] ?? 'Course').toString();
            final duration = (res['estimated_learning_duration'] ??
                    res['duration'] ??
                    'Self-paced')
                .toString();
            final description = (res['description'] ?? '').toString();
            final url = (res['url'] ?? '').toString();

            return _ResourceItem(
              resourceName: name,
              platform: platform,
              resourceType: type,
              estimatedDuration: duration,
              description: description,
              url: url,
              onCopyUrl: url.isNotEmpty ? () => onCopyUrl(url) : null,
            );
          }),
        ],
      ),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final String resourceName;
  final String platform;
  final String resourceType;
  final String estimatedDuration;
  final String description;
  final String url;
  final VoidCallback? onCopyUrl;

  const _ResourceItem({
    required this.resourceName,
    required this.platform,
    required this.resourceType,
    required this.estimatedDuration,
    required this.description,
    required this.url,
    this.onCopyUrl,
  });

  Color _typeColor() {
    final lowerType = resourceType.toLowerCase();
    if (lowerType.contains('article')) return AppColors.info;
    if (lowerType.contains('book')) return AppColors.success;
    if (lowerType.contains('tutorial')) return AppColors.warning;
    if (lowerType.contains('video')) return AppColors.secondary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  resourceName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: resourceType, color: typeColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$platform • Est. $estimatedDuration',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (url.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      url,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  if (onCopyUrl != null)
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      color: AppColors.textSecondary,
                      tooltip: 'Copy URL',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: onCopyUrl,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
