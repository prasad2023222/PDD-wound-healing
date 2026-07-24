import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool showOverview = true;
  bool isLoading = true;

  List scans = [];

  @override
  void initState() {
    super.initState();
    loadScans();
  }

  Future<void> loadScans() async {
    final response = await ApiService.getMyScans();

    setState(() {
      scans = response?["scans"] ?? [];
      isLoading = false;
    });
  }

  List get oldestToLatestScans {
    return scans.reversed.toList();
  }

  int dayNumber(dynamic scan) {
    if (oldestToLatestScans.isEmpty) return 1;

    final firstDate = DateTime.tryParse(
      oldestToLatestScans.first["created_at"].toString(),
    );

    final scanDate = DateTime.tryParse(scan["created_at"].toString());

    if (firstDate == null || scanDate == null) return 1;

    return scanDate.difference(firstDate).inDays + 1;
  }

  int get latestScore {
    if (scans.isEmpty) return 0;
    return scans.first["healing_score"] ?? 0;
  }

  String get latestStatus {
    if (scans.isEmpty) return "No progress yet";
    return scans.first["progress_status"] ?? "Stable";
  }

  String get latestSummary {
    if (scans.isEmpty) {
      return "Upload palate scans to start tracking healing progress.";
    }

    return scans.first["summary"] ??
        "Your latest scan has been analyzed successfully.";
  }

  int previousScore(dynamic scan) {
    return scan["healing_score"] ?? 0;
  }

  String scoreChangeText() {
    if (scans.length < 2) return "First scan";

    final latest = scans[0]["healing_score"] ?? 0;
    final previous = scans[1]["healing_score"] ?? 0;
    final diff = latest - previous;

    if (diff > 0) return "+$diff improvement";
    if (diff < 0) return "$diff decline";

    return "No change";
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "improving":
        return Colors.green;

      case "worsening":
        return Colors.red;

      case "stable":
        return Colors.orange;

      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : RefreshIndicator(
                onRefresh: loadScans,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recovery Progress",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Track your healing journey over time.",
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      tabToggle(),

                      const SizedBox(height: 25),

                      showOverview ? overviewUI() : timelineUI(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget tabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          tabButton("Overview", showOverview, () {
            setState(() => showOverview = true);
          }),

          tabButton("Timeline", !showOverview, () {
            setState(() => showOverview = false);
          }),
        ],
      ),
    );
  }

  Widget tabButton(String title, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,

        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),

          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),

            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),

          child: Text(
            title,
            textAlign: TextAlign.center,

            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget overviewUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        progressSummaryCard(),

        const SizedBox(height: 20),

        trendCard(),

        const SizedBox(height: 25),

        const Text(
          "Progress Summary",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 15),

        if (scans.isEmpty)
          emptyCard("No scans yet. Upload your first palate image."),

        if (scans.isNotEmpty)
          weeklyCard(
            week: "Latest Scan",
            date: "Day ${dayNumber(scans.first)}",
            change: "$latestScore/100",
            status: latestStatus,
          ),

        if (scans.length > 1)
          weeklyCard(
            week: "Previous Scan",
            date: "Day ${dayNumber(scans[1])}",
            change: "${scans[1]["healing_score"] ?? 0}/100",
            status: scans[1]["progress_status"] ?? "Recorded",
          ),
      ],
    );
  }

  Widget progressSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11B8A5), Color(0xFF008779)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Current Healing Score",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Text(
                  scoreChangeText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text(
                "$latestScore",
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

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: latestScore / 100,
              minHeight: 8,
              backgroundColor: Colors.black.withOpacity(0.12),
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            latestSummary,
            style: const TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget trendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),

      decoration: whiteCard(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Healing Score Trend",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 26),

          SizedBox(
            height: 225,

            child: scans.isEmpty
                ? const Center(
                    child: Text(
                      "No trend available yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : CustomPaint(
                    painter: RecoveryGraphPainter(scans: oldestToLatestScans),
                    size: Size.infinite,
                  ),
          ),

          const SizedBox(height: 8),

          dynamicDayLabels(),
        ],
      ),
    );
  }

  Widget dynamicDayLabels() {
    if (scans.isEmpty) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Day 1", style: TextStyle(color: Colors.grey)),
          Text("Day 3", style: TextStyle(color: Colors.grey)),
          Text("Day 7", style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    final graphScans = oldestToLatestScans.length > 5
        ? oldestToLatestScans.sublist(oldestToLatestScans.length - 5)
        : oldestToLatestScans;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: graphScans.map((scan) {
        return Text(
          "Day ${dayNumber(scan)}",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        );
      }).toList(),
    );
  }

  Widget weeklyCard({
    required String week,
    required String date,
    required String change,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),

      decoration: whiteCard(),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: statusColor(status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),

            child: Icon(Icons.trending_up, color: statusColor(status)),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(week, style: const TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 4),

                Text(date, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text(
                change,
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                status,
                style: TextStyle(
                  color: statusColor(status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget timelineUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        beforeAfterCard(),

        const SizedBox(height: 25),

        if (scans.isEmpty)
          emptyCard("No timeline yet. Upload scans to see progress."),

        ...scans.map((scan) {
          final index = scans.indexOf(scan);

          return timelineCard(
            scan: scan,
            title: index == 0 ? "Latest Scan" : "Previous Scan ${index + 1}",
            active: index == 0,
          );
        }).toList(),
      ],
    );
  }

  Widget beforeAfterCard() {
    final firstScan = scans.isNotEmpty ? scans.last : null;
    final latestScan = scans.isNotEmpty ? scans.first : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: whiteCard(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Before & After",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: imageBox(
                  label: "Day 1",
                  imageUrl: firstScan?["image_url"],
                  tagColor: Colors.grey,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: imageBox(
                  label: latestScan == null
                      ? "Today"
                      : "Day ${dayNumber(latestScan)}",
                  imageUrl: latestScan?["image_url"],
                  tagColor: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget imageBox({
    required String label,
    required String? imageUrl,
    required Color tagColor,
  }) {
    String? emulatorUrl;

    if (imageUrl != null) {
      emulatorUrl = imageUrl.replaceFirst(
        "http://127.0.0.1:8000",
        "http://10.0.2.2:8000",
      );
    }

    return Container(
      height: 170,

      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),

      child: Stack(
        children: [
          if (emulatorUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),

              child: Image.network(
                emulatorUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            const Center(
              child: Text("Image", style: TextStyle(color: Colors.teal)),
            ),

          Positioned(
            top: 10,
            left: 10,

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(8),
              ),

              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget timelineCard({
    required dynamic scan,
    required String title,
    required bool active,
  }) {
    final score = scan["healing_score"] ?? 0;
    final status = scan["progress_status"] ?? "Recorded";
    final summary =
        scan["summary"] ??
        "${scan["condition"] ?? "Unknown"} • Severity: ${scan["severity"] ?? "N/A"}";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,

              decoration: BoxDecoration(
                color: active ? Colors.teal : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.teal, width: 2),
              ),
            ),

            Container(width: 1, height: 120, color: Colors.grey[300]),
          ],
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(18),

            decoration: whiteCard(),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$title • Day ${dayNumber(scan)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Text(
                        "$score/100",
                        style: TextStyle(
                          color: statusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  status,
                  style: TextStyle(
                    color: statusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  summary,
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: whiteCard(),

      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }

  BoxDecoration whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),

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

class RecoveryGraphPainter extends CustomPainter {
  final List scans;

  RecoveryGraphPainter({required this.scans});

  @override
  void paint(Canvas canvas, Size size) {
    if (scans.isEmpty) return;

    final visibleScans = scans.length > 5
        ? scans.sublist(scans.length - 5)
        : scans;

    final graphHeight = size.height * 0.62;
    final graphTop = size.height * 0.18;
    final graphBottom = graphTop + graphHeight;

    final points = <Offset>[];

    for (int i = 0; i < visibleScans.length; i++) {
      final score = (visibleScans[i]["healing_score"] ?? 0).toDouble();

      final x = visibleScans.length == 1
          ? size.width / 2
          : (size.width / (visibleScans.length - 1)) * i;

      final normalized = score / 100;

      final y = graphBottom - (normalized * graphHeight);

      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.teal.withOpacity(0.13)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];

      final controlX = (previous.dx + current.dx) / 2;

      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, graphBottom)
      ..lineTo(points.first.dx, graphBottom)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 4.5, pointPaint);

      canvas.drawCircle(point, 2.2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
