import 'dart:async';
import 'dart:convert';

import 'package:open_control/data/exceptions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A live or fake connection to OBS, abstracted so managers can be handed
/// either a real [_LiveObsWebSocketSession] or a demo-mode implementation.
abstract class ObsWebSocketSession {
  Stream<Map<String, dynamic>> get events;

  Future<Map<String, dynamic>> request(
    String type, [
    Map<String, dynamic>? data,
  ]);

  Future<void> close();

  static Future<ObsWebSocketSession> connect(String host, int port) =>
      _LiveObsWebSocketSession._connect(host, port);
}

/// A persistent, fully-identified obs-websocket v5 session: performs the
/// Hello -> Identify -> Identified handshake, then exposes typed
/// request/response calls and a broadcast event stream for the session's
/// lifetime. No authentication support — this app targets OBS instances
/// with WebSocket auth disabled.
class _LiveObsWebSocketSession implements ObsWebSocketSession {
  _LiveObsWebSocketSession._(this._channel);

  static const _timeout = Duration(seconds: 5);

  final WebSocketChannel _channel;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  final _pending = <String, Completer<Map<String, dynamic>>>{};
  StreamSubscription<dynamic>? _sub;
  int _requestCounter = 0;

  @override
  Stream<Map<String, dynamic>> get events => _events.stream;

  static Future<_LiveObsWebSocketSession> _connect(
    String host,
    int port,
  ) async {
    final uri = Uri.parse('ws://$host:$port');
    final channel = WebSocketChannel.connect(uri);
    final session = _LiveObsWebSocketSession._(channel);

    final hello = Completer<Map<String, dynamic>>();
    final identified = Completer<void>();

    void failHandshake(Object error) {
      if (!hello.isCompleted) hello.completeError(error);
      if (!identified.isCompleted) identified.completeError(error);
    }

    session._sub = channel.stream.listen(
      (raw) {
        final message = jsonDecode(raw as String) as Map<String, dynamic>;
        final data = (message['d'] as Map<String, dynamic>?) ?? const {};
        switch (message['op'] as int) {
          case 0:
            if (!hello.isCompleted) hello.complete(data);
          case 2:
            if (!identified.isCompleted) identified.complete();
          case 5:
            session._events.add(data);
          case 7:
            session._pending.remove(data['requestId'])?.complete(data);
        }
      },
      onError: (Object e) {
        final error = ObsConnectionException('Connection error: $e');
        session._failPending(error);
        failHandshake(error);
      },
      onDone: () {
        const error = ObsConnectionException('Connection closed');
        session._failPending(error);
        failHandshake(error);
      },
    );

    try {
      await channel.ready.timeout(
        _timeout,
        onTimeout: () =>
            throw ObsConnectionException('Timed out connecting to $host:$port'),
      );
      final helloData = await hello.future.timeout(
        _timeout,
        onTimeout: () =>
            throw ObsConnectionException('No response from $host:$port'),
      );
      channel.sink.add(
        jsonEncode({
          'op': 1,
          'd': {'rpcVersion': helloData['rpcVersion']},
        }),
      );
      await identified.future.timeout(
        _timeout,
        onTimeout: () => throw const ObsConnectionException(
          'OBS did not identify the session',
        ),
      );
    } catch (e) {
      await session._sub?.cancel();
      channel.sink.close().ignore();
      if (e is ObsConnectionException) rethrow;
      throw ObsConnectionException('Could not connect to $host:$port: $e');
    }

    return session;
  }

  /// Sends a Request (op 6) and awaits its RequestResponse (op 7).
  /// Throws [ObsConnectionException] on timeout or a non-successful result.
  @override
  Future<Map<String, dynamic>> request(
    String type, [
    Map<String, dynamic>? data,
  ]) async {
    final requestId = (_requestCounter++).toString();
    final completer = Completer<Map<String, dynamic>>();
    _pending[requestId] = completer;

    _channel.sink.add(
      jsonEncode({
        'op': 6,
        'd': {
          'requestType': type,
          'requestId': requestId,
          'requestData': ?data,
        },
      }),
    );

    final response = await completer.future.timeout(
      _timeout,
      onTimeout: () {
        _pending.remove(requestId);
        throw ObsConnectionException('Timed out waiting for $type response');
      },
    );

    final status = response['requestStatus'] as Map<String, dynamic>?;
    if (status == null || status['result'] != true) {
      throw ObsConnectionException(
        status?['comment'] as String? ?? 'Request $type failed',
      );
    }
    return (response['responseData'] as Map<String, dynamic>?) ?? const {};
  }

  void _failPending(Object error) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _events.close();
    _channel.sink.close().ignore();
  }
}
