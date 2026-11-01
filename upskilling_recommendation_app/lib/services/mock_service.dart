import 'dart:async';

import 'models/skill.dart';
import 'models/career.dart';
import 'models/student_profile.dart';
import 'models/course.dart';
import 'models/learning_plan_item.dart';
import 'api_service_interface.dart';

class MockService implements ApiService {
  StudentProfile? _profile;
  List<Career> _careers = [];
  List<Skill> _currentSkills = [];
  LearningPlanItem? _learningPlan;
  Career? _selectedCareer;

  MockService() {
    _initializeMockCareers();
    _profile = StudentProfile.mock();
  }

  void _initializeMockCareers() {
    _careers = [
      Career.mock(title: 'Data Analyst'),
      Career.mock(title: 'Web Developer'),
      Career.mock(title: 'UX Designer'),
      Career.mock(title: 'Cybersecurity Analyst'),
    ];
  }

  @override
  Future<StudentProfile> fetchStudentProfile() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _profile ?? StudentProfile.guest;
  }

  @override
  Future<void> saveSkills(List<Skill> skills) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentSkills = skills;
  }

  @override
  Future<List<Career>> requestCareerRecommendations({
    required List<Skill> currentSkills,
    required Career selectedCareer,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _selectedCareer = selectedCareer;
    return List.from(_careers);
  }

  @override
  Future<List<LearningPlanItem>> generateLearningPlan({
    required Career selectedCareer,
    required List<Skill> currentSkills,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final currentSkillNames =
        currentSkills.map((s) => s.name.toLowerCase()).toSet();
    final missingSkills = _getMissingSkills(selectedCareer, currentSkillNames);

    final items = missingSkills.asMap().entries.map((entry) {
      final idx = entry.key;
      final skillName = entry.value;
      final isBeginner = currentSkills.isEmpty;
      final priority = idx < 3 ? 'high' : idx < 6 ? 'medium' : 'low';
      final courses = _generateCourses(skillName, isBeginner);
      final initialStatus = isBeginner ? 'planned' : 'completed';

      return LearningPlanItem.mock(
        skillName: skillName,
        whyItMatters: _whyItMatters(skillName, selectedCareer.title),
        courses: courses,
        priority: priority,
        status: initialStatus,
      );
    }).toList();

    _learningPlan = items;
    return items;
  }

  List<String> _getMissingSkills(Career career, Set<String> currentSkillNames) {
    final required = career.requiredSkills;
    return required.where((r) => !currentSkillNames.any((n) => n == r)).toList();
  }

  List<Course> _generateCourses(String skillName, bool isBeginner) {
    final level = isBeginner ? 'beginner' : 'intermediate';
    return [
      Course.mock(
        title: 'Introduction to $skillName',
        provider: 'Coursera',
        duration: '4 weeks',
        level: level,
      ),
      Course.mock(
        title: '$skillName: Practice',
        provider: 'Udemy',
        duration: '6 weeks',
        level: level,
      ),
    ];
  }

  String _whyItMatters(String skillName, String careerTitle) {
    return 'This skill is important for building a strong foundation as a $careerTitle professional.';
  }

  @override
  Future<void> updateProgress({
    required String planItemId,
    required String status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> saveProfile(StudentProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _profile = profile;
  }

  @override
  Future<List<Career>> fetchCareers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_careers);
  }

  @override
  Future<bool> checkHealth() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}