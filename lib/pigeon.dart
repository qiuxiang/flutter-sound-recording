import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeon.g.dart',
    javaOut: 'android/src/main/java/qiuxiang/sound_recording/Pigeon.java',
    javaOptions: JavaOptions(package: 'qiuxiang.sound_recording'),
  ),
)
@HostApi()
abstract class MainApi {
  @async
  void init();

  @async
  void open(int bufferSize, int sampleRate);
}
