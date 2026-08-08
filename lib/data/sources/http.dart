import 'dart:convert';
import 'dart:io';

import 'package:open_control/data/exceptions.dart';

const _timeout = Duration(seconds: 5);

/// Issues a plain HTTP request against a server and returns its decoded JSON
/// body (or null for an empty body). Shared by [SettingsSource] and
/// [FilesSource] — both talk to the server's REST endpoints independently of
/// the OBS websocket relay.
Future<dynamic> sendJsonRequest(
  String method,
  Uri uri, {
  Map<String, dynamic>? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri).timeout(_timeout);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(_timeout);
    final text = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 400) {
      throw ServerConnectionException(_errorMessage(response.statusCode, text));
    }
    return text.isEmpty ? null : jsonDecode(text);
  } on ServerConnectionException {
    rethrow;
  } catch (e) {
    throw ServerConnectionException(
      'Could not reach ${uri.host}:${uri.port}: $e',
    );
  } finally {
    client.close(force: true);
  }
}

String _errorMessage(int statusCode, String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['error'] is String) {
      return decoded['error'] as String;
    }
  } catch (_) {
    // Fall through to the generic message below.
  }
  return 'Request failed ($statusCode)';
}
