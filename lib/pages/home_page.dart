import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hazelnut/components/navbar_item.dart';
// ignore: unused_import
import 'package:hazelnut/components/premium_background.dart';

import "../theme.dart";

import 'main_screens/main_page_1.dart';
import 'main_screens/main_page_2.dart';
import 'main_screens/main_page_3.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController pageController = PageController(initialPage: 0, keepPage: true);
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void onItemTapped(int index) {
    if (index == selectedIndex) return;
    setState(() => selectedIndex = index);
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;
    //final mediaQuery = MediaQuery.of(context);
    
    return Scaffold(
      backgroundColor: theme.background.shade800,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          //PremiumBackground(),
          PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => selectedIndex = index),
            children: const [
              MainPage1(key: ValueKey("page1")),
              MainPage2(key: ValueKey("page2")),
              MainPage3(key: ValueKey("page3")),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Stack(
                children: [
                  // Normale Bar (unselected Farben)
                  Container(
                    margin: const EdgeInsets.all(0),
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                    color: Color.fromARGB(100, 35, 35, 35),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        NavBarItem(
                          icon: Icons.group,
                          label: "Chatrooms",
                          selected: selectedIndex == 0,
                          onTap: () => onItemTapped(0),
                          selectedColor: Colors.white,
                          unselectedColor: Theme.of(context).primaryColor,
                        ),
                        NavBarItem(
                          icon: Icons.add_rounded,
                          label: "Hinzufügen",
                          selected: selectedIndex == 1,
                          onTap: () => onItemTapped(1),
                          selectedColor: Colors.white,
                          unselectedColor: Theme.of(context).primaryColor,
                        ),
                        NavBarItem(
                          icon: Icons.settings,
                          label: "Einstellungen",
                          selected: selectedIndex == 2,
                          onTap: () => onItemTapped(2),
                          selectedColor: Colors.white,
                          unselectedColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                  IgnorePointer(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFF1F00),
                            Color(0xFFFF6200),
                            Color(0xFFFF7D00),
                            Color(0xFFFFA300),
                            Color(0xFFFFDF00),
                            Color(0xFFFFFB00),
                          ],
                          stops: [0.0, 0.025, 0.45, 0.5, 0.55, 0.95, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            NavBarItem(
                              icon: Icons.group,
                              label: "Chatrooms",
                              selected: selectedIndex == 0,
                              onTap: null,
                              selectedColor: Colors.white,
                              unselectedColor: Colors.transparent,
                            ),
                            NavBarItem(
                              icon: Icons.add_rounded,
                              label: "Hinzufügen",
                              selected: selectedIndex == 1,
                              onTap: null,
                              selectedColor: Colors.white,
                              unselectedColor: Colors.transparent,
                            ),
                            NavBarItem(
                              icon: Icons.settings,
                              label: "Einstellungen",
                              selected: selectedIndex == 2,
                              onTap: null,
                              selectedColor: Colors.white,
                              unselectedColor: Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      /*
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        selectedItemColor:   const Color.fromARGB(162, 255, 50, 180),
        unselectedItemColor: theme.navbar.unselected,
        backgroundColor:     Colors.transparent,
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.group, size: 27),
            ),
            label: 'Chatrooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_rounded, size: 30),
            label: 'Erstellen',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.settings, size: 27),
            ),
            label: 'Einstellungen',
          ),
        ],
      ),
      */
    );
  }
}