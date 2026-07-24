import 'package:flutter/material.dart';

import '../main_navigation/main_navigation_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final Map<String, dynamic> result;

  const AnalysisScreen({super.key, required this.result});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prediction =
        widget.result["prediction"] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isLoading ? loadingUI() : resultUI(prediction),
        ),
      ),
    );
  }

  Widget loadingUI() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.teal),
        SizedBox(height: 25),
        Text(
          "Analyzing your oral image...",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          "AI is checking color, texture, and visible healing patterns.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget resultUI(Map<String, dynamic> prediction) {
    final recommendations = prediction["recommendations"] is List
        ? prediction["recommendations"] as List
        : [];

    final observations = prediction["observations"] is List
        ? prediction["observations"] as List
        : [];

    final summary =
        prediction["summary"]?.toString() ?? "No summary available.";

    final riskAlert =
        prediction["risk_alert"]?.toString() ?? "No risk alert available.";

    final coachingTip =
        prediction["coaching_tip"]?.toString() ??
        "Continue tracking your recovery.";

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Analysis Result",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text(
            "Based on your uploaded palate image.",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 25),

          resultCard(prediction),

          const SizedBox(height: 25),

          summaryCard(summary),

          const SizedBox(height: 25),

          const Text(
            "Visual Observations",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          if (observations.isEmpty)
            recommendationCard(
              icon: Icons.visibility_outlined,
              title: "No observation available",
              desc: "The AI could not extract clear observations.",
            )
          else
            ...observations.map((item) {
              return recommendationCard(
                icon: Icons.visibility_outlined,
                title: "Observation",
                desc: item.toString(),
              );
            }).toList(),

          const SizedBox(height: 10),

          const Text(
            "Recovery Guidance",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          recommendationCard(
            icon: Icons.warning_amber_rounded,
            title: "Risk Alert",
            desc: riskAlert,
          ),

          recommendationCard(
            icon: Icons.health_and_safety_outlined,
            title: "Coaching Tip",
            desc: coachingTip,
          ),

          const SizedBox(height: 10),

          const Text(
            "Recommendations",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          if (recommendations.isEmpty)
            recommendationCard(
              icon: Icons.tips_and_updates_outlined,
              title: "Recommendation",
              desc:
                  "Maintain oral hygiene, avoid smoking during healing, stay hydrated, and consult a dentist if symptoms persist.",
            )
          else
            ...recommendations.map((item) {
              return recommendationCard(
                icon: Icons.tips_and_updates_outlined,
                title: "Recommendation",
                desc: item.toString(),
              );
            }).toList(),

          recommendationCard(
            icon: Icons.medical_services,
            title: "Medical Note",
            desc:
                "This is an AI-assisted visual wellness assessment, not a medical diagnosis. Please consult a dentist for clinical decisions.",
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigationScreen(),
                  ),
                );
              },
              child: const Text(
                "Continue to Dashboard",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget resultCard(Map<String, dynamic> prediction) {
    final condition =
        prediction["condition"]?.toString() ?? "Condition unclear";

    final severity = prediction["severity"]?.toString() ?? "Unclear";

    final confidence = prediction["confidence"] ?? 0;

    final healingScore = prediction["healing_score"] ?? 0;

    final progressStatus =
        prediction["progress_status"]?.toString() ?? "Unclear";

    final improvement = prediction["improvement_percentage"] ?? 0;

    final recoveryDays = prediction["predicted_recovery_days"];

    final filename = widget.result["filename"]?.toString() ?? "Uploaded image";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Detected Condition",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 8),

          Text(
            condition,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),

          const SizedBox(height: 20),

          scoreRow("Healing Score", "$healingScore/100"),

          scoreRow("Progress Status", progressStatus),

          scoreRow("Improvement", "$improvement%"),

          scoreRow(
            "Estimated Recovery",
            recoveryDays == null ? "N/A" : "$recoveryDays days",
          ),

          scoreRow("Severity", severity),

          scoreRow("AI Confidence", "$confidence%"),

          scoreRow("Uploaded File", filename),
        ],
      ),
    );
  }

  Widget summaryCard(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Summary",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget scoreRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget recommendationCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal),
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
                  desc,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
