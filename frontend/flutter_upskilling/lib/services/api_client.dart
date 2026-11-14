import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class APIClient {
  // Base URL for the FastAPI backend
  // Platform-specific configuration:
  //   Android emulator: -DFLUTTER_API_BASE_URL=http://10.0.2.2:8000
  //   Web / Desktop:    http://127.0.0.1:8000 (default when running on Web)
  //   Physical device:  set via --dart-define=FLUTTER_API_BASE_URL=http://<host>:8000
  static String get _baseUrl {
    const configured = String.fromEnvironment('FLUTTER_API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
  }

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

  // buildHeaders constructs authorization headers using the token.
  // If [token] is provided, it uses that; otherwise it reads from SharedPreferences.
  static Future<Map<String, String>> buildHeaders({String? token, String contentType = 'application/json'}) async {
    final t = token ?? await _getCachedToken();
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

  // --- Auth endpoints ---

  static Future<Map<String, dynamic>> register({required String email, required String username, required String password}) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register');
    final response = await http.post(
      uri,
      headers: await buildHeaders(contentType: 'application/x-www-form-urlencoded'),
      body: {'email': email, 'username': username, 'password': password},
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({required String username, required String password}) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: await buildHeaders(contentType: 'application/x-www-form-urlencoded'),
      body: {'username': username, 'password': password},
    );

    return _handleResponse(response);
  }

  // --- Profile endpoints ---

  static Future<Map<String, dynamic>> getProfile() async {
    final uri = Uri.parse('$_baseUrl/api/profile');
    final response = await http.get(
      uri,
      headers: await buildHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String institution,
    required String degree,
    required String academicYear,
    String? interests,
    String? learningGoals,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/profile');
    final Map<String, dynamic> payload = {
      'name': name,
      'institution': institution,
      'degree': degree,
      'academic_year': academicYear,
    };
    if (interests != null) payload['interests'] = interests;
    if (learningGoals != null) payload['learning_goals'] = learningGoals;
    final body = json.encode(payload);

    final response = await http.post(
      uri,
      headers: await buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  // --- Skills endpoints ---

  static Future<List<dynamic>> getSkills() async {
    final uri = Uri.parse('$_baseUrl/api/skills');
    final response = await http.get(
      uri,
      headers: await buildHeaders(),
    );

    final result = _handleResponse(response);
    // Backend returns: {"success": true, "data": {"skills": skill_list}}
    return result['data']['skills'] ?? [];
  }

  static Future<Map<String, dynamic>> addSkill({
    required String skillName,
    required String proficiencyLevel,
    String category = '',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/skills');
    final body = json.encode({
      'skill_name': skillName,
      'proficiency_level': proficiencyLevel,
      'category': category,
    });

    final response = await http.post(
      uri,
      headers: await buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteSkill(int skillId) async {
    final uri = Uri.parse('$_baseUrl/api/skills/$skillId');
    final response = await http.delete(
      uri,
      headers: await buildHeaders(),
    );

    return _handleResponse(response);
  }

  // --- AI endpoints ---

  static Future<Map<String, dynamic>> getCareerRecommendations({required List<String> skills, required Map<String, String> proficiency, required String interests, required String academicBackground}) async {
    final uri = Uri.parse('$_baseUrl/api/ai/career-recommendations');
    final body = json.encode({
      'skills': skills,
      'proficiency': proficiency,
      'interests': interests,
      'academic_background': academicBackground,
    });

    final response = await http.post(
      uri,
      headers: await buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getSkillGapAnalysis({required List<dynamic> studentSkills, required List<dynamic> requiredSkills}) async {
    final uri = Uri.parse('$_baseUrl/api/ai/skill-gap-analysis');
    final body = json.encode({
      'student_skills': studentSkills,
      'required_skills': requiredSkills,
    });

    final response = await http.post(
      uri,
      headers: await buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPersonalizedSkills({required List<String> existingSkills, required String targetCareer, required List<String> missingSkills, required String learningGoals}) async {
    final uri = Uri.parse('$_baseUrl/api/ai/personalized-skills');
    final body = json.encode({
      'existing_skills': existingSkills,
      'target_career': targetCareer,
      'missing_skills': missingSkills,
      'learning_goals': learningGoals,
    });

    final response = await http.post(
      uri,
      headers: await buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> generateRoadmap({required List<dynamic> studentSkills, required List<dynamic> careerRequirements, required String interests, required String academicBackground, required String learningGoals}) async {
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
      headers: await buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  // --- Learning resources ---

  static Future<List<dynamic>> getLearningResources({
    required String taskDescription,
    required String skillFocus,
    String resourceType = 'mixed',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ai/recommend-resources');
    final body = json.encode({
      'task_description': taskDescription,
      'skill_focus': skillFocus,
      'resource_type': resourceType,
    });

    final response = await http.post(
      uri,
      headers: await buildHeaders(),
      body: body,
    );

    final result = _handleResponse(response);
    return result['data']['resources'] ?? [];
  }

  // --- Saved roadmap & progress ---

  static Future<Map<String, dynamic>> getRoadmap() async {
    final uri = Uri.parse('$_baseUrl/api/roadmap');
    final response = await http.get(
      uri,
      headers: await buildHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProgress() async {
    final uri = Uri.parse('$_baseUrl/api/progress');
    final response = await http.get(
      uri,
      headers: await buildHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getDemoMode() async {
    final uri = Uri.parse('$_baseUrl/api/demo-mode');
    final response = await http.get(
      uri,
      headers: await buildHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getHealth() async {
    final uri = Uri.parse('$_baseUrl/health');
    final response = await http.get(
      uri,
      headers: await buildHeaders(),
    );

    return _handleResponse(response);
  }

  // --- Task progress ---

  static Future<Map<String, dynamic>> updateTaskProgress({required String taskId, required String status}) async {
    final uri = Uri.parse('$_baseUrl/api/progress/$taskId');
    final body = json.encode({
      'status': status,
    });

    final response = await http.post(
      uri,
      headers: await buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  /// Comprehensive HTTP response handler supporting all status codes:
  /// 200, 201, 202 - successful responses (decode JSON body)
  /// 204 - No Content (return empty map, no JSON decoding)
  /// 400 - Bad Request (parse validation errors)
  /// 401 - Unauthorized (clear token, throw auth error)
  /// 403 - Forbidden (parse error detail)
  /// 404 - Not Found (parse error detail)
  /// 409 - Conflict (parse error detail, e.g., duplicate resource)
  /// 422 - Unprocessable Entity (parse validation errors)
  /// 500 - Internal Server Error (parse detail or generic message)
  /// Invalid JSON - throw descriptive error
  /// Empty response body - handle gracefully
  /// Network errors / timeouts - propagate as appropriate
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // 2xx success responses
    if (statusCode == 200 || statusCode == 201 || statusCode == 202) {
      try {
        return json.decode(response.body);
      } catch (_) {
        // If body is not valid JSON, return empty map
        return {};
      }
    }

    // 204 No Content - successful but no body
    if (statusCode == 204) {
      return {};
    }

    // 401 Unauthorized - clear stored token and re-throw
    if (statusCode == 401) {
      _removeTokenSynchronously().then((_) {
        // Token cleared - could trigger logout callback
      });
      throw Exception('Unauthorized - please login again');
    }

    // 403 Forbidden
    if (statusCode == 403) {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Forbidden access');
      } catch (_) {
        throw Exception('Forbidden access (status $statusCode)');
      }
    }

    // 404 Not Found
    if (statusCode == 404) {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Resource not found');
      } catch (_) {
        throw Exception('Resource not found (status $statusCode)');
      }
    }

    // 409 Conflict
    if (statusCode == 409) {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Conflict - resource may already exist');
      } catch (_) {
        throw Exception('Conflict (status $statusCode)');
      }
    }

    // 422 Unprocessable Entity - validation errors
    if (statusCode == 422) {
      try {
        final errorBody = json.decode(response.body);
        final detail = errorBody['detail'] ?? errorBody;
        if (detail is List) {
          // FastAPI validation error format: list of {loc, msg, type}
          final messages = detail.map((e) => e['msg'] ?? 'Validation error').toString();
          throw Exception('Validation failed: $messages');
        }
        throw Exception('$detail');
      } catch (_) {
        throw Exception('Unprocessable entity (status $statusCode)');
      }
    }

    // 500 Internal Server Error
    if (statusCode == 500) {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Internal server error');
      } catch (_) {
        throw Exception('Internal server error (status $statusCode)');
      }
    }

    // Default case for any other status code
    try {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['detail'] ?? 'Request failed with status $statusCode');
    } catch (_) {
      throw Exception('Request failed with status $statusCode');
    }
  }

  // Synchronous helper for token removal in _handleResponse
  static Future<void> _removeTokenSynchronously() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}