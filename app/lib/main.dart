import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hazelnut/deps.dart";
import "package:hazelnut/utils/life_cycle_handler.dart";
import "package:hazelnut/utils/main_init.dart";
import "package:hazelnut/utils/route_observer.dart";
import "package:hazelnut/utils/snackbar_utils.dart";
import "package:flutter/material.dart";
import "package:hazelnut/theme.dart";
import "package:hazelnut/utils/loading_provider.dart";
import "package:hazelnut/utils/event_provider.dart";
import "package:hazelnut_ui/pages/home_page.dart";
import "package:hazelnut_ui/pages/setup_page.dart";
import "package:hazelnut_shared/app_dependencies.dart";

final EventProvider eventProviderGlobal       = EventProvider();
final GlobalKey<NavigatorState> navigatorKey  = GlobalKey<NavigatorState>();
final ProviderContainer container = ProviderContainer();

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final routeObserver = GlobalRouteObserver();
bool firebaseBackgroundInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await createDependencies();
  bool initialized = await dependencies.prefsService.getBool("initialized") ?? false;

  container.updateOverrides([
    appDependenciesProvider.overrideWithValue(dependencies),
  ]);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyAppLifecycleHandler(
        child: HazelnutApp()
      )
    )
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (initialized) return;
    final secureStorage = dependencies.secureStorageService;

    await initFirebase(secureStorage);
    await initFullServices();
    initialized = true;

    // UI listener for logic-triggered snackbars
    try {
      dependencies.webSocketBus.on('SHOW_SNACKBAR').listen((payload) {
        try {
          final p = payload as Map<String, dynamic>;
          final ctx = rootScaffoldMessengerKey.currentContext;
          if (ctx == null) return;
          final theme = Theme.of(ctx).extension<CustomColors>()!;

          final title = p['title']?.toString() ?? '';
          final type = p['type']?.toString() ?? 'info';

          IconData icon = Icons.info_outline_rounded;
          Color color1 = theme.info.shade500!;
          Color color2 = theme.info.shade400!;
          if (type == 'error') {
            icon = Icons.error_outline_rounded;
            color1 = theme.warning.shade500!;
            color2 = theme.warning.shade400!;
          }

          final heightOffset = (p['heightOffset'] is num) ? (p['heightOffset'] as num).toDouble() : 50.0;

          showAnimatedSnackbarGlobal(
            icon: icon,
            color1: color1,
            color2: color2,
            title: title,
            heightOffset: heightOffset,
          );
        } catch (_) {}
      });
    } catch (_) {}
  });
}

class HazelnutApp extends ConsumerWidget {
  const HazelnutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingService = ref.watch(loadingServiceProvider);
    final prefsService = ref.watch(appDependenciesProvider).prefsService;

    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      title: "Hazelnut",
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: ThemeMode.system,
      home: FutureBuilder(
        future: prefsService.getBool("setupComplete"),
        builder: (context, asyncSnapshot) {
          if (!asyncSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(
              color: Colors.deepOrange,
            ));
          }

          return Stack(
            children: [
              asyncSnapshot.data! ? HomePage() : SetupPage(),
    
              if (loadingService.isLoading)
                Builder(
                  builder: (context) {
                    final theme = Theme.of(context).extension<CustomColors>()!;
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