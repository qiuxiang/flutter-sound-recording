Flutter sound recording plugin for DSP purposes, now supports android.

<img src=https://user-images.githubusercontent.com/1709072/198487233-7108f863-ca97-4ce2-a43b-2b5e8bcd09d8.png width=300 >

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
