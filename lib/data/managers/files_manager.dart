import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:open_control/data/models/fs_entry.dart';
import 'package:open_control/data/models/pool_op.dart';
import 'package:open_control/data/models/submit_result.dart';
import 'package:open_control/data/sources/files_source.dart';

const _emptySubmitResult = SubmitResult(
  succeeded: [],
  failed: null,
  error: null,
  remaining: [],
);

/// Browses one server's configured media folder and stages rename/delete
/// intents into its pool, applying them only on [submitCommand].
class FilesManager {
  FilesManager(this._source, this.host, this.port);

  final FilesSource _source;
  final String host;
  final int port;

  /// '' is the configured root itself; otherwise a '/'-joined relative path.
  final currentPath = ValueNotifier<String>('');
  final entries = ValueNotifier<List<FsEntry>>(const []);
  final pool = ValueNotifier<List<PoolOp>>(const []);

  bool get canGoUp => currentPath.value.isNotEmpty;

  Future<void> _refreshEntries() async {
    entries.value = await _source.list(host, port, currentPath.value);
  }

  late final listCommand = Command.createAsyncNoParamNoResult(
    _refreshEntries,
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  late final queueRenameCommand =
      Command.createAsyncNoResult<({String path, String newPath})>((
        target,
      ) async {
        final op = await _source.queueRename(
          host,
          port,
          target.path,
          target.newPath,
        );
        pool.value = [...pool.value, op];
      }, errorFilter: const GlobalIfNoLocalErrorFilter());

  late final queueDeleteCommand = Command.createAsyncNoResult<String>((
    path,
  ) async {
    final op = await _source.queueDelete(host, port, path);
    pool.value = [...pool.value, op];
  }, errorFilter: const GlobalIfNoLocalErrorFilter());

  late final removeFromPoolCommand = Command.createAsyncNoResult<String>((
    id,
  ) async {
    await _source.removeFromPool(host, port, id);
    pool.value = pool.value.where((op) => op.id != id).toList();
  }, errorFilter: const GlobalIfNoLocalErrorFilter());

  late final submitCommand = Command.createAsyncNoParam<SubmitResult>(
    () async {
      final result = await _source.submit(host, port);
      pool.value = result.remaining;
      await _refreshEntries();
      return result;
    },
    initialValue: _emptySubmitResult,
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  void open(String name) {
    currentPath.value = currentPath.value.isEmpty
        ? name
        : '${currentPath.value}/$name';
    listCommand.run();
  }

  void goUp() {
    final segments = currentPath.value.split('/')..removeLast();
    currentPath.value = segments.join('/');
    listCommand.run();
  }

  Future<void> refreshPool() async {
    pool.value = await _source.fetchPool(host, port);
  }
}
