import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(settings);
  }

  static NotificationDetails notificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'oral_health_channel',
          'Oral Health Notifications',
          channelDescription: 'Reminders for oral health tracking',
          importance: Importance.high,
          priority: Priority.high,
        );

    return const NotificationDetails(android: androidDetails);
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await notificationsPlugin.show(1, title, body, notificationDetails());
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }
}
