import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hazelnut/main.dart';

OverlayEntry? _currentSnackbarEntry;
Timer? _dismissTimer;
String? _currentMessage;
AnimatedSnackbarController? _currentController;

class AnimatedSnackbarController {
  VoidCallback? _onDismiss;
  void dismiss() => _onDismiss?.call();
}

class _AnimatedSnackbar extends StatefulWidget {
  final IconData icon;
  final Color color1;
  final Color color2;
  final String title;
  final double heightOffset;
  final VoidCallback onDismissed;
  final AnimatedSnackbarController? controller;

  const _AnimatedSnackbar({
    required this.icon,
    required this.color1,
    required this.color2,
    required this.title,
    required this.heightOffset,
    required this.onDismissed,
    this.controller,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    widget.controller?._onDismiss = dismiss;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  Future<void> dismiss() async {
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    widget.controller?._onDismiss = null;
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
          color: const Color(0xFF000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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

void showAnimatedSnackbarGlobal({
  required IconData icon,
  required Color color1,
  required Color color2,
  required String title,
  required double heightOffset,
}) {
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) {
    debugPrint("Kein Overlay gefunden - App evtl. noch nicht aufgebaut?");
    return;
  }

  if (_currentMessage == title && _currentSnackbarEntry != null) {
    _resetDismissTimer();
    return;
  }

  _dismissCurrentSnackbar();

  final controller = AnimatedSnackbarController();
  _currentController = controller;

  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => _AnimatedSnackbar(
      icon: icon,
      color1: color1,
      color2: color2,
      title: title,
      heightOffset: heightOffset,
      controller: controller,
      onDismissed: () {
        if (overlayEntry == _currentSnackbarEntry) {
          _currentSnackbarEntry = null;
          _currentMessage = null;
          _currentController = null;
        }
        overlayEntry.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);
  _currentSnackbarEntry = overlayEntry;
  _currentMessage = title;

  _startDismissTimer(() {
    controller.dismiss();
  });
}

void _startDismissTimer(VoidCallback onDone) {
  _dismissTimer?.cancel();
  _dismissTimer = Timer(const Duration(seconds: 2), onDone);
}

void _resetDismissTimer() {
  if (_dismissTimer == null) return;
  _dismissTimer!.cancel();

  _dismissTimer = Timer(const Duration(seconds: 2), () {
    _currentController?.dismiss();
  });
}

void _dismissCurrentSnackbar() {
  _dismissTimer?.cancel();
  _dismissTimer = null;

  _currentController?.dismiss();
  _currentController = null;
}
