import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:open_control/data/models/settings_state.dart';
import 'package:open_control/data/sources/settings_source.dart';

typedef ServerTarget = ({String host, int port});
typedef UpdateTarget = ({
  String host,
  int port,
  String? obsPassword,
  String? fsRoot,
});

const _empty = SettingsState(obsPasswordSet: false, fsRoot: '');

class ServerSettingsManager {
  ServerSettingsManager(this._source);

  final SettingsSource _source;

  /// null until the first fetch completes for the current target.
  final state = ValueNotifier<SettingsState?>(null);

  late final fetchCommand = Command.createAsync<ServerTarget, SettingsState>(
    (target) async {
      final result = await _source.fetch(target.host, target.port);
      state.value = result;
      return result;
    },
    initialValue: _empty,
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  late final saveCommand = Command.createAsync<UpdateTarget, SettingsState>(
    (target) async {
      final result = await _source.update(
        target.host,
        target.port,
        obsPassword: target.obsPassword,
        fsRoot: target.fsRoot,
      );
      state.value = result;
      return result;
    },
    initialValue: _empty,
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );
}
