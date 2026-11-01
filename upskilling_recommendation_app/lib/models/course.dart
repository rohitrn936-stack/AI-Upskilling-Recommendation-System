class Course {
  final String id;
  final String title;
  final String provider;
  final String estimatedDuration;
  final String level;
  final String? url;
  final double? rating;

  const Course({
    required this.id,
    required this.title,
    required this.provider,
    required this.estimatedDuration,
    required this.level,
    this.url,
    this.rating,
  });

  factory Course.mock({required String title, required String provider, required String duration, required String level}) {
    return Course(
      id: 'course_${title.toLowerCase().replaceAll(' ', '_')}',
      title: title,
      provider: provider,
      estimatedDuration: duration,
      level: level,
    );
  }
}