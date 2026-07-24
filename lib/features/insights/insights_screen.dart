import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? insights;

  @override
  void initState() {
    super.initState();
    loadInsights();
  }

  Future<void> loadInsights() async {
    final response = await ApiService.getInsights();

    setState(() {
      insights = response;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final latestScan = insights?["latest_scan"];
    final observations = latestScan?["observations"] ?? [];
    final recommendations =
        latestScan?["recommendations"] ?? insights?["recommendations"] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : RefreshIndicator(
                onRefresh: loadInsights,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AI Insights",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Personalized recovery guidance from your latest scan.",
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 25),

                      heroInsightCard(),

                      const SizedBox(height: 25),

                      insightStatsCard(),

                      const SizedBox(height: 25),

                      riskAndCoachingCard(),

                      const SizedBox(height: 25),

                      const Text(
                        "Visual Observations",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      if (observations.isEmpty)
                        adviceCard(
                          icon: Icons.visibility_outlined,
                          iconColor: Colors.blue,
                          borderColor: Colors.blue,
                          title: "No observations yet",
                          desc:
                              "Upload a palate image to generate visual observations.",
                        )
                      else
                        ...observations.map((item) {
                          return adviceCard(
                            icon: Icons.visibility_outlined,
                            iconColor: Colors.blue,
                            borderColor: Colors.blue,
                            title: "Observation",
                            desc: item.toString(),
                          );
                        }).toList(),

                      const SizedBox(height: 10),

                      const Text(
                        "Actionable Advice",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      if (recommendations.isEmpty)
                        adviceCard(
                          icon: Icons.lightbulb_outline,
                          iconColor: Colors.teal,
                          borderColor: Colors.teal,
                          title: "Start tracking",
                          desc:
                              "Upload an oral scan and add daily logs to generate personalized recommendations.",
                        )
                      else
                        ...recommendations.map((item) {
                          return adviceCard(
                            icon: Icons.tips_and_updates_outlined,
                            iconColor: Colors.teal,
                            borderColor: Colors.teal,
                            title: "Recommendation",
                            desc: item.toString(),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget heroInsightCard() {
    final latestScan = insights?["latest_scan"];

    final progressStatus =
        latestScan?["progress_status"] ??
        insights?["healing_status"] ??
        "No data yet";

    final summary =
        latestScan?["summary"] ??
        insights?["summary"] ??
        "Upload an oral image to generate AI-powered recovery insights.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF635BFF), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progressStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  summary,
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget insightStatsCard() {
    final riskLevel = insights?["risk_level"] ?? "Unknown";

    final latestScan = insights?["latest_scan"];
    final latestLog = insights?["latest_log"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Latest Recovery Summary",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          statRow("Risk Level", riskLevel),

          statRow(
            "Healing Score",
            latestScan?["healing_score"] == null
                ? "No scan yet"
                : "${latestScan["healing_score"]}/100",
          ),

          statRow(
            "Progress Status",
            latestScan?["progress_status"]?.toString() ?? "No scan yet",
          ),

          statRow(
            "Improvement",
            latestScan?["improvement_percentage"] == null
                ? "N/A"
                : "${latestScan["improvement_percentage"]}%",
          ),

          statRow(
            "Estimated Recovery",
            latestScan?["predicted_recovery_days"] == null
                ? "N/A"
                : "${latestScan["predicted_recovery_days"]} days",
          ),

          statRow(
            "Detected Condition",
            latestScan?["condition"]?.toString() ?? "No scan yet",
          ),

          statRow(
            "AI Confidence",
            latestScan?["confidence"] == null
                ? "N/A"
                : "${latestScan["confidence"]}%",
          ),

          statRow("Severity", latestScan?["severity"]?.toString() ?? "N/A"),

          statRow(
            "Pain Level",
            latestLog?["pain_level"] == null
                ? "No log yet"
                : "${latestLog["pain_level"]}/10",
          ),

          statRow(
            "Dryness Level",
            latestLog?["dryness_level"] == null
                ? "No log yet"
                : "${latestLog["dryness_level"]}/10",
          ),

          statRow(
            "Smoking Today",
            latestLog?["smoking_count"] == null
                ? "No log yet"
                : latestLog["smoking_count"] > 0
                ? "Yes"
                : "No",
          ),

          statRow(
            "Water Intake",
            latestLog?["water_intake"] == null
                ? "No log yet"
                : waterText(latestLog["water_intake"]),
          ),
        ],
      ),
    );
  }

  Widget riskAndCoachingCard() {
    final latestScan = insights?["latest_scan"];

    final riskAlert = latestScan?["risk_alert"] ?? "No risk alert available.";

    final coachingTip =
        latestScan?["coaching_tip"] ?? "Continue tracking your recovery.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recovery Guidance",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          adviceCard(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            borderColor: Colors.orange,
            title: "Risk Alert",
            desc: riskAlert.toString(),
          ),

          adviceCard(
            icon: Icons.health_and_safety_outlined,
            iconColor: Colors.teal,
            borderColor: Colors.teal,
            title: "Coaching Tip",
            desc: coachingTip.toString(),
          ),
        ],
      ),
    );
  }

  String waterText(dynamic value) {
    if (value == 1) return "< 1L";
    if (value == 2) return "1-2L";
    if (value == 3) return "> 2L";

    return "N/A";
  }

  Widget statRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.grey)),
          ),
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

  Widget adviceCard({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  desc,
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
