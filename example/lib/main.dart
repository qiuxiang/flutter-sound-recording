import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scidart/numdart.dart';
import 'package:sound_recording/sound_recording.dart';
import 'package:scidart/scidart.dart';

late SendPort sendPort;
final streamController = StreamController<RecordingData>();

class RecordingData {
  final List<int> items;
  final List<double> spectrum;

  const RecordingData(this.items, this.spectrum);
}

void main() {
  final receivePort = ReceivePort();
  receivePort.listen((message) {
    if (message is SendPort) {
      sendPort = message;
      SoundRecording.onData(sendPort.send);
    } else {
      streamController.sink.add(message);
    }
  });
  Isolate.spawn(processRecordingData, receivePort.sendPort);
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

Future<void> processRecordingData(SendPort sendPort) async {
  final receivePort = ReceivePort();
  receivePort.listen((data) {
    final items = (data as List).cast<int>().map((i) => i.toDouble()).toList();
    final spectrum = rfft(Array(items));
    sendPort.send(RecordingData(data.cast<int>(),
        spectrum.sublist(0, spectrum.length ~/ 2).map(complexAbs).toList()));
  });
  sendPort.send(receivePort.sendPort);
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: WillPopScope(
        onWillPop: () async {
          await SoundRecording.stop();
          return true;
        },
        child: AnnotatedRegion(
          value: SystemUiOverlayStyle(
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            body: Column(children: [
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton(
                  onPressed: () async {
                    if (await Permission.microphone.request().isGranted) {
                      SoundRecording.start(sampleRate: 8000, bufferSize: 1024);
                    }
                  },
                  child: const Text('START'),
                ),
                const ElevatedButton(
                  onPressed: SoundRecording.stop,
                  child: Text('STOP'),
                ),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder(
                  stream: streamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Waveform(snapshot.data!);
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class Waveform extends StatelessWidget {
  final RecordingData data;

  const Waveform(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CustomPaint(painter: WaveformPainter(data)),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final RecordingData data;

  WaveformPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    paintSpectrum(canvas, size);
    paintWaveForm(canvas, size);
  }

  void paintSpectrum(Canvas canvas, Size size) {
    final slice = size.width / (data.spectrum.length - 1);
    var x = 0.0;
    for (final i in data.spectrum) {
      final y = (i / 262144) * size.height;
      final hslColor = HSLColor.fromAHSL(
          1, data.spectrum.indexOf(i) * 360 / data.spectrum.length, 1, 0.5);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - y, slice, y),
        Paint()..color = hslColor.toColor(),
      );
      x += slice;
    }
  }

  void paintWaveForm(Canvas canvas, Size size) {
    final slice = size.width / (data.items.length - 1);
    var x = 0.0;
    final points = data.items.map((i) {
      final y = (0.5 + i / 32768) * size.height;
      final offset = Offset(x, y);
      x += slice;
      return offset;
    });
    canvas.drawPoints(
      PointMode.lines,
      points.toList(),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.grey,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
