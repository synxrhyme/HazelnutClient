import 'package:flutter/material.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:hazelnut/utils/database_service.dart';
import 'package:hazelnut/utils/message_provider.dart';

class MainPage3 extends StatefulWidget {
  const MainPage3({super.key});

  @override
  State<MainPage3> createState() => _MainPage3State();
}

class _MainPage3State extends State<MainPage3> {
  int showing = 0;

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
      bottom: true,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => setState(() {
              if (showing > 1) { showing = 0; }
              else { showing += 1; }
            }),
            child: Text("change"),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                switch (showing) {
                  case 0: return ListView.builder(
                    itemCount: ChatProvider().chats.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(ChatProvider().chats[index].chatName),
                        subtitle: Text("${ChatProvider().chats[index].createdByName} -- ${ChatProvider().chats[index].chatId}"),
                      );
                    }
                  );

                  case 1: return ListView.builder(
                    itemCount: MessageProvider().messagesForChat(0).length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text("${MessageProvider().messagesForChat(0)[index].senderName} -- ${MessageProvider().messagesForChat(0)[index].uId.toString()}"),
                        subtitle: Text("${MessageProvider().messagesForChat(0)[index].text} -- ${MessageProvider().messagesForChat(0)[index].sentTimestamp}"),
                      );
                    }
                  );

                  case 2: return FutureBuilder(
                    future: DatabaseService().loadAllUsers(),
                    builder: (context, asyncSnapshot) {
                      while (asyncSnapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return ListView.builder(
                        itemCount: asyncSnapshot.data?.length ?? 0,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text("${asyncSnapshot.data?[index].userId} -- ${asyncSnapshot.data?[index].username}"),
                            subtitle: Text("online: ${asyncSnapshot.data?[index].online} -- last seen: ${asyncSnapshot.data?[index].lastSeen}"),
                          );
                        }
                      );
                    }
                  );

                  default: return const SizedBox.shrink();
                }
              }
            ),
          ),
        ],
      ),
    );
  }
}