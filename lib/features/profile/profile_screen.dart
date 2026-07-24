import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../reminders/reminder_screen.dart';
import 'edit_profile_screen.dart';
import 'permissions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final response = await ApiService.getProfile();

    setState(() {
      userData = response?["user"];
      isLoading = false;
    });
  }

  Future<void> openEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: userData?["full_name"] ?? "",
          currentEmail: userData?["email"] ?? "",
        ),
      ),
    );

    if (updated == true) {
      setState(() {
        isLoading = true;
      });

      await loadProfile();
    }
  }

  Future<void> openPermissions() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PermissionsScreen()),
    );
  }

  Future<void> handleLogout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header(),
                    const SizedBox(height: 28),
                    profileCard(context),
                    const SizedBox(height: 28),
                    const Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    settingsCard(context),
                    const SizedBox(height: 30),
                    logoutButton(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "Profile",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Icon(Icons.settings_outlined),
      ],
    );
  }

  Widget profileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: whiteCard(),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFC8FFF3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.teal,
              size: 36,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData?["full_name"] ?? "User",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  userData?["email"] ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: openEditProfile,
            child: const Text(
              "Edit",
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget settingsCard(BuildContext context) {
    return Container(
      decoration: whiteCard(),
      child: Column(
        children: [
          settingItem(
            context,
            icon: Icons.person_outline,
            iconColor: Colors.blue,
            title: "Personal Information",
            onTap: openEditProfile,
          ),
          divider(),
          settingItem(
            context,
            icon: Icons.shield_outlined,
            iconColor: Colors.purple,
            title: "App Permissions",
            onTap: openPermissions,
          ),
          divider(),
          settingItem(
            context,
            icon: Icons.notifications_none,
            iconColor: Colors.orange,
            title: "Notifications",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReminderScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget settingItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget logoutButton(BuildContext context) {
    return GestureDetector(
      onTap: handleLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Log out",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget divider() {
    return Divider(height: 1, color: Colors.grey.shade200);
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
