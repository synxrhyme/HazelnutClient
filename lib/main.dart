import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hazelnut/utils/main_init.dart";
import "package:hazelnut/utils/navigation_mode_helper.dart";
import "package:hazelnut/utils/secure_storage_service.dart";
import "package:flutter/material.dart";
import "package:hazelnut/theme.dart";
import "package:hazelnut/utils/websocket_service.dart";
import "package:hazelnut/utils/loading_provider.dart";
import "package:hazelnut/utils/event_provider.dart";
import "package:hazelnut/utils/preferences_utils.dart";
import "package:hazelnut/pages/home_page.dart";
import "package:hazelnut/pages/setup_page.dart";

final EventProvider eventProviderGlobal         = EventProvider();
final SecureStorageService secureStorage        = SecureStorageService();

final GlobalKey<NavigatorState> navigatorKey  = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

late final String navigationMode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  navigationMode = await NavigationModeHelper.getNavigationMode();

  await initFirebase(secureStorage);
  await initServices(secureStorage);

  runApp(
    ProviderScope(child: const HazelnutApp()),
  );
}

class HazelnutApp extends ConsumerWidget {
  const HazelnutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingService = ref.watch(loadingServiceProvider);
    WebSocketService().init(ref);

    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorKey: navigatorKey,
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      title: "Hazelnut",
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: ThemeMode.system,
      home: FutureBuilder(
        future: getBool("setupComplete"),
        builder: (context, asyncSnapshot) {
          if (!asyncSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              asyncSnapshot.data! ? HomePage() : SetupPage(),
    
              if (loadingService.isLoading)
                Builder(
                  builder: (context) {
                    var theme = Theme.of(context).extension<CustomColors>()!;
                    return Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.info.shade500,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}