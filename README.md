Flutter sound recording plugin for real-time DSP, now supports android.

![](https://user-images.githubusercontent.com/1709072/198860611-ed1660f4-0a08-431b-b5b3-930242a9d353.png)

## Usage

```dart
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_recording/sound_recording.dart';

if (await Permission.microphone.request().isGranted) {
  SoundRecording.start(sampleRate: 8000, bufferSize: 1024);
}

SoundRecording.onData((data) {
  // do some DSP
});

// stop if unneeded
SoundRecording.stop();
```
