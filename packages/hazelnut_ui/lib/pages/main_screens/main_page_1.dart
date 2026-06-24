import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/chat_provider.dart';
import 'package:hazelnut_ui/components/chat_list_or_placeholder.dart';
import 'package:hazelnut_ui/components/standard_app_bar.dart';
import 'package:hazelnut_ui/theme.dart';

class MainPage1 extends ConsumerStatefulWidget {
  const MainPage1({super.key});

  @override
  ConsumerState<MainPage1> createState() => _MainPage1State();
}

class _MainPage1State extends ConsumerState<MainPage1> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async => await ref.read(chatProviderProvider).loadChats());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: StandardAppBar(theme: theme, title: "Hazelnut Messenger", leading: null),
      backgroundColor: Colors.transparent,
      body: ChatListOrPlaceholder(),
    );
  }
}