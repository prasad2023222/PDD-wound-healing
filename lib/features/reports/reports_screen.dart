import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isLoading = false;
  Map<String, dynamic>? report;

  Future<void> generateReport() async {
    setState(() {
      isLoading = true;
    });

    final response = await ApiService.getReportSummary();

    setState(() {
      report = response;
      isLoading = false;
    });

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate report")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report generated successfully")),
      );
    }
  }

  Future<void> downloadPdfReport() async {
    if (report == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Generate report first")));
      return;
    }

    await PdfService.generateAndShareReport(report!);
  }

  @override
  Widget build(BuildContext context) {
    final user = report?["user"];
    final latestScan = report?["latest_scan"];
    final latestLog = report?["latest_log"];

    final observations = latestScan?["observations"] ?? [];
    final recommendations =
        latestScan?["recommendations"] ?? report?["recommendations"] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: generateReport,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Doctor Reports",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Generate and share your recovery progress reports.",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 25),

                generateReportCard(),

                const SizedBox(height: 28),

                if (report != null) ...[
                  const Text(
                    "Generated Report",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  reportSummaryCard(
                    user: user,
                    latestScan: latestScan,
                    latestLog: latestLog,
                    observations: observations,
                    recommendations: recommendations,
                  ),

                  const SizedBox(height: 28),
                ],

                const Text(
                  "Recent Reports",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                if (report != null)
                  reportCard(
                    context,
                    title: "Latest Recovery Report",
                    date: "Generated now",
                  )
                else
                  emptyReportCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget generateReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: const Color(0xFFEFFFFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.teal.shade100),
      ),

      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),

            child: const Icon(Icons.description, color: Colors.teal, size: 34),
          ),

          const SizedBox(height: 20),

          const Text(
            "Generate New Report",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          const Text(
            "Create a doctor-friendly report using your latest scan, healing score, observations, daily logs, and AI recommendations.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,

            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              onPressed: isLoading ? null : generateReport,

              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.description_outlined),

              label: Text(isLoading ? "Generating..." : "Generate Report"),
            ),
          ),
        ],
      ),
    );
  }

  Widget reportSummaryCard({
    required dynamic user,
    required dynamic latestScan,
    required dynamic latestLog,
    required dynamic observations,
    required dynamic recommendations,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: whiteCard(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            user?["full_name"] ?? "User",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(
            user?["email"] ?? "",
            style: const TextStyle(color: Colors.grey),
          ),

          const Divider(height: 30),

          infoRow("Risk Level", report?["risk_level"] ?? "Unknown"),
          infoRow("Total Scans", "${report?["total_scans"] ?? 0}"),
          infoRow("Total Logs", "${report?["total_logs"] ?? 0}"),

          infoRow(
            "Healing Score",
            latestScan?["healing_score"] == null
                ? "No scan yet"
                : "${latestScan["healing_score"]}/100",
          ),

          infoRow(
            "Progress Status",
            latestScan?["progress_status"] ?? "No scan yet",
          ),

          infoRow("Condition", latestScan?["condition"] ?? "No scan yet"),

          infoRow(
            "AI Confidence",
            latestScan?["confidence"] == null
                ? "N/A"
                : "${latestScan["confidence"]}%",
          ),

          infoRow("Severity", latestScan?["severity"] ?? "N/A"),

          if (latestScan?["summary"] != null) ...[
            const SizedBox(height: 12),
            noteBox(
              title: "AI Summary",
              text: latestScan["summary"].toString(),
              color: Colors.teal,
            ),
          ],

          const SizedBox(height: 18),

          const Text(
            "Visual Observations",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          if (observations.isEmpty)
            const Text(
              "No observations available.",
              style: TextStyle(color: Colors.grey),
            )
          else
            ...observations.map((item) {
              return bulletText(item.toString());
            }).toList(),

          const SizedBox(height: 18),

          const Text(
            "Daily Log Summary",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          infoRow(
            "Pain Level",
            latestLog?["pain_level"] == null
                ? "No log yet"
                : "${latestLog["pain_level"]}/10",
          ),

          infoRow(
            "Dryness Level",
            latestLog?["dryness_level"] == null
                ? "No log yet"
                : "${latestLog["dryness_level"]}/10",
          ),

          infoRow(
            "Smoking Count",
            latestLog?["smoking_count"] == null
                ? "N/A"
                : "${latestLog["smoking_count"]}",
          ),

          infoRow(
            "Water Intake",
            latestLog?["water_intake"] == null
                ? "N/A"
                : "${latestLog["water_intake"]}",
          ),

          if (latestLog?["notes"] != null) ...[
            const SizedBox(height: 12),
            noteBox(
              title: "Patient Notes",
              text: latestLog["notes"].toString(),
              color: Colors.blue,
            ),
          ],

          const SizedBox(height: 18),

          const Text(
            "Recommendations",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          if (recommendations.isEmpty)
            const Text(
              "No recommendations available.",
              style: TextStyle(color: Colors.grey),
            )
          else
            ...recommendations.map((item) {
              return bulletText(item.toString());
            }).toList(),
        ],
      ),
    );
  }

  Widget noteBox({
    required String title,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(text, style: const TextStyle(color: Colors.grey, height: 1.4)),
        ],
      ),
    );
  }

  Widget bulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),

      child: Text(
        "• $text",
        style: const TextStyle(color: Colors.grey, height: 1.4),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

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

  Widget emptyReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: whiteCard(),

      child: const Text(
        "No reports generated yet.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget reportCard(
    BuildContext context, {
    required String title,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),

      decoration: whiteCard(),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 4),

                    Text(date, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              const Icon(Icons.check_circle_outline, color: Colors.teal),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(),

          const SizedBox(height: 8),

          Row(
            children: [
              reportAction(context, Icons.download, "Download"),
              const SizedBox(width: 8),
              reportAction(context, Icons.share, "Share"),
              const SizedBox(width: 8),
              reportAction(context, Icons.email_outlined, "Email"),
            ],
          ),
        ],
      ),
    );
  }

  Widget reportAction(BuildContext context, IconData icon, String label) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () async {
          if (label == "Download" || label == "Share" || label == "Email") {
            await downloadPdfReport();
          }
        },

        icon: Icon(icon, size: 16),

        label: Text(label),

        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade300),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
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
