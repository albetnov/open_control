import 'package:command_it/command_it.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_control/core/theme/app_theme_colors.dart';
import 'package:open_control/data/managers/connection_manager.dart';
import 'package:open_control/data/managers/files_manager.dart';
import 'package:open_control/data/models/fs_entry.dart';
import 'package:open_control/data/sources/files_source.dart';
import 'package:open_control/presentation/files/widgets/fs_entry_row.dart';
import 'package:open_control/presentation/files/widgets/pending_changes_sheet.dart';
import 'package:watch_it/watch_it.dart';

class FilesScreen extends WatchingWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = di<ConnectionManager>().lastConnected;
    if (connection == null) {
      return const Scaffold(body: Center(child: Text('Not connected')));
    }

    final manager = createOnce(
      () => FilesManager(di<FilesSource>(), connection.host, connection.port),
    );

    callOnce((_) => manager.listCommand());

    final entries = watchValue((FilesManager m) => m.entries);
    final pool = watchValue((FilesManager m) => m.pool);
    final currentPath = watchValue((FilesManager m) => m.currentPath);
    final isLoading = watchValue((FilesManager m) => m.listCommand.isRunning);
    final listError = watchValue((FilesManager m) => m.listCommand.errors);
    final canGoUp = currentPath.isNotEmpty;

    registerHandler(
      select: (FilesManager m) => m.queueRenameCommand.errors,
      handler: (context, error, _) => _showError(context, error),
    );
    registerHandler(
      select: (FilesManager m) => m.queueDeleteCommand.errors,
      handler: (context, error, _) => _showError(context, error),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => canGoUp ? manager.goUp() : context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: canGoUp ? 'Up' : 'Back',
                  ),
                  Expanded(
                    child: Text(
                      currentPath.isEmpty ? 'Files' : '/$currentPath',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.mutedColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(
                context,
                manager,
                entries,
                isLoading,
                listError?.error,
              ),
            ),
            if (pool.isNotEmpty) _PendingChangesBar(manager: manager),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FilesManager manager,
    List<FsEntry> entries,
    bool isLoading,
    Object? error,
  ) {
    if (isLoading && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
          ),
        ),
      );
    }
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'This folder is empty.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: entries.length,
      separatorBuilder: (context, _) =>
          Divider(height: 1, color: context.borderColor),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return FsEntryRow(
          entry: entry,
          onTap: () => manager.open(entry.name),
          onRename: () => _rename(context, manager, entry),
          onDelete: () => manager.queueDeleteCommand(_join(manager, entry)),
        );
      },
    );
  }

  String _join(FilesManager manager, FsEntry entry) =>
      manager.currentPath.value.isEmpty
      ? entry.name
      : '${manager.currentPath.value}/${entry.name}';

  Future<void> _rename(
    BuildContext context,
    FilesManager manager,
    FsEntry entry,
  ) async {
    final controller = TextEditingController(text: entry.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null || newName.isEmpty || newName == entry.name) return;

    final oldPath = _join(manager, entry);
    final newPath = manager.currentPath.value.isEmpty
        ? newName
        : '${manager.currentPath.value}/$newName';
    manager.queueRenameCommand((path: oldPath, newPath: newPath));
  }

  void _showError<T>(BuildContext context, CommandError<T>? error) {
    if (error == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.error.toString())));
  }
}

class _PendingChangesBar extends StatelessWidget {
  const _PendingChangesBar({required this.manager});

  final FilesManager manager;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: manager.pool,
      builder: (context, pool, _) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${pool.length} pending change${pool.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => PendingChangesSheet(manager: manager),
                ),
                child: const Text('Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
