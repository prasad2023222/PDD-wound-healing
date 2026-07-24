import 'package:flutter/material.dart';

import '../profile_setup/profile_setup_screen.dart';
import '../main_navigation/main_navigation_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool cameraAccess = false;
  bool dataProcessing = false;

  bool get isEnabled => cameraAccess && dataProcessing;

  void skipToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  void continueToProfileSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),

                  GestureDetector(
                    onTap: skipToDashboard,
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.teal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "Consent & Permissions",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Review our medical disclaimer and grant necessary permissions.",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        "This app is an AI-assisted tracking tool, not a medical device. "
                        "It does not replace professional medical advice. Always consult a doctor or dentist.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Required Permissions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              permissionTile(
                icon: Icons.camera_alt,
                title: "Camera Access",
                subtitle: "Needed to capture images for analysis",
                value: cameraAccess,
                onChanged: (val) {
                  setState(() {
                    cameraAccess = val;
                  });
                },
              ),

              const SizedBox(height: 15),

              permissionTile(
                icon: Icons.security,
                title: "Secure Data Processing",
                subtitle: "Allow AI to process and store your data securely",
                value: dataProcessing,
                onChanged: (val) {
                  setState(() {
                    dataProcessing = val;
                  });
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnabled ? Colors.teal : Colors.grey,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  onPressed: isEnabled ? continueToProfileSetup : null,

                  child: const Text(
                    "I Accept & Continue",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: TextButton(
                  onPressed: skipToDashboard,

                  child: const Text(
                    "Skip for now and go to dashboard",
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget permissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Switch(value: value, onChanged: onChanged, activeColor: Colors.teal),
        ],
      ),
    );
  }
}
