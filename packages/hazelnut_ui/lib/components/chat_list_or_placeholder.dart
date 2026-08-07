import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/auth_service.dart';
import 'package:hazelnut_logic/chat_provider.dart';
import 'package:hazelnut_logic/message_provider.dart';
import 'package:hazelnut_logic/util.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_ui/components/notification_icon.dart';
import 'package:hazelnut_ui/components/join_chat_modal_sheet.dart';
import 'package:hazelnut_ui/pages/chat_screen.dart';
import 'package:hazelnut_ui/theme.dart';

class ChatListOrPlaceholder extends ConsumerStatefulWidget {
  const ChatListOrPlaceholder({super.key});

  @override
  ConsumerState<ChatListOrPlaceholder> createState() => _ChatListOrPlaceholderState();
}

class _ChatListOrPlaceholderState extends ConsumerState<ChatListOrPlaceholder> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;
    final String userId = ref.read(authServiceProvider).userId ?? "";
    final List<ChatModel> chats = ref.watch(chatProviderProvider).chats;

    return Container(
      color: Colors.transparent,
      child: chats.isEmpty ?
          
        Container(
          alignment: Alignment(0, -0.5),
          margin: EdgeInsets.only(bottom: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 320,
                height: 155,
                decoration: BoxDecoration(
                  color: theme.neutral.shade600,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.only(
                  top: 15,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.info.shade400,
                      size: 26,
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          'Du hast noch keine Chats.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).primaryTextTheme.labelLarge?.copyWith(color: theme.info.shade400)
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Füge doch welche mit dem "+"-Button hinzu!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).primaryTextTheme.labelSmall?.copyWith(color: theme.info.shade200)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    isDismissible: true,
                    isScrollControlled: true,
                    context: context,
                    backgroundColor: theme.neutral.shade600,
                    builder: ((context) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: JoinChatModal(),
                      );
                    })
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.neutral.shade600
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 10),
                  child: Icon(
                    Icons.add_rounded,
                    color: theme.info.shade400,
                  ),
                )
              ),
            ],
          ),
        )
    
        :
        
        ListView.separated(
          itemCount: chats.length + 1,
          itemBuilder: (context, index) {
            
            if (index == chats.length) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {                     
                      showModalBottomSheet(
                        isDismissible: true,
                        isScrollControlled: true,
                        context: context,
                        backgroundColor: theme.neutral.shade600,
                        builder: ((context) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: JoinChatModal(),
                          );
                        })
                      );
                    },
                    child: Icon(
                      Icons.add_rounded,
                      color: theme.accent.shade400,
                      weight: 1,
                      size: 30,
                    ),
                  ),
                ),
              );
            }

            else {
              final List<MessageModel> messages = ref.watch(messageProviderProvider).messagesForChat(chats[index].chatId);
              MessageModel? lastMessage;
              if (messages.isNotEmpty) lastMessage = messages.last;
              
              return Container(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {                     
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chatId: chats[index].chatId),
                          settings: RouteSettings(name: "chatId_${chats[index].chatId}"),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: theme.neutral.shade600,
                          child: Text(
                            chats[index].chatName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: "Space Grotesk",
                              fontWeight: FontWeight.w800,
                              color: getAccentFromString(chats[index].chatName),
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
                                  chats[index].chatName,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(220),
                                    fontFamily: "IBM Sans",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  ref.watch(messageProviderProvider).messagesForChat(chats[index].chatId).isNotEmpty && lastMessage != null
                                      ? "${lastMessage.senderId == userId ? "Du" : sanitizeRawInput(lastMessage.senderName, maxLength: 30, forDisplay: true)}: ${sanitizeRawInput(lastMessage.text, maxLength: 50, forDisplay: true)}"
                                      : "Keine Nachrichten",
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(150),
                                    fontFamily: "IBM Sans",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        NotificationsReceivedIcon(chatId: chats[index].chatId),
                      ],
                    ),
                  ),
                ),
              );
            }
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