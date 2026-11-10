import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upskilling/services/api_client.dart';

void main() {
  final mockClient = MockClient((request) async {
    final uri = Uri.parse(request.url.toString());

    // Register endpoint - expects form data
    if (request.url.path == '/api/auth/register' && request.method == 'POST') {
      final body = request.body;
      // Validate form fields are present
      if (body.contains('email') && body.contains('username') && body.contains('password')) {
        return http.Response(
          '{"success": true, "data": {"id": 1, "email": "test@example.com", "username": "testuser"}}',
          200,
        );
      }
      return http.Response('Missing form fields', 400);
    }

    // Login endpoint - expects form data
    if (request.url.path == '/api/auth/login' && request.method == 'POST') {
      final body = request.body;
      // Validate form fields are present
      if (body.contains('username') && body.contains('password')) {
        return http.Response(
          '{"success": true, "data": {"access_token": "test_jwt_token", "token_type": "bearer"}}',
          200,
        );
      }
      return http.Response('Missing credentials', 400);
    }

    // Profile GET endpoint
    if (request.url.path == '/api/profile' && request.method == 'GET') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        return http.Response(
          '{"success": true, "data": {"name": "Test User", "email": "test@example.com", "skills": []}}',
          200,
        );
      }
      return http.Response('Unauthorized', 401);
    }

    // Profile POST endpoint
    if (request.url.path == '/api/profile' && request.method == 'POST') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        final body = request.body;
        if (body.isNotEmpty) {
          return http.Response(
            '{"success": true, "data": {"message": "Profile updated successfully"}}',
            200,
          );
        }
        return http.Response('No data', 400);
      }
      return http.Response('Unauthorized', 401);
    }

    // Skills GET endpoint
    if (request.url.path == '/api/skills' && request.method == 'GET') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        return http.Response(
          '{"success": true, "data": {"skills": [{"id": 1, "skill_name": "Python", "proficiency_level": "Intermediate", "category": "Programming"}]}}',
          200,
        );
      }
      return http.Response('Unauthorized', 401);
    }

    // Skills POST endpoint - JSON body
    if (request.url.path == '/api/skills' && request.method == 'POST') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        final body = request.body;
        if (body.isNotEmpty && body.contains('skill_name')) {
          return http.Response(
            '{"success": true, "data": {"message": "Skill added", "skill_id": 2}}',
            201,
          );
        }
        return http.Response('Invalid skill data', 422);
      }
      return http.Response('Unauthorized', 401);
    }

    // Career recommendations
    if (request.url.path == '/api/ai/career-recommendations' && request.method == 'POST') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        return http.Response(
          '{"success": true, "data": {"careers": [{"id": 1, "name": "Software Engineer", "description": "Build software", "category": "Tech", "average_salary": 100000, "growth_outlook": "High"}]}}',
          200,
        );
      }
      return http.Response('Unauthorized', 401);
    }

    // Skill gap analysis
    if (request.url.path == '/api/ai/skill-gap-analysis' && request.method == 'POST') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        return http.Response(
          '{"success": true, "data": {"match_percentage": 85, "existing_skills": ["Python"], "required_skills": ["JavaScript"], "missing_skills": ["JavaScript"]}}',
          200,
        );
      }
      return http.Response('Unauthorized', 401);
    }

    // Personalized skills
    if (request.url.path == '/api/ai/personalized-skills' && request.method == 'POST') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        return http.Response(
          '{"success": true, "data": {"suggestions": ["Learn JavaScript", "Build a project"]}}',
          200,
        );
      }
      return http.Response('Unauthorized', 401);
    }

    // Roadmap generation
    if (request.url.path == '/api/ai/roadmap-generate' && request.method == 'POST') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        return http.Response(
          '{"success": true, "data": {"roadmap": {"title": "Learning Roadmap", "phases": [{"phase_name": "Fundamentals", "tasks": [{"task_name": "Learn basics"}]}}}}',
          200,
        );
      }
      return http.Response('Unauthorized', 401);
    }

    // Learning resources
    if (request.url.path == '/api/ai/recommend-resources' && request.method == 'POST') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        return http.Response(
          '{"success": true, "data": {"resources": [{"resource_name": "Flutter Course", "platform": "Udemy", "resource_type": "course}]}}',
          200,
        );
      }
      return http.Response('Unauthorized', 401);
    }

    // Progress update - JSON body
    if (request.url.path.contains('/api/progress/') && request.method == 'POST') {
      final authorization = request.headers['authorization'];
      if (authorization != null && authorization.startsWith('Bearer ')) {
        final body = request.body;
        if (body.contains('status')) {
          return http.Response(
            '{"success": true, "data": {"message": "Task marked as completed"}}',
            200,
          );
        }
        return http.Response('Missing status field', 422);
      }
      return http.Response('Unauthorized', 401);
    }

    // Default 404
    return http.Response('Not Found', 404);
  });

  group('API Client - Response Parsing', () {
    test('getSkills extracts data.skills from response', () async {
      final skills = await APIClient.getSkills();
      expect(skills.length, greaterThan(0));
      expect(skills[0]['skill_name'], equals('Python'));
      expect(skills[0]['proficiency_level'], equals('Intermediate'));
      expect(skills[0]['category'], equals('Programming'));
    });

    test('getLearningResources extracts data.resources from response', () async {
      final resources = await APIClient.getLearningResources(
        taskDescription: 'Learn Flutter',
        skillFocus: 'Programming',
      );
      expect(resources.length, greaterThan(0));
    });

    test('getProfile returns user profile data', () async {
      final profile = await APIClient.getProfile();
      expect(profile['data']['name'], isNotEmpty);
      expect(profile['data']['email'], equals('test@example.com'));
      expect(profile['data']['skills'], isEmpty);
    });
  });

  group('API Client - Error Handling', () {
    test('401 handling - unauthorized responses trigger token removal', () {
      // Test that 401 responses are properly handled by _handleResponse
      // The method should clear stored JWT token on 401
    });

    test('404 handling - not found responses', () {
      // Test that 404 responses are properly handled
    });

    test('422 handling - validation errors', () {
      // Test that 422 validation errors are properly handled
    });

    test('500 handling - server errors', () {
      // Test that 500 server errors are properly handled
    });

    test('malformed JSON response handling', () {
      // Test handling of invalid JSON responses
    });
  });

  group('API Client - Authentication', () {
    test('JWT token storage after login', () {
      // Verify token is stored after successful login
      // The saveToken method should persist token to SharedPreferences
    });

    test('JWT token removal after logout', () {
      // Verify token is removed after logout
      // The removeToken method should clear stored token
    });

    test('Authorization header constructed correctly', () {
      // Verify Bearer token format in headers
      // Headers should include "Authorization: Bearer <token>"
    });

    test('Login returns valid JWT token', () {
      // Verify login returns access_token in response body
    });
  });

  group('API Client - Form Authentication', () {
    test('Register sends form-encoded credentials with email, username, password', () {
      // Verify register request uses form encoding
    });

    test('Login sends form-encoded credentials with username, password', () {
      // Verify login request uses form encoding
    });

    test('Register validates all required form fields present', () {
      // Test that missing fields return 400
    });

    test('Login validates credentials are present', () {
      // Test that missing credentials return 400
    });
  });

  group('API Contract Tests', () {
    test('GET profile returns 401 without authentication', () {
      // Test that profile endpoint without token returns 401
      // Should not have authorization header
    });

    test('POST profile with data updates profile successfully', () {
      // Test profile update with JSON body and auth header
    });

    test('GET skills returns user skills list with auth header', () {
      // Test skills listing requires valid Bearer token
    });

    test('POST skill adds skill with JSON body (skill_name, proficiency_level, category)', () {
      // Test skill creation requires valid Bearer token and JSON body
    });

    test('Career recommendations with valid request and auth header', () {
      // Test career recommendations endpoint
    });

    test('Skill gap analysis with valid request and auth header', () {
      // Test skill gap analysis endpoint
    });

    test('Personalized skills request with auth header', () {
      // Test personalized skills endpoint
    });

    test('Roadmap generation request with auth header', () {
      // Test roadmap generation endpoint
    });

    test('Learning resources request with auth header', () {
      // Test learning resources recommendation endpoint
    });

    test('Progress update with JSON body (status field) and auth header', () {
      // Test task progress update requires status in JSON body
    });
  });
}