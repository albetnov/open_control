enum PoolOpType { rename, delete }

/// A queued-but-not-yet-applied file operation. Nothing on disk changes
/// until the pool holding these is submitted.
class PoolOp {
  const PoolOp({
    required this.id,
    required this.type,
    required this.path,
    this.newPath,
  });

  final String id;
  final PoolOpType type;
  final String path;
  final String? newPath;

  factory PoolOp.fromJson(Map<String, dynamic> json) => PoolOp(
    id: json['id'] as String,
    type: PoolOpType.values.byName(json['type'] as String),
    path: json['path'] as String,
    newPath: json['newPath'] as String?,
  );
}
