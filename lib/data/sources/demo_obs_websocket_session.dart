import 'dart:async';

import 'package:open_control/data/sources/obs_websocket_session.dart';

/// An in-memory stand-in for [ObsWebSocketSession] that answers the exact
/// request types [RemoteControlManager] sends, with no network involved.
class DemoObsWebSocketSession implements ObsWebSocketSession {
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  bool _recording = false;
  bool _paused = false;

  @override
  Stream<Map<String, dynamic>> get events => _events.stream;

  @override
  Future<Map<String, dynamic>> request(
    String type, [
    Map<String, dynamic>? data,
  ]) async {
    switch (type) {
      case 'GetRecordStatus':
        return {'outputActive': _recording, 'outputPaused': _paused};
      case 'GetProfileParameter':
        return {'parameterValue': 'demo-pattern'};
      case 'SetProfileParameter':
        return {};
      case 'StartRecord':
        _recording = true;
        _paused = false;
        _emit('OBS_WEBSOCKET_OUTPUT_STARTED');
        return {};
      case 'StopRecord':
        _recording = false;
        _paused = false;
        _emit('OBS_WEBSOCKET_OUTPUT_STOPPED');
        return {};
      case 'PauseRecord':
        _paused = true;
        _emit('OBS_WEBSOCKET_OUTPUT_PAUSED');
        return {};
      case 'ResumeRecord':
        _paused = false;
        _emit('OBS_WEBSOCKET_OUTPUT_RESUMED');
        return {};
      case 'CreateRecordChapter':
        return {};
      default:
        return {};
    }
  }

  void _emit(String outputState) {
    _events.add({
      'eventType': 'RecordStateChanged',
      'eventData': {'outputState': outputState},
    });
  }

  @override
  Future<void> close() => _events.close();
}
