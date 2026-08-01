import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:open_control/data/models/server_connection.dart';
import 'package:open_control/data/sources/connection_store.dart';
import 'package:open_control/data/sources/demo_server_websocket_session.dart';
import 'package:open_control/data/sources/server_websocket_session.dart';

class ConnectionManager {
  ConnectionManager(this._store);

  final ConnectionStore _store;

  final _savedConnections = ValueNotifier<List<ServerConnection>>(const []);
  ValueListenable<List<ServerConnection>> get savedConnections =>
      _savedConnections;

  final activeSession = ValueNotifier<ServerWebSocketSession?>(null);

  /// The most recently connected host, used to smart-default the new-connection form.
  ServerConnection? get lastConnected =>
      _savedConnections.value.isEmpty ? null : _savedConnections.value.first;

  bool get isDemo => activeSession.value is DemoServerWebSocketSession;

  void enterDemoMode() {
    activeSession.value?.close().ignore();
    activeSession.value = DemoServerWebSocketSession();
  }

  late final connectCommand = Command.createAsyncNoResult<ServerConnection>((
    connection,
  ) async {
    final session = await ServerWebSocketSession.connect(
      connection.host,
      connection.port,
    );
    activeSession.value?.close().ignore();
    activeSession.value = session;

    final connected = connection.copyWith(lastConnectedAt: DateTime.now());
    final rest = _savedConnections.value.where((c) => !c.sameTarget(connected));
    _savedConnections.value = [connected, ...rest];
    await _store.saveAll(_savedConnections.value);
  }, errorFilter: const GlobalIfNoLocalErrorFilter());

  late final removeCommand = Command.createAsyncNoResult<ServerConnection>((
    connection,
  ) async {
    _savedConnections.value = _savedConnections.value
        .where((c) => !c.sameTarget(connection))
        .toList();
    await _store.saveAll(_savedConnections.value);
  }, errorFilter: const GlobalIfNoLocalErrorFilter());

  Future<void> disconnect() async {
    await activeSession.value?.close();
    activeSession.value = null;
  }

  Future<ConnectionManager> init() async {
    _savedConnections.value = await _store.getSaved();
    return this;
  }
}
