import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/util.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_ui/components/message_widget.dart';

class ChatList extends ConsumerWidget {
  final int chatId;
  const ChatList({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageProviderProvider).messagesForChat(chatId).reversed.toList();

    return Container(
      color: Colors.black,
      child: messages.isEmpty ? Center(
        child: Text(
          "Keine Nachrichten",
          style: TextStyle(
            color: Theme.of(context).primaryColor.withAlpha(130),
            fontSize: 19,
            fontFamily: "Space Grotesk",
            fontWeight: FontWeight.normal
          ),
        ),
      ) : ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final MessageModel msg = messages[index];
          return MessageWidget(message: msg);
        },
      ),
    );
  }
}