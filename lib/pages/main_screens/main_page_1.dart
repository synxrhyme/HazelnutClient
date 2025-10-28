import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/components/chat_list_or_placeholder.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:hazelnut/pages/add_chat_screen.dart';
import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils/models.dart';
import 'package:hazelnut/utils/snackbar_utils.dart';

class MainPage1 extends StatefulWidget {
  const MainPage1({super.key});

  @override
  State<MainPage1> createState() => _MainPage1State();
}

class _MainPage1State extends State<MainPage1> {
  List<ChatModel> chats = ChatProvider().chats;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async => await ChatProvider().loadChats());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() async => await ChatProvider().loadChats());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Column(
      children: [
        Container(
          color: theme.background.shade700,
          child: SafeArea(
            top: true,
            left: false,
            right: false,
            bottom: true,
            child: Container(),
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 5, bottom: 10),                                                         // top bar
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            color: theme.background.shade700,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(left: 20),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 255, 13, 0),
                        Color.fromARGB(255, 255, 125, 0),
                        Color.fromARGB(255, 255, 217, 0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Text(
                    "Hazelnut Messenger",
                    style: TextStyle(
                      fontFamily: "Space Grotesk",
                      color: Colors.white.withAlpha(200),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 20, left: 30),
                  padding: EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(5),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  transitionDuration: Duration(
                                    milliseconds: 300,
                                  ),
                                  reverseTransitionDuration: Duration(
                                    milliseconds: 300,
                                  ),
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => AddChatScreen(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        // Animation beim Rein- und Rausgehen
                                        final inAnimation =
                                            Tween<Offset>(
                                              begin: Offset(0.0, 1.0),
                                              end: Offset.zero,
                                            ).chain(
                                              CurveTween(
                                                curve: Curves.easeInOut,
                                              ),
                                            );
                                            
                                        final outAnimation =
                                            Tween<Offset>(
                                              begin: Offset.zero,
                                              end: Offset(0.0, 1.0),
                                            ).chain(
                                              CurveTween(
                                                curve: Curves.easeInOut,
                                              ),
                                            );
                                            
                                        return SlideTransition(
                                          position: animation.drive(
                                            inAnimation,
                                          ),
                                          child: SlideTransition(
                                            position: secondaryAnimation.drive(
                                              outAnimation,
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                ),
                              );
                                            
                              //chatProvider.addItem(ChatWidget());
                            },
                            child: SizedBox(
                              width: 50,
                              height: 40,
                              child: Center(
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 35,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          return ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(5),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  showAnimatedSnackbarGlobal(
                                    icon: Icons.warning,
                                    color1: Colors.yellow,
                                    color2: Colors.white,
                                    title: "Test!",
                                    heightOffset: 50,
                                  );
                                },
                                child: SizedBox(
                                  width: 50,
                                  height: 40,
                                  child: Icon(
                                    Icons.edit,
                                    size: 25,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        ChatListOrPlaceholder(),
      ],
    );
  }
}
