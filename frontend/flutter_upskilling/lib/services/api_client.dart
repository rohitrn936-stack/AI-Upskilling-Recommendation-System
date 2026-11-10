import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class APIClient {
  // Base URL for the FastAPI backend
  // Platform-specific configuration:
  //   Android emulator: -DFLUTTER_API_BASE_URL=http://10.0.2.2:8000
  //   iOS simulator:    -DFLUTTER_API_BASE_URL=http://127.0.0.1:8000
  //   macOS desktop:    -DFLUTTER_API_BASE_URL=http://127.0.0.1:8000
  //   Physical device:  set via CI/CD or run flags
  //   Override with: export FLUTTER_API_BASE_URL=<your-host>:8000
  static const String _baseUrl = String.fromEnvironment('FLUTTER_API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

  // JWT token storage key
  static const String _tokenKey = 'jwt_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Map<String, String> buildHeaders({String? token, String contentType = 'application/json'}) {
    final t = token ?? _getCachedToken();
    final Map<String, String> headers = {
      'Content-Type': contentType,
    };
    if (t != null) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  static Future<String?> _getCachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register');
    final response = await http.post(
      uri,
      headers: buildHeaders(contentType: 'application/x-www-form-urlencoded'),
      body: {'email': email, 'username': username, 'password': password},
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: buildHeaders(contentType: 'application/x-www-form-urlencoded'),
      body: {'username': username, 'password': password},
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final uri = Uri.parse('$_baseUrl/api/profile');
    final response = await http.get(
      uri,
      headers: buildHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String institution,
    required String degree,
    required String academicYear,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/profile');
    final body = json.encode({
      'name': name,
      'institution': institution,
      'degree': degree,
      'academic_year': academicYear,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getSkills() async {
    final uri = Uri.parse('$_baseUrl/api/skills');
    final response = await http.get(
      uri,
      headers: buildHeaders(),
    );

    final result = _handleResponse(response);
    return result['skills'] ?? [];
  }

  static Future<Map<String, dynamic>> addSkill({
    required String skillName,
    required String proficiencyLevel,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/skills');
    final body = json.encode({
      'skill_name': skillName,
      'proficiency_level': proficiencyLevel,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCareerRecommendations({
    required List<String> skills,
    required Map<String, String> proficiency,
    required String interests,
    required String academicBackground,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ai/career-recommendations');
    final body = json.encode({
      'skills': skills,
      'proficiency': proficiency,
      'interests': interests,
      'academic_background': academicBackground,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getSkillGapAnalysis({
    required List<dynamic> studentSkills,
    required List<dynamic> requiredSkills,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ai/skill-gap-analysis');
    final body = json.encode({
      'student_skills': studentSkills,
      'required_skills': requiredSkills,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPersonalizedSkills({
    required List<String> existingSkills,
    required String targetCareer,
    required List<String> missingSkills,
    required String learningGoals,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ai/personalized-skills');
    final body = json.encode({
      'existing_skills': existingSkills,
      'target_career': targetCareer,
      'missing_skills': missingSkills,
      'learning_goals': learningGoals,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> generateRoadmap({
    required List<dynamic> studentSkills,
    required List<dynamic> careerRequirements,
    required String interests,
    required String academicBackground,
    required String learningGoals,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ai/roadmap-generate');
    final body = json.encode({
      'student_skills': studentSkills,
      'career_requirements': careerRequirements,
      'interests': interests,
      'academic_background': academicBackground,
      'learning_goals': learningGoals,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getLearningResources({
    required String taskDescription,
    required String skillFocus,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ai/recommend-resources');
    final body = json.encode({
      'task_description': taskDescription,
      'skill_focus': skillFocus,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    final result = _handleResponse(response);
    return result['resources'] ?? [];
  }

  static Future<Map<String, dynamic>> updateTaskProgress({
    required String taskId,
    required String status,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/progress/$taskId');
    final body = json.encode({
      'status': status,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      removeToken().then((_) {
        // Could trigger logout callback
      });
      throw Exception('Unauthorized - please login again');
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['detail'] ?? 'Request failed');
    }
  }
}