import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:open_control/data/models/obs_connection.dart';
import 'package:open_control/data/sources/connection_store.dart';
import 'package:open_control/data/sources/obs_socket_client.dart';

class ConnectionManager {
  ConnectionManager(this._store, this._client);

  final ConnectionStore _store;
  final ObsSocketClient _client;

  final _savedConnections = ValueNotifier<List<ObsConnection>>(const []);
  ValueListenable<List<ObsConnection>> get savedConnections => _savedConnections;

  /// The most recently connected host, used to smart-default the new-connection form.
  ObsConnection? get lastConnected =>
      _savedConnections.value.isEmpty ? null : _savedConnections.value.first;

  late final connectCommand = Command.createAsyncNoResult<ObsConnection>(
    (connection) async {
      await _client.testConnection(connection.host, connection.port);
      final connected = connection.copyWith(lastConnectedAt: DateTime.now());
      final rest = _savedConnections.value.where((c) => !c.sameTarget(connected));
      _savedConnections.value = [connected, ...rest];
      await _store.saveAll(_savedConnections.value);
    },
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  late final removeCommand = Command.createAsyncNoResult<ObsConnection>(
    (connection) async {
      _savedConnections.value =
          _savedConnections.value.where((c) => !c.sameTarget(connection)).toList();
      await _store.saveAll(_savedConnections.value);
    },
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  Future<ConnectionManager> init() async {
    _savedConnections.value = await _store.getSaved();
    return this;
  }
}
