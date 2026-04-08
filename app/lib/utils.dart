import "dart:convert";
import 'package:characters/characters.dart';
import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";

Future<void> requestPermission({required Permission permission}) async {
  await permission.request();
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

String sanitizeRawInput(
  String? input, {
  int maxLength = 2000,
  bool forDisplay = false,
}) {
  if (input == null) return '';

  var sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
  sanitized = sanitized.trim();

  // Zeichenbegrenzung (unicode-safe)
  if (sanitized.characters.length > maxLength) {
    sanitized = sanitized.characters.take(maxLength).toString();
  }

  if (forDisplay) {
    sanitized = const HtmlEscape().convert(sanitized);
  }

  return sanitized;
}