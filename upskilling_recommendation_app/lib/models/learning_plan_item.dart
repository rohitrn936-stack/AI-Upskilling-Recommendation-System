class LearningPlanItem {
  final String id;
  final String skillName;
  final String priority;
  final String whyItMatters;
  final List<Course> recommendedCourses;
  final String status; // 'planned', 'in_progress', 'completed'

  const LearningPlanItem({
    required this.id,
    required this.skillName,
    required this.priority,
    required this.whyItMatters,
    required this.recommendedCourses,
    this.status = 'planned',
  });

  factory LearningPlanItem.mock({
    required String skillName,
    required String whyItMatters,
    List<Course>? courses,
    String priority = 'high',
    String status = 'planned',
  }) {
    final defaultCourses = courses ?? [
      Course.mock(
        title: 'Introduction to $skillName',
        provider: 'Coursera',
        duration: '4 weeks',
        level: 'beginner',
      ),
    ];
    return LearningPlanItem(
      id: 'plan_${skillName.toLowerCase().replaceAll(' ', '_')}',
      skillName: skillName,
      priority: priority,
      whyItMatters: whyItMatters,
      recommendedCourses: defaultCourses,
      status: status,
    );
  }
}