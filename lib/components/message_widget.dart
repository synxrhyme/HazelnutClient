import 'package:flutter/material.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils/message_provider.dart';
import 'package:hazelnut/utils/models.dart';

class MessageWidget extends StatefulWidget {
  final MessageModel message;

  MessageWidget({
    super.key,
    required this.message
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  Color color = Colors.grey.shade700;
  String userId = "";

  @override
  void initState() {
    super.initState();
    loadVars();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadVars();
  }

  void loadVars() async {
    final String uId = await secureStorage.getToken("userId");

    setState(() {
      color = getAccentFromString(widget.message.senderId);
      userId = uId;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).extension<CustomColors>()!;

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
                         "${widget.message.senderName} (Du)",
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
                          widget.message.text,
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
      ),
    );
  }
}