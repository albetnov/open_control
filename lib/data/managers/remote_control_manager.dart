import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:open_control/data/exceptions.dart';
import 'package:open_control/data/managers/connection_manager.dart';
import 'package:open_control/data/sources/obs_websocket_session.dart';

enum RecordState { unknown, idle, recording, paused }

const _defaultFilenamePattern = '%CCYY-%MM-%DD %hh-%mm-%ss';

class RemoteControlManager {
  RemoteControlManager(this._connectionManager);

  final ConnectionManager _connectionManager;

  final recordState = ValueNotifier<RecordState>(RecordState.unknown);

  StreamSubscription<Map<String, dynamic>>? _eventsSub;

  void init() {
    _connectionManager.activeSession.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  void _onSessionChanged() {
    _eventsSub?.cancel();
    final session = _connectionManager.activeSession.value;
    if (session == null) {
      recordState.value = RecordState.unknown;
      return;
    }

    _eventsSub = session.events
        .where((event) => event['eventType'] == 'RecordStateChanged')
        .listen(
          (event) => _applyOutputState(
            (event['eventData'] as Map)['outputState'] as String?,
          ),
        );

    session.request('GetRecordStatus').then((response) {
      final active = response['outputActive'] == true;
      final paused = response['outputPaused'] == true;
      recordState.value = !active
          ? RecordState.idle
          : (paused ? RecordState.paused : RecordState.recording);
    });
  }

  void _applyOutputState(String? outputState) {
    if (outputState == null) return;
    if (outputState.contains('PAUSED')) {
      recordState.value = RecordState.paused;
    } else if (outputState.contains('STARTED') ||
        outputState.contains('RESUMED')) {
      recordState.value = RecordState.recording;
    } else if (outputState.contains('STOPPED')) {
      recordState.value = RecordState.idle;
    }
    // STARTING / STOPPING: leave as-is, the triggering command's isRunning
    // already communicates the in-flight transition.
  }

  ObsWebSocketSession _requireSession() {
    final session = _connectionManager.activeSession.value;
    if (session == null) throw const ObsConnectionException('Not connected');
    return session;
  }

  late final startRecordCommand = Command.createAsyncNoResult<String?>((
    tag,
  ) async {
    final session = _requireSession();
    final trimmedTag = tag?.trim();
    if (trimmedTag == null || trimmedTag.isEmpty) {
      await session.request('StartRecord');
      return;
    }

    final original =
        (await session.request('GetProfileParameter', {
              'parameterCategory': 'Output',
              'parameterName': 'FilenameFormatting',
            }))['parameterValue']
            as String?;

    await session.request('SetProfileParameter', {
      'parameterCategory': 'Output',
      'parameterName': 'FilenameFormatting',
      'parameterValue': '$trimmedTag ${original ?? _defaultFilenamePattern}',
    });

    try {
      await session.request('StartRecord');
    } finally {
      await session.request('SetProfileParameter', {
        'parameterCategory': 'Output',
        'parameterName': 'FilenameFormatting',
        'parameterValue': original,
      });
    }
  }, errorFilter: const GlobalIfNoLocalErrorFilter());

  late final stopRecordCommand = Command.createAsyncNoParamNoResult(
    () => _requireSession().request('StopRecord'),
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  late final pauseCommand = Command.createAsyncNoParamNoResult(
    () => _requireSession().request('PauseRecord'),
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  late final resumeCommand = Command.createAsyncNoParamNoResult(
    () => _requireSession().request('ResumeRecord'),
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  late final addChapterMarkerCommand = Command.createAsyncNoResult<String?>((
    name,
  ) {
    final trimmedName = name?.trim();
    return _requireSession().request(
      'CreateRecordChapter',
      trimmedName == null || trimmedName.isEmpty
          ? null
          : {'chapterName': trimmedName},
    );
  }, errorFilter: const GlobalIfNoLocalErrorFilter());
}
