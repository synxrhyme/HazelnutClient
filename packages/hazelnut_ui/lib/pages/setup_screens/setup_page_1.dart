import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hazelnut_logic/app_dependencies.dart";
import "package:hazelnut_ui/theme.dart";

class SetupPage1 extends ConsumerStatefulWidget {
  final void Function(bool value) callback;
  const SetupPage1({ super.key, required this.callback });

  @override
  ConsumerState<SetupPage1> createState() => _SetupPage1State();
}

class _SetupPage1State extends ConsumerState<SetupPage1> {
  bool active = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final value = await ref.read(appDependenciesProvider).prefsService.getBool("notifications");
      if (mounted) {
        setState(() => active = value ?? false);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onYes() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    setState(() => active = true);
    ref.read(appDependenciesProvider).prefsService.setBool("notifications", active);
    widget.callback(true);
  }

  void _onNo() {
    setState(() => active = false);
    ref.read(appDependenciesProvider).prefsService.setBool("notifications", active);
    widget.callback(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Benachrichtigungen erhalten?",
              style: TextStyle(
                color: Colors.white,
                fontFamily: "Space Grotesk",
                fontSize: 19
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Hazelnut informiert dich über neue Nachrichten, auch wenn die App geschlossen ist.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontFamily: "Space Grotesk",
                fontSize: 15
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _onYes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: active == true
                        ? theme.success.shade600
                        : theme.neutral.shade400,
                    foregroundColor: active == true
                        ? Colors.white
                        : Colors.white.withAlpha(160),
                  ),
                  child: Text("Ja"),
                ),
                ElevatedButton(
                  onPressed: _onNo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: active == false
                        ? theme.error.shade600
                        : theme.neutral.shade400,
                    foregroundColor: active == false
                        ? Colors.white
                        : Colors.white.withAlpha(160),
                  ),
                  child: Text("Nein"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}