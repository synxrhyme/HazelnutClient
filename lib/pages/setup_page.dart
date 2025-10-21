import "package:flutter/services.dart";
import "package:hazelnut/main.dart";
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/material.dart';

import "package:hazelnut/pages/setup_screens/setup_page_1.dart";
import "package:hazelnut/pages/setup_screens/setup_page_2.dart";
import "package:hazelnut/pages/setup_screens/setup_page_3.dart";

import "package:hazelnut/theme.dart";

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPage();
}

class _SetupPage extends State<SetupPage> {
  final TextEditingController usernameController = TextEditingController();
  final PageController pageController = PageController();
  bool onLastPage = false;
  bool onFirstPage = true;

  bool canGoNextPage = true;
  int _index = 0;

  String username = "";

  List<Color> appBarList = [
    Color(0xFF262626),
    Color(0xFF1F1F1F),
    Color(0xFF1A1A1A),
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      )
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        color: appBarList[_index],
        child: SafeArea(
          top: true,
          left: false,
          right: false,
          bottom: true,
          child: Stack(
            children: [
              PageView(
                physics: NeverScrollableScrollPhysics(),
                controller: pageController,
                onPageChanged: (index) {
                  setState(() {
                    _index = index;
                    onFirstPage = (index == 0);
                    onLastPage  = (index == 2);
          
                    if (onFirstPage || onLastPage) canGoNextPage = true;
                  });
                },
                children: [
                  SetupPage1(),
                  SetupPage2(
                    controller: usernameController,
                    callback: (value, name) {
                      setState(() {
                        canGoNextPage = value;
                      });

                      username = name;
                    },
                    username: username,
                  ),
                  SetupPage3(username: username),
                ],
              ),
          
              Container(
                width: double.infinity,
                alignment: Alignment(0, 0.7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    onFirstPage ?
              
                      SizedBox(width: 90)
              
                      :
              
                      SizedBox(
                        width: 90,
                        height: 35,
                        child: GestureDetector(
                          onTap: () => {
                            pageController.previousPage(duration: Duration(milliseconds: 250), curve: Curves.easeOut),
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: theme.background.shade300,
                            ),
                            child: Text("zurück", style: TextStyle(fontFamily: "Space Grotesk", color: Colors.white))
                          ),
                        ),
                      ),  
              
                    SmoothPageIndicator(
                      controller: pageController,
                      count: 3,
                      effect: ExpandingDotsEffect(
                        dotColor:       theme.info.shade700!,
                        activeDotColor: theme.info.shade600!,
                      ),  
                    ),
              
                    onLastPage ?
              
                      SizedBox(width: 90)
              
                      :
              
                      SizedBox(
                        width: 90,
                        height: 35,
                        child: GestureDetector(
                          onTap: canGoNextPage ? () {
                            if (_index == 2) secureStorage.saveToken("username", username);
                            pageController.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeOut);
                          } : null,
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.only(top: 5, right: 10, bottom: 5, left: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: canGoNextPage ? theme.background.shade300 : theme.background.shade400,
                            ),
                            child: Text("weiter", style: TextStyle(fontFamily: "Space Grotesk", color: canGoNextPage ? Colors.white : Colors.grey.shade500))
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}