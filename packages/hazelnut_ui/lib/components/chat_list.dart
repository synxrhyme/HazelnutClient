import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/util.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_ui/components/message_widget.dart';

class ChatList extends ConsumerStatefulWidget {
  final int chatId;
  const ChatList({super.key, required this.chatId});

  @override
  ConsumerState<ChatList> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  late List<MessageModel> messages;

  @override
  void initState() {
    super.initState();
    messages = ref.watch(messageProviderProvider).messagesForChat(widget.chatId).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
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