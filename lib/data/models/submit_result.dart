import 'package:open_control/data/models/pool_op.dart';

class SubmitResult {
  const SubmitResult({
    required this.succeeded,
    required this.failed,
    required this.error,
    required this.remaining,
  });

  final List<PoolOp> succeeded;
  final PoolOp? failed;
  final String? error;
  final List<PoolOp> remaining;

  factory SubmitResult.fromJson(Map<String, dynamic> json) => SubmitResult(
    succeeded: _list(json['succeeded']),
    failed: json['failed'] == null
        ? null
        : PoolOp.fromJson(json['failed'] as Map<String, dynamic>),
    error: json['error'] as String?,
    remaining: _list(json['remaining']),
  );

  static List<PoolOp> _list(dynamic raw) => ((raw as List?) ?? const [])
      .map((e) => PoolOp.fromJson(e as Map<String, dynamic>))
      .toList();
}
