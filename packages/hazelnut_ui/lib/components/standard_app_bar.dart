import 'package:flutter/material.dart';
import 'package:hazelnut_ui/theme.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StandardAppBar({
    super.key,
    required this.theme,
    required this.title,
    required this.leading,
  });

  final CustomColors theme;
  final String title;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 60,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: Container(
          height: 1,
          color: theme.neutral.shade400
        ),
      ),
      backgroundColor: theme.neutral.shade700,
      leading: leading,
      title: Row(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 10, top: 7),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: theme.accent.shade400,
                  fontFamily: "Space Grotesk"
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}