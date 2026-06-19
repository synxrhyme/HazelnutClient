import 'package:flutter/material.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut_shared/app_dependencies.dart';
import 'package:hazelnut_shared/preferences_service.dart';

final ValueNotifier<int> rebuildNotificationNumberTrigger = ValueNotifier(0);

class NotificationsReceivedIcon extends StatefulWidget {
  final int chatId;
  const NotificationsReceivedIcon({super.key, required this.chatId});

  @override
  State<NotificationsReceivedIcon> createState() => _NotificationsReceivedIconState();
}

class _NotificationsReceivedIconState extends State<NotificationsReceivedIcon> {
  @override
  Widget build(BuildContext context) {
    final dependencies = container.read(appDependenciesProvider);
    final PreferencesService prefs = dependencies.prefsService;

    return ValueListenableBuilder(
      valueListenable: rebuildNotificationNumberTrigger,
      builder: (context, _, __) {
        return FutureBuilder(
          future: prefs.getInt("chat_${widget.chatId}"),
          builder: (context, asyncSnapshot) {
            while (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                width: 30,
                height: 30,
              );
            }

            if (asyncSnapshot.data != null && asyncSnapshot.data != 0) {
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1000),
                    color: Colors.lightGreen.withAlpha(160)
                  ),
                  width: 27,
                  height: 27,
                  child: Center(
                    child: Text(
                      asyncSnapshot.data.toString(),
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 14,
                        fontFamily: "Space Grotesk"
                      ),
                    ),
                  ),
                ),
              );
            }

            else {
              return SizedBox.shrink();
            }
          }
        );
      }
    );
  }
}