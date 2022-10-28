Flutter sound recording plugin for DSP purposes, now supports android.

<img src=https://user-images.githubusercontent.com/1709072/198511525-31c77f2b-09dd-4a95-a5ae-81b8ecb16447.png width=300 >

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
