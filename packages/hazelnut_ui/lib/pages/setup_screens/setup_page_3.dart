import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hazelnut_logic/app_dependencies.dart";
import "package:hazelnut_logic/auth_service.dart";
import "package:hazelnut_ui/theme.dart";

class SetupPage3 extends ConsumerStatefulWidget {
  final String username;
  const SetupPage3({super.key, required this.username});

  @override
  ConsumerState<SetupPage3> createState() => _SetupPage3State();
}

class _SetupPage3State extends ConsumerState<SetupPage3> {
  void _sendRegistration(BuildContext context) {
    if (widget.username == "") {
      ref.read(appDependenciesProvider).webSocketBus.emit("INVALID_SIGNUP_CREDENTIALS", {});
    }

    ref.read(authServiceProvider).signUp(context, widget.username);
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
              onPressed: () => _sendRegistration(context),
              child: Text("Setup abschließen"),
            ),
          )
        ],
      ),
    );
  }
}