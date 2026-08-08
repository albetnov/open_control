import 'package:get_it/get_it.dart';
import 'package:open_control/data/managers/connection_manager.dart';
import 'package:open_control/data/managers/discovery_manager.dart';
import 'package:open_control/data/managers/remote_control_manager.dart';
import 'package:open_control/data/managers/server_settings_manager.dart';
import 'package:open_control/data/sources/connection_store.dart';
import 'package:open_control/data/sources/files_source.dart';
import 'package:open_control/data/sources/settings_source.dart';

final di = GetIt.instance;

Future<void> configureDependencies() async {
  di.registerLazySingleton<ConnectionStore>(ConnectionStore.new);

  final connectionManager = await ConnectionManager(
    di<ConnectionStore>(),
  ).init();
  di.registerSingleton<ConnectionManager>(connectionManager);

  di.registerLazySingleton<RemoteControlManager>(
    () => RemoteControlManager(di<ConnectionManager>())..init(),
  );

  di.registerLazySingleton<DiscoveryManager>(DiscoveryManager.new);

  di.registerLazySingleton<SettingsSource>(SettingsSource.new);
  di.registerFactory<ServerSettingsManager>(
    () => ServerSettingsManager(di<SettingsSource>()),
  );

  di.registerLazySingleton<FilesSource>(FilesSource.new);
}
