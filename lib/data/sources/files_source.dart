import 'package:open_control/data/models/fs_entry.dart';
import 'package:open_control/data/models/pool_op.dart';
import 'package:open_control/data/models/submit_result.dart';
import 'package:open_control/data/sources/http.dart';

/// Talks to a server's /fs endpoints. List/read hit the live filesystem;
/// rename/delete only queue an intent — nothing changes on disk until
/// [submit] is called.
class FilesSource {
  Future<List<FsEntry>> list(String host, int port, String path) async {
    final uri = _uri(
      host,
      port,
      '/fs/list',
    ).replace(queryParameters: {'path': path});
    final json = await sendJsonRequest('GET', uri);
    return (json as List)
        .map((e) => FsEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PoolOp> queueRename(
    String host,
    int port,
    String path,
    String newPath,
  ) => _queue(host, port, {'type': 'rename', 'path': path, 'newPath': newPath});

  Future<PoolOp> queueDelete(String host, int port, String path) =>
      _queue(host, port, {'type': 'delete', 'path': path});

  Future<PoolOp> _queue(
    String host,
    int port,
    Map<String, dynamic> body,
  ) async {
    final json = await sendJsonRequest(
      'POST',
      _uri(host, port, '/fs/pool'),
      body: body,
    );
    return PoolOp.fromJson(json as Map<String, dynamic>);
  }

  Future<List<PoolOp>> fetchPool(String host, int port) async {
    final json = await sendJsonRequest('GET', _uri(host, port, '/fs/pool'));
    return (json as List)
        .map((e) => PoolOp.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeFromPool(String host, int port, String id) =>
      sendJsonRequest('DELETE', _uri(host, port, '/fs/pool/$id'));

  Future<SubmitResult> submit(String host, int port) async {
    final json = await sendJsonRequest('POST', _uri(host, port, '/fs/submit'));
    return SubmitResult.fromJson(json as Map<String, dynamic>);
  }

  Uri _uri(String host, int port, String path) =>
      Uri.parse('http://$host:$port$path');
}
