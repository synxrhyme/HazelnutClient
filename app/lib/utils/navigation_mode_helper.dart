import 'package:flutter/services.dart';

class NavigationModeHelper {
  NavigationModeHelper._internal() { getNavigationMode(); }

  static final NavigationModeHelper _instance = NavigationModeHelper._internal();
  factory NavigationModeHelper() => _instance;

  static const platform = MethodChannel('com.synxrhyme.navigationmode');
  String? navigationMode;

  void getNavigationMode() async {
    try {
      navigationMode = await platform.invokeMethod('getNavigationMode');
    }
    catch (e) {
      navigationMode = "buttons";
    }
  }
}