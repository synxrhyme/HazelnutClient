import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/chat_provider.dart';
import 'package:hazelnut_logic/message_provider.dart';
import 'package:hazelnut_logic/util.dart';
import 'package:hazelnut_shared/app_dependencies.dart';
import 'package:hazelnut_shared/database_service.dart';

class MainPage3 extends ConsumerStatefulWidget {
  const MainPage3({super.key});

  @override
  ConsumerState<MainPage3> createState() => _MainPage3State();
}

class _MainPage3State extends ConsumerState<MainPage3> {
  int showing = 0;

  late final ChatProvider chatProvider;
  late final MessageProvider messageProvider;
  late final DatabaseService databaseService;

  @override
  void initState() {
    super.initState();

    chatProvider = ref.watch(chatProviderProvider);
    messageProvider = ref.watch(messageProviderProvider);
    databaseService = ref.watch(appDependenciesProvider).databaseService;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() async => await chatProvider.loadChats());
    Future.microtask(() async => await messageProvider.loadAll());
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
                    itemCount: chatProvider.chats.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(chatProvider.chats[index].chatName),
                        subtitle: Text("${chatProvider.chats[index].createdByName} -- ${chatProvider.chats[index].chatId}"),
                      );
                    }
                  );

                  case 1: return ListView.builder(
                    itemCount: messageProvider.messagesForChat(0).length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text("${messageProvider.messagesForChat(0)[index].senderName} -- ${messageProvider.messagesForChat(0)[index].uId.toString()}"),
                        subtitle: Text("${messageProvider.messagesForChat(0)[index].text} -- ${messageProvider.messagesForChat(0)[index].sentTimestamp}"),
                      );
                    }
                  );

                  case 2: return FutureBuilder(
                    future: databaseService.loadAllUsers(),
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