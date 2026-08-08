import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:open_control/data/sources/settings_source.dart';

typedef ServerTarget = ({String host, int port});
typedef SetPasswordTarget = ({String host, int port, String password});

class ServerSettingsManager {
  ServerSettingsManager(this._source);

  final SettingsSource _source;

  /// null until the first fetch completes for the current target.
  final passwordSet = ValueNotifier<bool?>(null);

  late final fetchCommand = Command.createAsync<ServerTarget, bool>(
    (target) async {
      final isSet = await _source.fetchPasswordSet(target.host, target.port);
      passwordSet.value = isSet;
      return isSet;
    },
    initialValue: false,
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  late final saveCommand = Command.createAsync<SetPasswordTarget, bool>(
    (target) async {
      final isSet = await _source.setPassword(
        target.host,
        target.port,
        target.password,
      );
      passwordSet.value = isSet;
      return isSet;
    },
    initialValue: false,
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );
}
