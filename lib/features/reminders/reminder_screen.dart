import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool isLoading = true;
  List reminders = [];

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  Future<void> loadReminders() async {
    final response = await ApiService.getReminders();

    setState(() {
      reminders = response?["reminders"] ?? [];
      isLoading = false;
    });
  }

  Future<void> openAddReminderDialog() async {
    final titleController = TextEditingController();
    String selectedType = "daily_log";
    TimeOfDay selectedTime = const TimeOfDay(hour: 21, minute: 0);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Reminder"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Reminder title",
                      hintText: "Drink water / Daily log",
                    ),
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: "Reminder type",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "daily_log",
                        child: Text("Daily Log"),
                      ),
                      DropdownMenuItem(
                        value: "hydration",
                        child: Text("Hydration"),
                      ),
                      DropdownMenuItem(value: "scan", child: Text("Oral Scan")),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: Text("Time: ${selectedTime.format(context)}"),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );

                          if (picked != null) {
                            setDialogState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: const Text("Choose"),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();

                if (title.isEmpty) return;

                final timeText = selectedTime.format(context);

                final response = await ApiService.createReminder(
                  title,
                  selectedType,
                  timeText,
                );

                if (response != null) {
                  await NotificationService.scheduleDailyNotification(
                    id: response["reminder_id"],
                    title: "Oral Health AI",
                    body: title,
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                  );

                  if (!mounted) return;

                  Navigator.pop(context);
                  await loadReminders();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Reminder created successfully"),
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> toggleReminder(dynamic reminder) async {
    final response = await ApiService.toggleReminder(reminder["id"]);

    if (response != null) {
      final bool isActive = response["is_active"];

      if (isActive) {
        final parsed = parseTime(reminder["time"]);

        await NotificationService.scheduleDailyNotification(
          id: reminder["id"],
          title: "Oral Health AI",
          body: reminder["title"],
          hour: parsed.hour,
          minute: parsed.minute,
        );
      } else {
        await NotificationService.cancelNotification(reminder["id"]);
      }

      await loadReminders();
    }
  }

  Future<void> deleteReminder(dynamic reminder) async {
    await NotificationService.cancelNotification(reminder["id"]);

    final response = await ApiService.deleteReminder(reminder["id"]);

    if (response != null) {
      await loadReminders();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Reminder deleted")));
    }
  }

  TimeOfDay parseTime(String timeText) {
    final parts = timeText.split(" ");
    final hourMinute = parts[0].split(":");

    int hour = int.parse(hourMinute[0]);
    final int minute = int.parse(hourMinute[1]);

    final period = parts.length > 1 ? parts[1].toUpperCase() : "AM";

    if (period == "PM" && hour != 12) {
      hour += 12;
    }

    if (period == "AM" && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String typeLabel(String type) {
    if (type == "daily_log") return "Daily Log";
    if (type == "hydration") return "Hydration";
    if (type == "scan") return "Oral Scan";
    return type;
  }

  IconData typeIcon(String type) {
    if (type == "hydration") return Icons.local_drink;
    if (type == "scan") return Icons.camera_alt_outlined;
    return Icons.edit_note;
  }

  Color typeColor(String type) {
    if (type == "hydration") return Colors.blue;
    if (type == "scan") return Colors.purple;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text(
          "Reminders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        tooltip: "Add reminder",
        onPressed: openAddReminderDialog,
        child: const Icon(Icons.add),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: reminders.isEmpty
                  ? const Center(
                      child: Text(
                        "No reminders yet. Tap + to add one.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        return reminderCard(reminders[index]);
                      },
                    ),
            ),
    );
  }

  Widget reminderCard(dynamic reminder) {
    final bool isActive = reminder["is_active"] ?? false;
    final color = typeColor(reminder["reminder_type"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon(reminder["reminder_type"]), color: color),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder["title"] ?? "Reminder",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "${typeLabel(reminder["reminder_type"])} • ${reminder["time"]}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          Switch(
            value: isActive,
            activeColor: Colors.teal,
            onChanged: (_) {
              toggleReminder(reminder);
            },
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              deleteReminder(reminder);
            },
          ),
        ],
      ),
    );
  }
}
