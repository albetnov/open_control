class ObsConnection {
  ObsConnection({
    required this.host,
    this.port = 4455,
    String? label,
    this.lastConnectedAt,
  }) : label = label ?? host;

  final String host;
  final int port;
  final String label;
  final DateTime? lastConnectedAt;

  bool sameTarget(ObsConnection other) =>
      host == other.host && port == other.port;

  ObsConnection copyWith({DateTime? lastConnectedAt}) {
    return ObsConnection(
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

  factory ObsConnection.fromJson(Map<String, dynamic> json) {
    return ObsConnection(
      host: json['host'] as String,
      port: json['port'] as int,
      label: json['label'] as String?,
      lastConnectedAt: json['lastConnectedAt'] == null
          ? null
          : DateTime.parse(json['lastConnectedAt'] as String),
    );
  }
}
