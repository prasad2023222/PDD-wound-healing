import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  double painLevel = 3;
  double irritationLevel = 4;

  String smokingToday = "No";
  String waterIntake = "1-2L";

  bool isLoading = false;

  final TextEditingController notesController = TextEditingController();

  Future<void> saveDailyLog() async {
    setState(() {
      isLoading = true;
    });

    int smokingCount = smokingToday == "Yes" ? 1 : 0;

    int waterValue = 2;

    if (waterIntake == "< 1L") {
      waterValue = 1;
    } else if (waterIntake == "1-2L") {
      waterValue = 2;
    } else {
      waterValue = 3;
    }

    final response = await ApiService.createDailyLog(
      painLevel.toInt(),
      irritationLevel.toInt(),
      smokingCount,
      waterValue,
      notesController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daily log saved successfully")),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save daily log")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,

        title: const Text(
          "Daily Log",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Track today's symptoms and habits.",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),

            const SizedBox(height: 30),

            buildSectionTitle("Pain Level"),

            const SizedBox(height: 15),

            buildSlider(
              value: painLevel,
              onChanged: (value) {
                setState(() {
                  painLevel = value;
                });
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("No Pain"),

                Text(
                  "${painLevel.toInt()}/10",
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),

            buildSectionTitle("Irritation Level"),

            const SizedBox(height: 15),

            buildSlider(
              value: irritationLevel,
              onChanged: (value) {
                setState(() {
                  irritationLevel = value;
                });
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Low"),

                Text(
                  "${irritationLevel.toInt()}/10",
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),

            buildSectionTitle("Did you smoke today?"),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: buildOptionCard(
                    title: "No",
                    selected: smokingToday == "No",
                    onTap: () {
                      setState(() {
                        smokingToday = "No";
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: buildOptionCard(
                    title: "Yes",
                    selected: smokingToday == "Yes",
                    onTap: () {
                      setState(() {
                        smokingToday = "Yes";
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),

            buildSectionTitle("Water Intake"),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: buildOptionCard(
                    title: "< 1L",
                    selected: waterIntake == "< 1L",
                    onTap: () {
                      setState(() {
                        waterIntake = "< 1L";
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: buildOptionCard(
                    title: "1-2L",
                    selected: waterIntake == "1-2L",
                    onTap: () {
                      setState(() {
                        waterIntake = "1-2L";
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: buildOptionCard(
                    title: "> 2L",
                    selected: waterIntake == "> 2L",
                    onTap: () {
                      setState(() {
                        waterIntake = "> 2L";
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),

            buildSectionTitle("Notes"),

            const SizedBox(height: 15),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: TextField(
                controller: notesController,
                maxLines: 5,

                decoration: InputDecoration(
                  hintText: "Describe symptoms or changes...",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),

                  contentPadding: const EdgeInsets.all(18),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(
                onPressed: isLoading ? null : saveDailyLog,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Daily Log",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget buildSlider({
    required double value,
    required Function(double) onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.teal,
        inactiveTrackColor: Colors.teal.withOpacity(0.15),
        thumbColor: Colors.teal,
        overlayColor: Colors.teal.withOpacity(0.2),
      ),

      child: Slider(
        value: value,
        min: 0,
        max: 10,
        divisions: 10,
        onChanged: onChanged,
      ),
    );
  }

  Widget buildOptionCard({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 55,

        decoration: BoxDecoration(
          color: selected ? Colors.teal : Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: selected ? Colors.teal : Colors.grey.shade300,
          ),
        ),

        child: Center(
          child: Text(
            title,

            style: TextStyle(
              color: selected ? Colors.white : Colors.black,

              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
