import 'package:flutter/services.dart';

class NavigationModeHelper {
  static const platform = MethodChannel('com.example.navigationmode');

  static Future<String> getNavigationMode() async {
    try {
      final String mode = await platform.invokeMethod('getNavigationMode');
      return mode;
    } catch (e) {
      return "unknown";
    }
  }
}