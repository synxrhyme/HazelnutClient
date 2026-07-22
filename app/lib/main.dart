import "package:flutter_native_splash/flutter_native_splash.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:flutter/services.dart';
import "package:hazelnut/init_service.dart";
import "package:hazelnut/life_cycle_handler.dart";
import "package:hazelnut/route_observer.dart";
import "package:flutter/material.dart";
import "package:hazelnut_logic/app_state_provider.dart";
import "package:hazelnut/event_provider.dart";
import "package:hazelnut_logic/loading_provider.dart";
import "package:hazelnut_ui/pages/main_page.dart";
import "package:hazelnut_ui/pages/setup_page.dart";
import "package:hazelnut_ui/theme.dart";

final EventProvider eventProviderGlobal = EventProvider();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final routeObserver = GlobalRouteObserver();
bool firebaseBackgroundInitialized = false;

late final ProviderContainer container;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const _InitWrapper());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  });
}

// Kein ConsumerStatefulWidget mehr nötig – kein ref gebraucht
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
    _initFuture = InitService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightMode,
            darkTheme: darkMode,
            themeMode: ThemeMode.system,
            home: Scaffold(body: Center(child: Text('Fehler: ${snapshot.error}'))),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightMode,
            darkTheme: darkMode,
            themeMode: ThemeMode.system,
            home: const _LoadingScreen(),
          );
        }

        return UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            navigatorKey:         navigatorKey,
            navigatorObservers:   [routeObserver],
            debugShowCheckedModeBanner: false,
            title:     "Hazelnut",
            theme:     lightMode,
            darkTheme: darkMode,
            themeMode: ThemeMode.system,
            home: MyAppLifecycleHandler(child: const HazelnutApp()),
            builder: (context, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarContrastEnforced: false,
                  systemNavigationBarIconBrightness: Brightness.light,
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final loadingService = ref.watch(loadingServiceProvider);
                    return Stack(
                      children: [
                        child!,
                        if (loadingService.isLoading)
                          Builder(builder: (context) {
                            final theme = Theme.of(context).extension<CustomColors>()!;
                            return Container(
                              color: Colors.black54,
                              child: Center(
                                child: CircularProgressIndicator(color: theme.accent.shade500),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Kein MaterialApp mehr – gibt nur den eigentlichen Inhalt zurück
class HazelnutApp extends ConsumerWidget {
  const HazelnutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupComplete  = ref.watch(setupCompleteProvider);
    return setupComplete ? const HomePage() : const SetupPage();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: theme.accent.shade500),
      ),
    );
  }
}