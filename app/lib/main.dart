import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hazelnut/init_service.dart";
import "package:hazelnut/life_cycle_handler.dart";
import "package:hazelnut/route_observer.dart";
import "package:flutter/material.dart";
import "package:hazelnut_logic/app_state_provider.dart";
import "package:hazelnut_ui/loading_provider.dart";
import "package:hazelnut/event_provider.dart";
import "package:hazelnut_ui/pages/home_page.dart";
import "package:hazelnut_ui/pages/setup_page.dart";
import "package:hazelnut_ui/theme.dart";

final EventProvider eventProviderGlobal = EventProvider();
final ProviderContainer container = ProviderContainer();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final routeObserver = GlobalRouteObserver();
bool firebaseBackgroundInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const _InitWrapper(),
    ),
  );
}

class _InitWrapper extends StatefulWidget {
  const _InitWrapper();

  @override
  State<_InitWrapper> createState() => _InitWrapperState();
}

class _InitWrapperState extends State<_InitWrapper> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = InitService.initialize(); // einmal gespeichert, nie neu erzeugt
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Fehler: ${snapshot.error}')),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: _LoadingScreen(),
          );
        }
        return MyAppLifecycleHandler(child: const HazelnutApp());
      },
    );
  }
}

class HazelnutApp extends ConsumerWidget {
  const HazelnutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingService = ref.watch(loadingServiceProvider);
    final setupComplete = ref.watch(setupCompleteProvider);

    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      title: "Hazelnut",
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: ThemeMode.system,
      home: Stack(
        children: [
          setupComplete ? const HomePage() : const SetupPage(),
          if (loadingService.isLoading)
            Builder(builder: (context) {
              final theme = Theme.of(context).extension<CustomColors>()!;
              return Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(color: theme.info.shade500),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      ),
    );
  }
}