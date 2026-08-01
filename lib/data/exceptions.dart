class ServerConnectionException implements Exception {
  const ServerConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
