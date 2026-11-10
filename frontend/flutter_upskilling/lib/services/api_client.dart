import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class APIClient {
  // Base URL for the FastAPI backend
  static const String _baseUrl = 'http://10.0.2.2:8000';

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

  static Map<String, String> buildHeaders({String? token}) {
    final t = token ?? _getCachedToken();
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
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
    final body = json.encode({
      'email': email,
      'username': username,
      'password': password,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final body = json.encode({
      'email': email,
      'password': password,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final uri = Uri.parse('$_baseUrl/api/users/me');
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
    final uri = Uri.parse('$_baseUrl/api/users/me/profile');
    final body = json.encode({
      'name': name,
      'institution': institution,
      'degree': degree,
      'academicYear': academicYear,
    });

    final response = await http.put(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getSkills() async {
    final uri = Uri.parse('$_baseUrl/api/skills/me');
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
    final uri = Uri.parse('$_baseUrl/api/skills/me');
    final body = json.encode({
      'skillName': skillName,
      'proficiencyLevel': proficiencyLevel,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCareerRecommendations() async {
    final uri = Uri.parse('$_baseUrl/api/ai/career-recommendations');
    final response = await http.get(
      uri,
      headers: buildHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getSkillGapAnalysis({
    required String careerId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ai/skill-gap-analysis');
    final body = json.encode({
      'careerId': careerId,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPersonalizedSkills() async {
    final uri = Uri.parse('$_baseUrl/api/ai/personalized-skills');
    final response = await http.get(
      uri,
      headers: buildHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> generateRoadmap({
    required String careerId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ai/roadmap-generate');
    final body = json.encode({
      'careerId': careerId,
    });

    final response = await http.post(
      uri,
      headers: buildHeaders(),
      body: body,
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getLearningResources({
    required String taskId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/learning-resources');
    final body = json.encode({
      'taskId': taskId,
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
    final uri = Uri.parse('$_baseUrl/api/task-progress');
    final body = json.encode({
      'taskId': taskId,
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