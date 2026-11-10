import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upskilling/main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulate loading and then navigate
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      context.go('/onboarding');
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              size: 100,
              color: Color(0xFF6750A4),
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Upskilling System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Powered by Artificial Intelligence',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}