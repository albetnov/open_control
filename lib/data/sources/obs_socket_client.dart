import 'package:open_control/data/exceptions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ObsSocketClient {
  static const _connectTimeout = Duration(seconds: 5);

  /// Opens a WebSocket connection to `ws://host:port` and waits for
  /// obs-websocket's v5 `Hello` (op-code 0) message, then closes.
  /// Throws [ObsConnectionException] on failure or timeout.
  Future<void> testConnection(String host, int port) async {
    final uri = Uri.parse('ws://$host:$port');
    final channel = WebSocketChannel.connect(uri);
    try {
      await channel.ready.timeout(
        _connectTimeout,
        onTimeout: () => throw ObsConnectionException('Timed out connecting to $host:$port'),
      );
      await channel.stream.first.timeout(
        _connectTimeout,
        onTimeout: () => throw ObsConnectionException('No response from $host:$port'),
      );
    } on ObsConnectionException {
      rethrow;
    } catch (e) {
      throw ObsConnectionException('Could not connect to $host:$port: $e');
    } finally {
      // Best-effort cleanup: don't await it. If the connection never actually
      // opened (e.g. a firewall silently dropped it), closing it can hang
      // just as long as connecting did, which would re-introduce the endless
      // loading state the timeouts above are meant to prevent.
      channel.sink.close().ignore();
    }
  }
}
