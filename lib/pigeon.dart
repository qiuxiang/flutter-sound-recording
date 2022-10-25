// ignore: depend_on_referenced_packages
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeon.g.dart',
    javaOut: 'android/src/main/java/qiuxiang/sound_recording/Pigeon.java',
    javaOptions: JavaOptions(package: 'qiuxiang.sound_recording'),
  ),
)
@HostApi()
abstract class SoundRecordingApi {
  @async
  void init(int bufferSize, int sampleRate);

  @async
  void start();

  @async
  void stop();
}

@FlutterApi()
abstract class SoundRecordingHandler {
  void read(List<int> buffer);
}
