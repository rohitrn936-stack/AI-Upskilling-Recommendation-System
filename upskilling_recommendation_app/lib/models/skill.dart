class Skill {
  final String id;
  final String name;
  final String? proficiencyLevel;

  const Skill({
    required this.id,
    required this.name,
    this.proficiencyLevel,
  });

  factory Skill.mock({required String name, String? proficiencyLevel}) {
    return Skill(
      id: 'skill_${name.toLowerCase().replaceAll(' ', '_')}',
      name: name,
      proficiencyLevel: proficiencyLevel,
    );
  }
}