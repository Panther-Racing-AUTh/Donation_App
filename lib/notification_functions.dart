import 'package:permission_handler/permission_handler.dart';

Future<void> requestNotificationPermission() async {
  var status = await Permission.notification.request();
  if (status.isGranted) {
    print("✅ Notification Permission Granted");
  } else if (status.isDenied) {
    print("⚠️ Notification Permission Denied");
  } else if (status.isPermanentlyDenied) {
    print("❌ Permission Permanently Denied. Redirecting to settings...");
    openAppSettings(); // Open app settings if permanently denied
  }
}

Future<bool> requestGalleryPermission() async {
  final status = await Permission.photos.request();
  if (!status.isGranted) {
    print("Gallery permission is not granted");
    return false;
  }
  return true;
}