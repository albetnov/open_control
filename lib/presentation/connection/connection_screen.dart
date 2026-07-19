import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_control/core/router/routes.dart';
import 'package:open_control/core/theme/app_theme_colors.dart';
import 'package:open_control/data/managers/connection_manager.dart';
import 'package:open_control/presentation/connection/widgets/connection_list_item.dart';
import 'package:open_control/presentation/connection/widgets/new_connection_form.dart';
import 'package:watch_it/watch_it.dart';

class ConnectionScreen extends WatchingWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = di<ConnectionManager>();
    final savedConnections = watchValue((ConnectionManager m) => m.savedConnections);
    final isConnecting = watchValue((ConnectionManager m) => m.connectCommand.isRunning);
    final connectResult = watchValue((ConnectionManager m) => m.connectCommand.results);

    registerHandler(
      select: (ConnectionManager m) => m.connectCommand.errors,
      handler: (context, error, _) {
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect: ${error.error}')),
        );
      },
    );

    registerHandler(
      select: (ConnectionManager m) => m.activeSession,
      handler: (context, session, _) {
        if (session != null) context.push(AppRoute.remote.path);
      },
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          children: [
            Text('Open Control', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Connect to OBS on your local network.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
            ),
            const SizedBox(height: 28),
            Text('New Connection', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            NewConnectionForm(
              defaultHost: manager.lastConnected?.host ?? '',
              isConnecting: isConnecting,
              onConnect: (connection) => manager.connectCommand(connection),
            ),
            const SizedBox(height: 36),
            Text('Saved Connections', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (savedConnections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No saved connections yet. Connect once and it will show up here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
                ),
              )
            else
              for (final (index, connection) in savedConnections.indexed) ...[
                if (index > 0) Divider(height: 1, color: context.borderColor),
                ConnectionListItem(
                  connection: connection,
                  isConnecting:
                      isConnecting && connectResult.paramData?.sameTarget(connection) == true,
                  onTap: () => manager.connectCommand(connection),
                  onRemove: () => manager.removeCommand(connection),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
