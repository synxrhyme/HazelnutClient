import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/components/notification_icon.dart';
import 'package:hazelnut/pages/chat_screen.dart';
import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:hazelnut/utils/message_provider.dart';
import 'package:hazelnut/utils/models.dart';

class ChatListOrPlaceholder extends ConsumerStatefulWidget {
  const ChatListOrPlaceholder({super.key});

  @override
  ConsumerState<ChatListOrPlaceholder> createState() => _ChatListOrPlaceholderState();
}

class _ChatListOrPlaceholderState extends ConsumerState<ChatListOrPlaceholder> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;
    final List<ChatModel> chats = ref.watch(chatProvider).chats;

    return Expanded(
      child: Container(
        color: Colors.transparent,
        child: chats.isEmpty ?
            
          Container(
            alignment: Alignment(0, -0.5),
            child: Container(
              width: 320,
              height: 155,
              decoration: BoxDecoration(
                color: theme.background.shade700,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.only(
                top: 15,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.info.shade500,
                    size: 26,
                  ),
                  Column(
                    children: [
                      Text(
                        'Du hast noch keine Chats.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Space Grotesk",
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Füge doch welche mit dem "+"-Button hinzu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Space Grotesk",
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )

          :
          
          ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
          
              return Container(
                margin: EdgeInsets.only(bottom: 20),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {                     
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chatId: chat.chatId),
                          settings: RouteSettings(name: "chatId_${chat.chatId}"),
                        ),
                      );
                    },
                    child: Container(
                      height: 70,
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        top: 10,
                        bottom: 10,
                        left: 20,
                        right: 20,
                      ),
                      margin: EdgeInsets.only(
                        top: 0,
                        left: 10,
                        right: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.background.shade700,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: theme.background.shade600,
                            child: Text(
                              chat.chatName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 22,
                                color: getAccentFromString(chat.chatName),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  5,
                                ),
                              ),
                              padding: EdgeInsets.only(
                                left: 20,
                                right: 20,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat.chatName,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor.withAlpha(240),
                                      fontFamily: "Space Grotesk",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "Letzte Nachricht",
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor.withAlpha(200),
                                      fontFamily: "Space Grotesk",
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          NotificationsReceivedIcon(chatId: chat.chatId),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ),
    );
  }
}