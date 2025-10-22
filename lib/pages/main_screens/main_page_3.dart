import 'package:flutter/material.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:hazelnut/utils/message_provider.dart';
import 'package:hazelnut/utils/navigation_mode_helper.dart';

class MainPage3 extends StatefulWidget {
  const MainPage3({super.key});

  @override
  State<MainPage3> createState() => _MainPage3State();
}

class _MainPage3State extends State<MainPage3> {
  bool showChats = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() async => await ChatProvider().loadChats());
    Future.microtask(() async => await MessageProvider().loadAll());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: NavigationModeHelper().navigationMode == "gesture" ? false : true,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => setState(() { showChats = !showChats; }),
            child: Text("change"),
          ),
          Expanded(
            child: showChats ?
              ListView.builder(
                itemCount: ChatProvider().chats.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(ChatProvider().chats[index].chatName),
                    subtitle: Text("${ChatProvider().chats[index].createdByName} -- ${ChatProvider().chats[index].chatId}"),
                  );
                }  
              )
          
              :
          
              ListView.builder(
                itemCount: MessageProvider().messagesForChat(0).length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("${MessageProvider().messagesForChat(0)[index].senderName} -- ${MessageProvider().messagesForChat(0)[index].uId.toString()}"),
                    subtitle: Text("${MessageProvider().messagesForChat(0)[index].text} -- ${MessageProvider().messagesForChat(0)[index].sentTimestamp}"),
                  );
                }  
              ),
          ),
        ],
      ),
    );
  }
}