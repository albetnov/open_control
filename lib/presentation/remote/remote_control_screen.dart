import 'package:command_it/command_it.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_control/core/theme/app_theme_colors.dart';
import 'package:open_control/data/managers/connection_manager.dart';
import 'package:open_control/data/managers/remote_control_manager.dart';
import 'package:open_control/presentation/remote/widgets/record_actions.dart';
import 'package:open_control/presentation/remote/widgets/record_status.dart';
import 'package:watch_it/watch_it.dart';

class RemoteControlScreen extends WatchingWidget {
  const RemoteControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectionManager = di<ConnectionManager>();
    final manager = di<RemoteControlManager>();
    final activeConnection = connectionManager.lastConnected;

    final state = watchValue((RemoteControlManager m) => m.recordState);
    final isStarting = watchValue(
      (RemoteControlManager m) => m.startRecordCommand.isRunning,
    );
    final isStopping = watchValue(
      (RemoteControlManager m) => m.stopRecordCommand.isRunning,
    );
    final isPausing = watchValue(
      (RemoteControlManager m) => m.pauseCommand.isRunning,
    );
    final isResuming = watchValue(
      (RemoteControlManager m) => m.resumeCommand.isRunning,
    );
    final isAddingChapter = watchValue(
      (RemoteControlManager m) => m.addChapterMarkerCommand.isRunning,
    );

    registerHandler(
      select: (RemoteControlManager m) => m.startRecordCommand.errors,
      handler: (context, error, _) => _showError(context, error),
    );
    registerHandler(
      select: (RemoteControlManager m) => m.stopRecordCommand.errors,
      handler: (context, error, _) => _showError(context, error),
    );
    registerHandler(
      select: (RemoteControlManager m) => m.pauseCommand.errors,
      handler: (context, error, _) => _showError(context, error),
    );
    registerHandler(
      select: (RemoteControlManager m) => m.resumeCommand.errors,
      handler: (context, error, _) => _showError(context, error),
    );
    registerHandler(
      select: (RemoteControlManager m) => m.addChapterMarkerCommand.errors,
      handler: (context, error, _) => _showError(context, error),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      connectionManager.disconnect();
                      context.pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Disconnect',
                  ),
                  Expanded(
                    child: Text(
                      activeConnection == null
                          ? ''
                          : '${activeConnection.host}:${activeConnection.port}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              RecordStatus(state: state),
              const SizedBox(height: 36),
              RecordActions(
                state: state,
                isStarting: isStarting,
                isStopping: isStopping,
                isPausing: isPausing,
                isResuming: isResuming,
                isAddingChapter: isAddingChapter,
                onStart: (tag) => manager.startRecordCommand(tag),
                onStop: () => manager.stopRecordCommand(),
                onPause: () => manager.pauseCommand(),
                onResume: () => manager.resumeCommand(),
                onAddChapter: (name) => manager.addChapterMarkerCommand(name),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError<T>(BuildContext context, CommandError<T>? error) {
    if (error == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.error.toString())));
  }
}
