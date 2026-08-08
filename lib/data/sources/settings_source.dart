import 'dart:convert';
import 'dart:io';

import 'package:open_control/data/exceptions.dart';

/// Talks to a server's plain HTTP /settings endpoint. Deliberately separate
/// from the OBS websocket relay: a password often has to be configured here
/// *before* a connection through that relay can succeed at all.
class SettingsSource {
  static const _timeout = Duration(seconds: 5);

  Future<bool> fetchPasswordSet(String host, int port) =>
      _send('GET', host, port).then(_isPasswordSet);

  Future<bool> setPassword(String host, int port, String password) => _send(
    'PUT',
    host,
    port,
    body: {'obsPassword': password},
  ).then(_isPasswordSet);

  bool _isPasswordSet(Map<String, dynamic> response) =>
      response['obsPasswordSet'] == true;

  Future<Map<String, dynamic>> _send(
    String method,
    String host,
    int port, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final request = await client
          .openUrl(method, Uri.parse('http://$host:$port/settings'))
          .timeout(_timeout);
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 400) {
        throw ServerConnectionException(
          'Settings request failed (${response.statusCode})',
        );
      }
      return jsonDecode(text) as Map<String, dynamic>;
    } on ServerConnectionException {
      rethrow;
    } catch (e) {
      throw ServerConnectionException('Could not reach $host:$port: $e');
    } finally {
      client.close(force: true);
    }
  }
}
