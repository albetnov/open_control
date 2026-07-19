import 'package:get_it/get_it.dart';
import 'package:open_control/data/managers/connection_manager.dart';
import 'package:open_control/data/managers/remote_control_manager.dart';
import 'package:open_control/data/sources/connection_store.dart';

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
}
