import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hazelnut_logic/app_dependencies.dart";
import "package:hazelnut_logic/secure_storage_service.dart";
import "package:hazelnut_ui/theme.dart";

class SetupPage2 extends ConsumerStatefulWidget {
  final void Function(bool value, String username) callback;
  final TextEditingController controller;
  final String username;

  const SetupPage2({
    super.key,
    required this.controller,
    required this.callback,
    required this.username,
  });

  @override
  ConsumerState<SetupPage2> createState() => _SetupPage2State();
}

class _SetupPage2State extends ConsumerState<SetupPage2> {
  final FocusNode _focusNode = FocusNode();
  late final SecureStorageService secureStorage;

  // Anstatt setState → ValueNotifier für Counter
  final ValueNotifier<int> remainingSpace = ValueNotifier(30);
  final ValueNotifier<Color> remainingColor = ValueNotifier(Colors.blue);

  bool valid = false;
  String username = "";

  @override
  void initState() {
    super.initState();

    secureStorage = ref.watch(appDependenciesProvider).secureStorageService;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.username == "") {
      Future.microtask(() async {
        widget.controller.text = await secureStorage.getToken("username");
      });
    }

    else {
      widget.controller.text = widget.username;
    }

    onChange(widget.controller.text);
  }

  void triggerCallback() {
    widget.callback(valid, username);
  }

  void onChange(String value) {
    bool newValid;
    int newRemainingSpace = 30;
    Color newRemainingColor = Colors.white;

    if (value.isEmpty) {
      newValid = false;
    } else if (value.length > 30) {
      widget.controller.text = value.substring(0, 30);
      widget.controller.selection = TextSelection.fromPosition(TextPosition(offset: 30));
      newValid = true;
      newRemainingSpace = 0;
      newRemainingColor = Colors.red;
    } else {
      newValid = true;
      newRemainingSpace = 30 - value.length;

      if (newRemainingSpace <= 5) {
        newRemainingColor = Colors.red;
      } else if (newRemainingSpace <= 10) {
        newRemainingColor = Colors.orange;
      }
    }

    // Nur diese kleinen Widgets rebuilden
    remainingSpace.value = newRemainingSpace;
    remainingColor.value = newRemainingColor;

    valid = newValid;
    username = value;

    WidgetsBinding.instance.addPostFrameCallback((_) => triggerCallback());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Überleg dir einen guten Namen!",
          style: TextStyle(
            color: Colors.white,
            height: 1.8,
            fontSize: 19,
            fontFamily: "Space Grotesk",
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.only(left: 30, right: 30, top: 30),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  cursorColor: theme.accent.shade600,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: "IBM Sans",
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.neutral.shade600,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        width: 1,
                        color: theme.neutral.shade200!, // Farbe im Ruhezustand
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        width: 1.5,
                        color: theme.accent.shade600!, // Farbe wenn fokussiert
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                  onChanged: onChange,
                  onTapOutside: (event) {
                    _focusNode.unfocus();
                  },
                ),
              ),
              Container(
                width: 20,
                margin: const EdgeInsets.only(left: 10),
                child: ValueListenableBuilder<int>(
                  valueListenable: remainingSpace,
                  builder: (_, space, __) {
                    return ValueListenableBuilder<Color>(
                      valueListenable: remainingColor,
                      builder: (_, color, __) {
                        return Text(
                          space.toString(),
                          style: TextStyle(
                            color: color,
                            fontFamily: "Space Grotesk",
                            fontSize: 15,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}