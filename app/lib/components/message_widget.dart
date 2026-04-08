import 'package:flutter/material.dart';
import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils.dart';
import 'package:hazelnut/utils/message_provider.dart';
import 'package:hazelnut/utils/models.dart';

class MessageWidget extends StatelessWidget {
  final MessageModel message;

  MessageWidget({
    super.key,
    required this.message
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;
    final userId = MessageProvider().userId ?? "";
    final color = getAccentFromString(message.senderName);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 5, left: 15, right: 15, top: 5),
      padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.background.shade700,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.background.shade400,
            child: Text(
              message.senderName[0].toUpperCase(),
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
                         "${sanitizeRawInput(message.senderName, maxLength: 30, forDisplay: true)}${message.senderId == userId ? " (Du)" : ""}",
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
                          sanitizeRawInput(message.text, maxLength: 65535, forDisplay: true),
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

                  if (message.pending == 1)
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
      ),
    );
  }
}