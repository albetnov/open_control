import 'package:flutter/material.dart';
import 'package:open_control/core/theme/app_colors.dart';
import 'package:open_control/core/theme/app_theme_colors.dart';
import 'package:open_control/core/utils.dart';
import 'package:open_control/data/models/obs_connection.dart';

class ConnectionListItem extends StatelessWidget {
  const ConnectionListItem({
    required this.connection,
    required this.isConnecting,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final ObsConnection connection;
  final bool isConnecting;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isConnecting ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnecting ? AppColors.amber : Colors.transparent,
                  border: Border.all(color: context.borderColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '${connection.host}:${connection.port}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.mutedColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (connection.lastConnectedAt != null)
              Text(
                formatRelativeTime(connection.lastConnectedAt!),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.mutedColor),
              ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
              color: context.mutedColor,
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }
}
