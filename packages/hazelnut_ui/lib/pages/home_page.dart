import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/app_dependencies.dart';
import 'package:hazelnut_logic/message_provider.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/util.dart';
import "package:hazelnut_ui/pages/main_screens/main_page_1.dart";
import "package:hazelnut_ui/pages/main_screens/main_page_2.dart";
import "package:hazelnut_ui/pages/main_screens/main_page_3.dart";
import 'package:hazelnut_ui/theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController pageController = PageController(initialPage: 0, keepPage: true);
  int selectedIndex = 0;

  late final SecureStorageService secureStorage;
  late final MessageProvider messageProvider;

  @override
  void initState() {
    super.initState();
    secureStorage = ref.watch(appDependenciesProvider).secureStorageService;
    messageProvider = ref.watch(messageProviderProvider);

    messageProvider.loadUserId(secureStorage);

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
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.neutral.shade800,
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.neutral.shade400!)),
                    color: theme.neutral.shade700,
                  ),
                  child: SizedBox(height: 60, width: double.infinity),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: BottomNavigationBar(
                    currentIndex: selectedIndex,
                    onTap: onItemTapped,
                    backgroundColor: Colors.transparent,
                    selectedItemColor: theme.navbar.selected,
                    unselectedItemColor: theme.navbar.unselected,
                    selectedFontSize: 14,
                    unselectedFontSize: 12,
                    selectedLabelStyle: TextStyle(fontFamily: "IBM Sans", fontWeight: FontWeight.w500),
                    unselectedLabelStyle: TextStyle(fontFamily: "IBM Sans", fontWeight: FontWeight.w400),
                    items: [
                      BottomNavigationBarItem(
                        icon: Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.group, size: 27)),
                        label: 'Chatrooms',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.add_rounded, size: 30),
                        label: 'Erstellen',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(padding: EdgeInsets.only(top: 5), child: Icon(Icons.settings, size: 26)),
                        label: 'Einstellungen',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ]
      ),
    );
  }
}