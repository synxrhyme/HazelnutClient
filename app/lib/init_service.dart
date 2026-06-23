import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/deps.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/main_init.dart';
import 'package:hazelnut_logic/app_dependencies.dart';
import 'package:hazelnut_logic/app_state_provider.dart';
import 'package:hazelnut_shared/navigation.dart';
import 'package:hazelnut_ui/pages/setup_page.dart';
import 'package:hazelnut_ui/snackbar_utils.dart';
import 'package:hazelnut_ui/theme.dart';

class InitService {
  static Future<void> initialize() async {
    final dependencies = await createDependencies(navigatorKey);
    final setupComplete = await dependencies.prefsService.getBool("setupComplete") ?? false;

    container = ProviderContainer(
      overrides: [
        appDependenciesProvider.overrideWithValue(dependencies),
        setupCompleteProvider.overrideWithValue(setupComplete),
        navigatorKeyProvider.overrideWithValue(navigatorKey),
      ],
    );

    // alles weitere was vor App-Start fertig sein muss:
    await initFirebase(dependencies.secureStorageService);
    await initFullServices();

    dependencies.webSocketBus.on('SHOW_SNACKBAR').listen((payload) {
      try {
        final p = payload as Map<String, dynamic>;
        final ctx = rootScaffoldMessengerKey.currentContext;
        
        if (ctx == null || !ctx.mounted) return;
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
          navigatorKey: navigatorKey,
          icon: icon,
          color1: color1,
          color2: color2,
          title: title,
          heightOffset: heightOffset,
        );
      } catch (_) {}
    });

    dependencies.webSocketBus.on('USER_SIGNED_OUT').listen((_) {
      container.updateOverrides([
        appDependenciesProvider.overrideWithValue(dependencies),
        setupCompleteProvider.overrideWithValue(false),
        navigatorKeyProvider.overrideWithValue(navigatorKey),
      ]);

      navigatorKey.currentState?.pushAndRemoveUntil(
        PageRouteBuilder(
          settings: RouteSettings(name: "setupPage"),
          pageBuilder: (context, animation, _) => SetupPage(),
          transitionsBuilder: (context, animation, _, child) {
            final slide = Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
            return SlideTransition(position: slide, child: child);
          },
        ),
        (route) => false,
      );
    });

    dependencies.webSocketBus.on('INVALID_SIGNUP_CREDENTIALS').listen((_) {
      final ctx = rootScaffoldMessengerKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      
      final theme = Theme.of(ctx).extension<CustomColors>()!;

      showAnimatedSnackbarGlobal(
        navigatorKey: navigatorKey,
        icon: Icons.error_outline_rounded,
        color1: theme.warning.shade500!,
        color2: theme.warning.shade400!,
        title: "Der Username ist noch nicht gesetzt!",
        heightOffset: 50,
      );
    });

    dependencies.webSocketBus.on('REFRESH_TOKEN_EMPTY').listen((_) {
      final ctx = rootScaffoldMessengerKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      
      final theme = Theme.of(ctx).extension<CustomColors>()!;

      showAnimatedSnackbarGlobal(
        navigatorKey: navigatorKey,
        icon: Icons.error_outline_rounded,
        color1: theme.warning.shade500!,
        color2: theme.warning.shade400!,
        title: "Refresh-Token nicht gefunden",
        heightOffset: 50,
      );
    });
  }
}