import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_timezone/flutter_timezone.dart';

import 'features/splash/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    // Disable debug logs in release mode to prevent sensitive data leakage
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }

  try {
    tz.initializeTimeZones();
    String localTimeZone = 'Asia/Kolkata';
    try {
      localTimeZone = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      debugPrint("Failed to get local timezone, falling back to Asia/Kolkata: $e");
    }

    try {
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {}
    }
  } catch (e) {
    debugPrint("Timezone initialization failed: $e");
  }

  if (!kIsWeb) {
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint("Notification initialization failed: $e");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oral Health AI',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const SplashScreen(),
    );
  }
}
