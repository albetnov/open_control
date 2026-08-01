import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:open_control/data/models/server_connection.dart';

/// Must match the server's advertised mDNS/DNS-SD service type exactly.
const _serviceType = '_open-control._tcp';

/// Picks a usable host address from a resolved service's addresses, which may
/// contain IPv4, IPv6, or both depending on platform (see bonsoir's docs).
/// Prefers IPv4; brackets an IPv6 address so it stays safe to embed in a URI.
String? pickHostAddress(List<String> addresses) {
  if (addresses.isEmpty) return null;

  final ipv4 = addresses.where((a) => !a.contains(':'));
  if (ipv4.isNotEmpty) return ipv4.first;

  return '[${addresses.first}]';
}

/// Discovers Open Control servers advertised on the LAN via mDNS, so the
/// connection screen can offer them without the user typing an IP address.
class DiscoveryManager {
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;

  final _discovered = ValueNotifier<List<ServerConnection>>(const []);
  ValueListenable<List<ServerConnection>> get discovered => _discovered;

  Future<void> start() async {
    final discovery = BonsoirDiscovery(type: _serviceType);
    await discovery.initialize();

    _subscription = discovery.eventStream?.listen((event) {
      switch (event) {
        case BonsoirDiscoveryServiceFoundEvent():
          event.service.resolve(discovery.serviceResolver);
        case BonsoirDiscoveryServiceResolvedEvent():
          _upsert(event.service);
        case BonsoirDiscoveryServiceLostEvent():
          _remove(event.service);
        default:
          break;
      }
    });

    _discovery = discovery;
    await discovery.start();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    await _discovery?.stop();
    _discovery = null;

    _discovered.value = const [];
  }

  void _upsert(BonsoirService service) {
    final host = pickHostAddress(service.hostAddresses);
    if (host == null) return;

    final connection = ServerConnection(
      host: host,
      port: service.port,
      label: service.name,
    );

    final rest = _discovered.value.where((c) => !c.sameTarget(connection));
    _discovered.value = [connection, ...rest];
  }

  void _remove(BonsoirService service) {
    final host = pickHostAddress(service.hostAddresses);
    if (host == null) return;

    _discovered.value = _discovered.value
        .where((c) => c.host != host || c.port != service.port)
        .toList();
  }
}
