abstract class ApiService {
  static const String baseUrl = '{baseUrl}placeholder';

  Future<StudentProfile> fetchStudentProfile();
  Future<void> saveSkills(List<Skill> skills);
  Future<List<Career>> requestCareerRecommendations({
    required List<Skill> currentSkills,
    required Career selectedCareer,
  });
  Future<List<LearningPlanItem>> generateLearningPlan({
    required Career selectedCareer,
    required List<Skill> currentSkills,
  });
  Future<void> updateProgress({
    required String planItemId,
    required String status,
  });
  Future<void> saveProfile(StudentProfile profile);
  Future<List<Career>> fetchCareers();
  Future<bool> checkHealth();
}