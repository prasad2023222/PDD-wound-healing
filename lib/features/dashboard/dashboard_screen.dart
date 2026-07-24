import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../camera/camera_screen.dart';
import '../progress/progress_screen.dart';
import '../daily_log/daily_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;

  String fullName = "User";
  List scans = [];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    final profileResponse = await ApiService.getProfile();
    final scansResponse = await ApiService.getMyScans();

    setState(() {
      fullName = profileResponse?["user"]?["full_name"] ?? "User";
      scans = scansResponse?["scans"] ?? [];
      isLoading = false;
    });
  }

  int get healingScore {
    if (scans.isEmpty) return 0;
    return scans.first["healing_score"] ?? 0;
  }

  String get latestCondition {
    if (scans.isEmpty) return "No scan yet";
    return scans.first["condition"] ?? "Unknown";
  }

  String get latestSeverity {
    if (scans.isEmpty) return "N/A";
    return scans.first["severity"] ?? "N/A";
  }

  String get latestSummary {
    if (scans.isEmpty) {
      return "Upload your first palate scan to begin tracking healing progress.";
    }

    return scans.first["summary"] ??
        "Your latest scan has been analyzed successfully.";
  }

  String get progressStatus {
    if (scans.isEmpty) return "No Progress";

    return scans.first["progress_status"] ?? "Stable";
  }

  Color get progressColor {
    switch (progressStatus.toLowerCase()) {
      case "improving":
        return Colors.green;

      case "worsening":
        return Colors.red;

      case "stable":
        return Colors.orange;

      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadDashboardData,

                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      header(),

                      const SizedBox(height: 25),

                      healingScoreCard(),

                      const SizedBox(height: 25),

                      Row(
                        children: [
                          Expanded(child: scanCard(context)),

                          const SizedBox(width: 14),

                          Expanded(child: dailyLogCard(context)),
                        ],
                      ),

                      const SizedBox(height: 28),

                      healingTrendHeader(context),

                      const SizedBox(height: 15),

                      healingTrendCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              "Hello, $fullName",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(
              scans.isEmpty ? "Start your first oral scan." : latestSummary,
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
          ],
        ),

        Container(
          width: 46,
          height: 46,

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: const Center(child: Icon(Icons.notifications_none)),
        ),
      ],
    );
  }

  Widget healingScoreCard() {
    final score = healingScore;
    final progress = score / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11B8A5), Color(0xFF008779)],
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              const Text(
                "Healing Score",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: progressColor),

                    const SizedBox(width: 5),

                    Text(
                      progressStatus,
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text(
                "$score",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 7),

                child: Text(
                  "/100",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black.withOpacity(0.12),
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            scans.isEmpty ? "No scan result available yet" : latestCondition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            scans.isEmpty ? "" : "Severity Level: $latestSeverity",
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget scanCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );

        loadDashboardData();
      },

      child: Container(
        height: 145,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade300),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: const [
            Icon(Icons.camera_alt_outlined, color: Colors.teal, size: 38),

            SizedBox(height: 14),

            Text("Scan Palate", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget dailyLogCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DailyLogScreen()),
        );
      },

      child: Container(
        height: 145,
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: const Color(0xFFF1F7FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD8E9FF)),
        ),

        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Icon(Icons.calendar_today, color: Colors.blue),

            Spacer(),

            Text(
              "Daily Log",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 6),

            Text("Log symptoms", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget healingTrendHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Healing Trend",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProgressScreen()),
            );
          },

          child: const Text(
            "View all",
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget healingTrendCard() {
    if (scans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: whiteCard(),

        child: const Text("No scans yet. Upload your first oral image."),
      );
    }

    return Container(
      width: double.infinity,
      height: 230,
      padding: const EdgeInsets.all(20),

      decoration: whiteCard(),

      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 35, right: 10, bottom: 10),

              child: CustomPaint(painter: DashboardTrendPainter(scans)),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,

            child: Text(
              "Healing Progress",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          Positioned(
            right: 0,
            top: 0,

            child: Text(
              "${scans.length} scans",
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),

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

class DashboardTrendPainter extends CustomPainter {
  final List scans;

  DashboardTrendPainter(this.scans);

  @override
  void paint(Canvas canvas, Size size) {
    if (scans.isEmpty) return;

    final linePaint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.fill;

    final path = Path();

    final visibleScans = scans.take(5).toList().reversed.toList();

    final points = <Offset>[];

    for (int i = 0; i < visibleScans.length; i++) {
      final score = (visibleScans[i]["healing_score"] ?? 0).toDouble();

      final x = visibleScans.length == 1
          ? size.width / 2
          : (size.width / (visibleScans.length - 1)) * i;

      final y = size.height - ((score / 100) * size.height);

      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 6, pointPaint);

      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
