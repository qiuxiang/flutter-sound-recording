import 'pigeon.g.dart';

final _api = MainApi();

class SoundRecording {
  Future<void> init(int bufferSize, int sampleRate) {
    return _api.init(bufferSize, sampleRate);
  }
}
