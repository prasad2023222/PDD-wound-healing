import 'package:flutter/material.dart';
import 'dart:async';

import '../../services/api_service.dart';

import '../onboarding/onboarding_screen.dart';
import '../consent/consent_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    // TEMPORARY LINE
    // This clears saved JWT token from local storage.
    // Remove this line later after testing onboarding/login flow.
    await ApiService.logout();

    final token = await ApiService.getSavedToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConsentScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: const [
            Icon(Icons.health_and_safety, size: 100, color: Colors.teal),

            SizedBox(height: 20),

            Text(
              "Oral Health AI",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
