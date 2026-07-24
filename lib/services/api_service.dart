import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://172.27.158.162:8000",
  );

  static const _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> signup(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": fullName,
          "email": email,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Signup error: $e");
      return {"detail": "Connection error or request timed out."};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["access_token"] != null) {
        await _storage.write(key: "access_token", value: data["access_token"]);
      }

      return data;
    } catch (e) {
      debugPrint("Login error: $e");
      return {"detail": "Connection error or request timed out."};
    }
  }

  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("ForgotPassword error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "new_password": newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("ResetPassword error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("GetProfile error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateProfile(
    String fullName,
    String email,
  ) async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse("$baseUrl/update-profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"full_name": fullName, "email": email}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("UpdateProfile error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getMyScans() async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/my-scans"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("GetMyScans error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadImage(XFile imageFile) async {
    try {
      // 1. Enforce local client-side file size limit check (5MB)
      final length = await imageFile.length();
      if (length > 5 * 1024 * 1024) {
        debugPrint("File upload rejected on client: exceeds 5MB limit.");
        return null;
      }

      final token = await getSavedToken();
      if (token == null) return null;

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/upload-image"),
      );

      request.headers["Authorization"] = "Bearer $token";

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "file",
            bytes,
            filename: imageFile.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath("file", imageFile.path),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("UploadImage error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createDailyLog(
    int painLevel,
    int drynessLevel,
    int smokingCount,
    int waterIntake,
    String notes,
  ) async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse("$baseUrl/daily-log"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "pain_level": painLevel,
          "dryness_level": drynessLevel,
          "smoking_count": smokingCount,
          "water_intake": waterIntake,
          "notes": notes,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("CreateDailyLog error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getInsights() async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/insights"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("GetInsights error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getReportSummary() async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/report-summary"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("GetReportSummary error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createReminder(
    String title,
    String reminderType,
    String time,
  ) async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse("$baseUrl/reminders"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "reminder_type": reminderType,
          "time": time,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("CreateReminder error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getReminders() async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/reminders"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("GetReminders error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> toggleReminder(int reminderId) async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse("$baseUrl/reminders/$reminderId/toggle"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("ToggleReminder error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> deleteReminder(int reminderId) async {
    try {
      final token = await getSavedToken();
      if (token == null) return null;

      final response = await http.delete(
        Uri.parse("$baseUrl/reminders/$reminderId"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("DeleteReminder error: $e");
      return null;
    }
  }

  static Future<String?> getSavedToken() async {
    try {
      return await _storage.read(key: "access_token");
    } catch (e) {
      debugPrint("Read secure token error: $e");
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await _storage.delete(key: "access_token");
    } catch (e) {
      debugPrint("Delete secure token error: $e");
    }
  }
}
