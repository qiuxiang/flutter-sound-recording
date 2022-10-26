import 'dart:async';

import 'pigeon.g.dart';

final _api = SoundRecordingApi();
void Function(List<int>)? onDataCallback;
_Handler? _handler;

class SoundRecording {
  static Future<void> start({int bufferSize = 8192, int sampleRate = 44100}) {
    if (_handler == null) {
      _handler = _Handler();
      SoundRecordingHandler.setup(_handler);
    }
    return _api.start(bufferSize, sampleRate);
  }

  static Future<void> stop() {
    return _api.stop();
  }

  static onData(void Function(List<int>) callback) {
    return onDataCallback = callback;
  }
}

class _Handler extends SoundRecordingHandler {
  @override
  void read(List<int?> buffer) {
    onDataCallback?.call(buffer.cast<int>());
  }
}
