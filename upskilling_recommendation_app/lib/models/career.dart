class Career {
  final String id;
  final String title;
  final String description;
  final List<String> requiredSkills;
  final int? skillMatchPercentage;

  const Career({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredSkills,
    this.skillMatchPercentage,
  });

  factory Career.mock({required String title, List<String>? requiredSkills}) {
    final defaults = _defaultRequiredSkills(title);
    return Career(
      id: 'career_${title.toLowerCase().replaceAll(' ', '_')}',
      title: title,
      description: '',
      requiredSkills: requiredSkills ?? defaults,
    );
  }

  static List<String> _defaultRequiredSkills(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('data') || normalized.contains('analyst')) {
      return ['data_analysis', 'sql', 'excel', 'statistics'];
    }
    if (normalized.contains('web') || normalized.contains('developer') || normalized.contains('frontend')) {
      return ['html', 'css', 'javascript', 'react'];
    }
    if (normalized.contains('ux') || normalized.contains('designer')) {
      return ['design_principles', 'color_theory', 'typography', 'figma'];
    }
    if (normalized.contains('cyber') || normalized.contains('security')) {
      return ['network_security', 'encryption', 'risk_assessment', 'compliance'];
    }
    return ['programming', 'problem_solving', 'communication'];
  }
}