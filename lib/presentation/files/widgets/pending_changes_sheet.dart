import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_control/core/theme/app_colors.dart';
import 'package:open_control/core/theme/app_theme_colors.dart';
import 'package:open_control/data/managers/files_manager.dart';
import 'package:open_control/data/models/pool_op.dart';
import 'package:watch_it/watch_it.dart';

/// Reviews queued rename/delete intents before they touch disk. Submit is
/// the one moment anything actually changes - queueing itself is free to
/// undo by removing an item here.
class PendingChangesSheet extends WatchingWidget {
  const PendingChangesSheet({required this.manager, super.key});

  final FilesManager manager;

  @override
  Widget build(BuildContext context) {
    final pool = watchValue((FilesManager m) => m.pool);
    final isSubmitting = watchValue(
      (FilesManager m) => m.submitCommand.isRunning,
    );
    final submitResult = watchValue(
      (FilesManager m) => m.submitCommand.results,
    );

    registerHandler(
      select: (FilesManager m) => m.removeFromPoolCommand.errors,
      handler: (context, error, _) {
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove: ${error.error}')),
        );
      },
    );
    registerHandler(
      select: (FilesManager m) => m.submitCommand.errors,
      handler: (context, error, _) {
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit: ${error.error}')),
        );
      },
    );

    final failed = submitResult.data?.failed;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pending Changes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
          if (failed != null) ...[
            const SizedBox(height: 4),
            Text(
              'Failed: ${failed.path} — ${submitResult.data?.error ?? 'unknown error'}. '
              'The rest are still queued.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 12),
          if (pool.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nothing queued.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: pool.length,
                separatorBuilder: (context, _) =>
                    Divider(height: 1, color: context.borderColor),
                itemBuilder: (context, index) {
                  final op = pool[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_describe(op)),
                    trailing: IconButton(
                      onPressed: () => manager.removeFromPoolCommand(op.id),
                      icon: const Icon(Icons.close, size: 18),
                      color: context.mutedColor,
                      tooltip: 'Remove from queue',
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: pool.isEmpty || isSubmitting
                  ? null
                  : () => manager.submitCommand(),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Submit ${pool.length} Change${pool.length == 1 ? '' : 's'}',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _describe(PoolOp op) => switch (op.type) {
    PoolOpType.rename => 'Rename ${op.path} → ${op.newPath}',
    PoolOpType.delete => 'Delete ${op.path}',
  };
}
