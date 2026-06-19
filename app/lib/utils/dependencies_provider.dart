import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/deps.dart';

final appDependenciesProvider = Provider<AppDependencies>((ref) {
  throw UnimplementedError('appDependenciesProvider muss in main() per override gesetzt werden');
});

final prefsServiceProvider = Provider((ref) => ref.watch(appDependenciesProvider).prefsService);
final databaseServiceProvider = Provider((ref) => ref.watch(appDependenciesProvider).databaseService);
final webSocketServiceProvider = Provider((ref) => ref.watch(appDependenciesProvider).webSocketService);
final webSocketBusProvider = Provider((ref) => ref.watch(appDependenciesProvider).webSocketBus);
final secureStorageServiceProvider = Provider((ref) => ref.watch(appDependenciesProvider).secureStorageService);