import 'package:flutter/material.dart';
import 'package:hazelnut/utils/preferences_utils.dart';

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
    return ValueListenableBuilder(
      valueListenable: rebuildNotificationNumberTrigger,
      builder: (context, _, __) {
        return FutureBuilder(
          future: PreferencesUtils().getInt("chat_${widget.chatId}"),
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