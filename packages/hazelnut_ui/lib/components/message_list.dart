import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/util.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_ui/components/message_widget.dart';
import 'package:hazelnut_ui/theme.dart';

class MessageList extends ConsumerStatefulWidget {
  final int chatId;
  const MessageList({super.key, required this.chatId});

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;
    final List<MessageModel> messages = ref.watch(messageProviderProvider).messagesForChat(widget.chatId).reversed.toList();

    return Container(
      color: theme.neutral.shade800,
      child: messages.isEmpty ? Center(
        child: Text(
          "Keine Nachrichten",
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 19, 
            fontFamily: "Space Grotesk",
            fontWeight: FontWeight.normal
          ),
        ),
      ) : ListView.separated(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final MessageModel msg = messages[index];
          return MessageWidget(message: msg);
        },
        separatorBuilder: (context, index) {
          return Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(
              widthFactor: 1,
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: theme.neutral.shade300,
              ),
            ),
          );
        },
      ),
    );
  }
}