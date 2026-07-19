import 'dart:convert';

import 'package:open_control/data/models/obs_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionStore {
  static const _key = 'saved_connections';

  Future<List<ObsConnection>> getSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((json) => ObsConnection.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<ObsConnection> connections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      connections.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }
}
