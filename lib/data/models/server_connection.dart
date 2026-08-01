class ServerConnection {
  ServerConnection({
    required this.host,
    this.port = 8888,
    String? label,
    this.lastConnectedAt,
  }) : label = label ?? host;

  final String host;
  final int port;
  final String label;
  final DateTime? lastConnectedAt;

  bool sameTarget(ServerConnection other) =>
      host == other.host && port == other.port;

  ServerConnection copyWith({DateTime? lastConnectedAt}) {
    return ServerConnection(
      host: host,
      port: port,
      label: label,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'label': label,
    'lastConnectedAt': lastConnectedAt?.toIso8601String(),
  };

  factory ServerConnection.fromJson(Map<String, dynamic> json) {
    return ServerConnection(
      host: json['host'] as String,
      port: json['port'] as int,
      label: json['label'] as String?,
      lastConnectedAt: json['lastConnectedAt'] == null
          ? null
          : DateTime.parse(json['lastConnectedAt'] as String),
    );
  }
}
