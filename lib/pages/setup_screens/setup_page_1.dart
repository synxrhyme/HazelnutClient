import "package:flutter/material.dart";
import "package:hazelnut/theme.dart";

class SetupPage1 extends StatefulWidget {
  const SetupPage1({ super.key });

  @override
  State<SetupPage1> createState() => _SetupPage1State();
}

class _SetupPage1State extends State<SetupPage1> {
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

    return Stack(
      children: [
        Container(
          color: theme.background.shade400,
        ),
        Center(
          child: Text(
            "Authentifizierung kommt noch.",
            style: TextStyle(
              color: Colors.white,
              fontFamily: "Space Grotesk",
              fontSize: 20
            ),
          ),
        ),
      ],
    );
  }
}