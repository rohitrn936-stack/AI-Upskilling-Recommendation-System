import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/services/api_client.dart';
import 'package:upskilling/widgets/app_bar.dart';
import 'package:upskilling/widgets/app_theme.dart';
import 'package:upskilling/widgets/loading_indicator.dart';

class PersonalizedSkillSuggestionsScreen extends StatefulWidget {
  const PersonalizedSkillSuggestionsScreen({super.key});

  @override
  State<PersonalizedSkillSuggestionsScreen> createState() =>
      _PersonalizedSkillSuggestionsScreenState();
}

class _PersonalizedSkillSuggestionsScreenState
    extends State<PersonalizedSkillSuggestionsScreen> {
  bool _isLoading = true;
  bool _initialized = false;
  bool _demoMode = false;
  String? _error;

  String _targetCareer = 'Software Engineer';
  List<String> _existingSkills = [];
  List<String> _missingSkills = [];
  String _learningGoals = '';
  List<dynamic> _suggestions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (args != null) {
        if (args['targetCareer'] != null &&
            args['targetCareer'].toString().isNotEmpty) {
          _targetCareer = args['targetCareer'].toString();
        }
        if (args['existingSkills'] is List) {
          _existingSkills =
              (args['existingSkills'] as List).map((e) => e.toString()).toList();
        }
        if (args['missingSkills'] is List) {
          _missingSkills =
              (args['missingSkills'] as List).map((e) => e.toString()).toList();
        }
        if (args['learningGoals'] != null) {
          _learningGoals = args['learningGoals'].toString();
        }
      }
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_existingSkills.isEmpty || _learningGoals.isEmpty) {
        final results = await Future.wait([
          APIClient.getSkills(),
          APIClient.getProfile(),
        ]);
        final rawSkills = results[0] as List<dynamic>;
        final profile =
            (results[1] as Map<String, dynamic>)['data'] as Map<String, dynamic>? ??
                {};

        if (_existingSkills.isEmpty) {
          _existingSkills = rawSkills
              .map((s) => (s['skill_name'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        if (_learningGoals.isEmpty) {
          _learningGoals = (profile['learning_goals'] ?? '').toString();
        }
      }

      final response = await APIClient.getPersonalizedSkills(
        existingSkills: _existingSkills,
        targetCareer: _targetCareer,
        missingSkills: _missingSkills,
        learningGoals: _learningGoals,
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final suggestions = data['suggestions'] as List<dynamic>? ?? [];

      if (!mounted) return;
      setState(() {
        _demoMode = data['demo_mode'] == true;
        _suggestions = suggestions;
      });
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

  @override
  Widget build(BuildContext context) {
    final topSkill = _suggestions.isNotEmpty
        ? (_suggestions.first['skill'] ?? _targetCareer).toString()
        : (_missingSkills.isNotEmpty ? _missingSkills.first : _targetCareer);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Skill Suggestions',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/skill-gap-analysis'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Suggestions',
            onPressed: _loadSuggestions,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Generating skill suggestions...')
          : _error != null
              ? ErrorMessage(message: _error!, onRetry: _loadSuggestions)
              : PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Recommended Skills for $_targetCareer',
                        subtitle:
                            'Prioritized skills to close your key gaps and build career momentum.',
                        trailing: _demoMode
                            ? const StatusPill(
                                label: 'Demo AI Mode',
                                color: AppColors.primary,
                                icon: Icons.auto_awesome_rounded,
                              )
                            : null,
                      ),
                      const SizedBox(height: 24),
                      if (_suggestions.isEmpty)
                        const AppCard(
                          child: Text('No skill suggestions available yet.'),
                        )
                      else
                        _buildSuggestionCards(),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go(
                              '/learning-resources',
                              extra: {
                                'skillFocus': topSkill,
                                'taskDescription':
                                    'Learn $topSkill for $_targetCareer',
                              },
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            label: const Text('Explore Learning Resources'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/learning-roadmap'),
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Go to Learning Roadmap'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSuggestionCards() {
    const priorityColors = {
      'high': AppColors.primary,
      'medium': AppColors.secondary,
      'low': AppColors.warning,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900 ? 3 : (width >= 580 ? 2 : 1);
        final cardWidth = (width - (16 * (columns - 1))) / columns;

        return Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: _suggestions.map((sug) {
            final skill = (sug['skill'] ?? 'Skill').toString();
            final reason = (sug['reason'] ?? '').toString();
            final priority =
                (sug['priority'] ?? 'medium').toString().toLowerCase();
            final explanation = (sug['explanation'] ?? '').toString();
            final color = priorityColors[priority] ?? AppColors.primary;

            return SizedBox(
              width: cardWidth,
              child: _SkillSuggestionCard(
                skill: skill,
                reason: reason,
                priority: priority.isNotEmpty ? priority : 'medium',
                explanation: explanation,
                color: color,
                onFindResources: () => context.go(
                  '/learning-resources',
                  extra: {
                    'skillFocus': skill,
                    'taskDescription': reason.isNotEmpty
                        ? reason
                        : 'Learn $skill for $_targetCareer',
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SkillSuggestionCard extends StatelessWidget {
  final String skill;
  final String reason;
  final String priority;
  final String explanation;
  final Color color;
  final VoidCallback onFindResources;

  const _SkillSuggestionCard({
    required this.skill,
    required this.reason,
    required this.priority,
    required this.explanation,
    required this.color,
    required this.onFindResources,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPriority =
        priority[0].toUpperCase() + priority.substring(1);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForSkill(skill),
                  color: color,
                  size: 22,
                ),
              ),
              const Spacer(),
              StatusPill(label: '$formattedPriority Priority', color: color),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            skill,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                explanation,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onFindResources,
              icon: const Icon(Icons.menu_book_rounded, size: 16),
              label: const Text('Find Resources'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForSkill(String skill) {
    final lower = skill.toLowerCase();
    if (lower.contains('machine learning') || lower.contains('ml')) {
      return Icons.science_outlined;
    }
    if (lower.contains('python') ||
        lower.contains('javascript') ||
        lower.contains('react') ||
        lower.contains('typescript')) {
      return Icons.code_rounded;
    }
    if (lower.contains('data') || lower.contains('sql')) {
      return Icons.bar_chart_rounded;
    }
    if (lower.contains('docker') ||
        lower.contains('devops') ||
        lower.contains('system')) {
      return Icons.architecture_rounded;
    }
    if (lower.contains('git')) {
      return Icons.folder_outlined;
    }
    return Icons.school_outlined;
  }
}
