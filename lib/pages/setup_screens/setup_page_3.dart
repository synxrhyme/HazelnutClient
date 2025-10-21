import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hazelnut/main.dart";
import "package:hazelnut/theme.dart";
import "package:hazelnut/utils/websocket_service.dart";
import "package:hazelnut/utils/loading_provider.dart";
import "package:hazelnut/utils/event_provider.dart";

class SetupPage3 extends ConsumerStatefulWidget {
  final String username;
  SetupPage3({super.key, required this.username});

  @override
  ConsumerState<SetupPage3> createState() => _SetupPage3State();
}

class _SetupPage3State extends ConsumerState<SetupPage3> {
  late EventProvider eventProvider;
  late EventCallback registerCallback;

  void sendRegistration(BuildContext context, CustomColors theme) async {
    String fcmToken = await secureStorage.getToken("fcmToken");

    if (!context.mounted) return;

    if (widget.username == "") {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.up,
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 110, left: 15, right: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.error_outline_rounded, color: theme.warning.shade400),
              Text(
                'Der Username ist noch nicht gesetzt!',
                style: TextStyle(
                  color: theme.warning.shade500,
                  fontFamily: "Space Grotesk"
                ),
                textAlign: TextAlign.center
              ),
            ],
          ),
          duration: Duration(seconds: 5),
          backgroundColor: theme.background.shade700,
        ),
      );

      return;
    }
    
    ref.read(loadingServiceProvider).show();

    Map<String, dynamic> request = {
      "header": "registration",
      "body": {
        "username": widget.username.toString(),
        "fcmToken": fcmToken.toString(),
      }
    };

    debugPrint(jsonEncode(request));
    WebSocketService().sendMessage(jsonEncode(request));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Container(
      color: theme.background.shade600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14),
            child: Text(
              "Fast fertig!\n\nKlicke auf 'Setup abschließen', um Hazelnut nutzen zu können!",
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                height: 1.8,
                fontSize: 19,
                fontFamily: "Space Grotesk",
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 80, bottom: 50),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(theme.background.shade400),
                foregroundColor: WidgetStatePropertyAll(theme.info.shade300),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
                ),
                padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>(
                  (Set<WidgetState> states) {
                    return EdgeInsets.only(top: 15, right: 40, bottom: 15, left: 40);
                  },
                ),
              ),
              onPressed: () => sendRegistration(context, theme),
              child: Text("Setup abschließen"),
            ),
          )
        ],
      ),
    );
  }
}