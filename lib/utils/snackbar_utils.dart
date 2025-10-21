import 'package:flutter/material.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/theme.dart';

bool showingError = false;

void showSnackBar(String title, int type) {
  if (showingError) return;
  showingError = true;

  Color? color1;
  Color? color2;

  IconData? icon;

  final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

  switch (type) {
    case 0:
      color1 = theme.warning.shade500;
      color2 = theme.warning.shade500;
      icon = Icons.error_outline_rounded;
    case 1:
      color1 = theme.info.shade500;
      color2 = theme.info.shade400;
      icon = Icons.error_outline_rounded;
    case 2:
      color1 = theme.success.shade500;
      color2 = theme.success.shade500;
      icon = Icons.check_circle_outline;
  }

  final window = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = window.physicalSize / window.devicePixelRatio;

  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.up,
      margin: EdgeInsets.only(bottom: size.height - 110, left: 15, right: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, color: color1),
          Text(
            title,
            style: TextStyle(
              color: color2,
              fontFamily: "Space Grotesk"
            ),
            textAlign: TextAlign.center
          ),
        ],
      ),
      duration: Duration(seconds: 2),
      backgroundColor: Color(0xFF000000),
    ),
  ).closed.then((_) {
    showingError = false;
  });
}

  void showWebsocketErrorSnackbar() {
    if (showingError) return;
    showingError = true;

    final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(rootScaffoldMessengerKey.currentContext!).size.height - 110,
          left: 15,
          right: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.wifi_off_rounded, color: theme.error.shade600, size: 30),
            Text(
              'Es gab ein Problem beim\nVerbindungsaufbau zum Server',
              style: TextStyle(
                color: theme.error.shade500,
                fontFamily: "Space Grotesk"
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: theme.background.shade800,
      ),
    ).closed.then((_) {
      showingError = false;
    });
  }