import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';

import 'package:hazelnut_shared/database_service.dart';
import 'package:hazelnut_shared/preferences_service.dart';
import 'package:hazelnut_shared/secure_storage_service.dart';

class AppDependencies {
  final SecureStorageService secureStorageService;

  final PreferencesService prefsService;
  final DatabaseService databaseService;

  AppDependencies({
    required this.secureStorageService,
    required this.prefsService,
    required this.databaseService
  });
}

Future<AppDependencies> createDependencies() async {
  final secureStorageService = SecureStorageServiceImpl();

  final prefsService = await PreferencesServiceImpl.create();
  final databaseService = await DatabaseServiceImpl.create(preferences: prefsService);

  return AppDependencies(
    secureStorageService: secureStorageService,
    prefsService: prefsService,
    databaseService: databaseService
  );
}