import "package:permission_handler/permission_handler.dart";

Future<void> requestPermission({required Permission permission}) async {
  await permission.request();
}

/*
Future<void> showLocalNotification(int id, String title, String body) async {
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