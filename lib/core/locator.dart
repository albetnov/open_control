import 'package:get_it/get_it.dart';
import 'package:open_control/data/managers/connection_manager.dart';
import 'package:open_control/data/sources/connection_store.dart';
import 'package:open_control/data/sources/obs_socket_client.dart';

final di = GetIt.instance;

Future<void> configureDependencies() async {
  di.registerLazySingleton<ConnectionStore>(ConnectionStore.new);
  di.registerLazySingleton<ObsSocketClient>(ObsSocketClient.new);

  final connectionManager =
      await ConnectionManager(di<ConnectionStore>(), di<ObsSocketClient>()).init();
  di.registerSingleton<ConnectionManager>(connectionManager);
}
