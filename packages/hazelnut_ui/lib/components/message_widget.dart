import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/util.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_ui/theme.dart';

class MessageWidget extends ConsumerStatefulWidget {
  final MessageModel message;

  const MessageWidget({
    super.key,
    required this.message
  });

  @override
  ConsumerState<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends ConsumerState<MessageWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;
    final userId = ref.read(messageProviderProvider).userId ?? "";
    final color = getAccentFromString(widget.message.senderName);

    return Container(
      color: Colors.green,
      height: 50,
      width: double.infinity,
      /*child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.neutral.shade400,
            child: Text(
              widget.message.senderName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 19,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.transparent,
              margin: EdgeInsets.only(top: 3, bottom: 3, right: 5, left: 15),
              padding: EdgeInsets.only(top: 2, bottom: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${sanitizeRawInput(widget.message.senderName, maxLength: 30, forDisplay: true)}${widget.message.senderId == userId ? " (Du)" : ""}",
                          style: TextStyle(
                            color: color.withAlpha(200),
                            fontFamily: "Space Grotesk",
                            fontSize: 13,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          sanitizeRawInput(widget.message.text, maxLength: 65535, forDisplay: true),
                          softWrap: true,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor.withAlpha(230),
                            fontFamily: "Space Grotesk",
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (widget.message.pending == 1)
                  Icon(
                    Icons.pending_rounded,
                    color: Colors.grey.shade700,
                    size: 12,
                  ),
                ],
              ),
            ),
          )
        ],
      ),*/
    );
  }
}