import 'package:flutter/material.dart';
import 'package:open_control/core/theme/app_theme_colors.dart';
import 'package:open_control/core/utils.dart';
import 'package:open_control/data/models/fs_entry.dart';

class FsEntryRow extends StatelessWidget {
  const FsEntryRow({
    required this.entry,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final FsEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: entry.isDir ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              entry.isDir ? Icons.folder_outlined : Icons.movie_outlined,
              size: 20,
              color: context.mutedColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (!entry.isDir)
                    Text(
                      '${formatFileSize(entry.size)} · ${formatRelativeTime(entry.modTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.mutedColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRename,
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: context.mutedColor,
              tooltip: 'Rename',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              color: context.mutedColor,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
