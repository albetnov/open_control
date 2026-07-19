class ObsConnectionException implements Exception {
  const ObsConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
