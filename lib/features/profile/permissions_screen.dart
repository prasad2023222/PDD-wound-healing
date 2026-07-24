import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  PermissionStatus? cameraStatus;
  PermissionStatus? notificationStatus;
  PermissionStatus? storageStatus;

  @override
  void initState() {
    super.initState();
    loadPermissions();
  }

  Future<void> loadPermissions() async {
    if (kIsWeb) {
      setState(() {
        cameraStatus = PermissionStatus.granted;
        notificationStatus = PermissionStatus.granted;
        storageStatus = PermissionStatus.granted;
      });
      return;
    }

    cameraStatus = await Permission.camera.status;
    notificationStatus = await Permission.notification.status;
    storageStatus = await Permission.storage.status;

    setState(() {});
  }

  Future<void> requestCamera() async {
    if (kIsWeb) return;
    await Permission.camera.request();
    loadPermissions();
  }

  Future<void> requestNotifications() async {
    if (kIsWeb) return;
    await Permission.notification.request();
    loadPermissions();
  }

  Future<void> requestStorage() async {
    if (kIsWeb) return;
    await Permission.storage.request();
    loadPermissions();
  }

  Widget permissionTile({
    required IconData icon,
    required String title,
    required PermissionStatus? status,
    required VoidCallback onTap,
    required Color color,
  }) {
    final granted = status == PermissionStatus.granted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  granted ? "Permission granted" : "Permission not granted",
                  style: TextStyle(color: granted ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: onTap,

            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),

            child: Text(granted ? "Granted" : "Allow"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),

        title: const Text(
          "App Permissions",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            permissionTile(
              icon: Icons.camera_alt_outlined,
              title: "Camera",
              status: cameraStatus,
              onTap: requestCamera,
              color: Colors.blue,
            ),

            permissionTile(
              icon: Icons.notifications_none,
              title: "Notifications",
              status: notificationStatus,
              onTap: requestNotifications,
              color: Colors.orange,
            ),

            permissionTile(
              icon: Icons.storage_outlined,
              title: "Storage",
              status: storageStatus,
              onTap: requestStorage,
              color: Colors.purple,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: kIsWeb ? null : openAppSettings,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                icon: const Icon(Icons.settings),

                label: const Text(
                  "Open Device Settings",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
