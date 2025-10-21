import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/components/message_widget.dart';
import 'package:hazelnut/utils/message_provider.dart';
import 'package:hazelnut/utils/models.dart';

class ChatList extends ConsumerWidget {
  final int chatId;
  const ChatList({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageProvider).messagesForChat(chatId).reversed.toList();

    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final MessageModel msg = messages[index];
        return MessageWidget(message: msg);
      },
    );
  }
}