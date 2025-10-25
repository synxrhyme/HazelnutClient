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

  class _AnimatedSnackbar extends StatefulWidget {
  final IconData icon;
  final Color color1;
  final Color color2;
  final String title;
  final double heightOffset;
  final VoidCallback onDismissed;

  const _AnimatedSnackbar({
    required this.icon,
    required this.color1,
    required this.color2,
    required this.title,
    required this.heightOffset,
    required this.onDismissed,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(Duration(seconds: 2), () {
      _controller.reverse().then((_) => widget.onDismissed());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.heightOffset,
      left: 15,
      right: 15,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(7),
          color: Color(0xFF000000),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(widget.icon, color: widget.color1),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.color2,
                      fontFamily: "Space Grotesk",
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showAnimatedSnackbar({
  required BuildContext context,
  required IconData icon,
  required Color color1,
  required Color color2,
  required String title,
  required double heightOffset,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _AnimatedSnackbar(
      icon: icon,
      color1: color1,
      color2: color2,
      title: title,
      heightOffset: heightOffset,
      onDismissed: () {
        overlayEntry.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);
}