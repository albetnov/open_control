import 'package:open_control/data/models/settings_state.dart';
import 'package:open_control/data/sources/http.dart';

/// Talks to a server's plain HTTP /settings endpoint. Deliberately separate
/// from the OBS websocket relay: a password often has to be configured here
/// *before* a connection through that relay can succeed at all.
class SettingsSource {
  Future<SettingsState> fetch(String host, int port) async {
    final json = await sendJsonRequest('GET', _uri(host, port));
    return SettingsState.fromJson(json as Map<String, dynamic>);
  }

  Future<SettingsState> update(
    String host,
    int port, {
    String? obsPassword,
    String? fsRoot,
  }) async {
    final json = await sendJsonRequest(
      'PUT',
      _uri(host, port),
      body: {'obsPassword': ?obsPassword, 'fsRoot': ?fsRoot},
    );
    return SettingsState.fromJson(json as Map<String, dynamic>);
  }

  Uri _uri(String host, int port) => Uri.parse('http://$host:$port/settings');
}
