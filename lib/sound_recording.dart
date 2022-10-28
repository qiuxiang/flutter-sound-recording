import 'dart:async';

import 'src/pigeon.g.dart';

final _api = SoundRecordingApi();
void Function(List<int>)? _onData;
_Handler? _handler;

/// Get real-time audio data from microphone.
class SoundRecording {
  /// Start recording.
  ///
  /// Make sure the microphone permission has granted.
  static Future<void> start({int bufferSize = 8192, int sampleRate = 44100}) {
    if (_handler == null) {
      _handler = _Handler();
      SoundRecordingHandler.setup(_handler);
    }
    return _api.start(bufferSize, sampleRate);
  }

  /// Stop recording and release recorder.
  static Future<void> stop() {
    return _api.stop();
  }

  /// Set onData listener.
  ///
  /// The date is mono 16Bit int list. 
  static onData(void Function(List<int>) callback) {
    return _onData = callback;
  }
}

class _Handler extends SoundRecordingHandler {
  @override
  void read(List<int?> buffer) {
    _onData?.call(buffer.cast<int>());
  }
}
