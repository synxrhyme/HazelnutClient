import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";

Future<void> requestPermission({required Permission permission}) async {
  final status = await permission.status;

  if (status.isGranted) {
    debugPrint("Permission already granted");
  } else if (status.isDenied) {
    if (await permission.request().isGranted) {
      debugPrint("Permission granted");
    } else {
      debugPrint("Permission denied");
    }
  } else {}
}

/*
Future<void> showNotification(int id, String title, String body) async {
  const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails('hazelnut_channel', 'Hazelnut',
      channelDescription: 'Hazelnut Notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker'
    );

  const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
  await FlutterLocalNotificationsPlugin().show(0, title, body, notificationDetails);
}
*/

List<double> saturationMatrix(double saturation) {
    final double invSat = 1 - saturation;
    final double r = 0.213 * invSat;
    final double g = 0.715 * invSat;
    final double b = 0.072 * invSat;

    return [
      r + saturation, g, b, 0, 0,
      r, g + saturation, b, 0, 0,
      r, g, b + saturation, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }