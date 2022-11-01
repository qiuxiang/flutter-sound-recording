import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_recording/sound_recording.dart';
import 'package:fftea/fftea.dart';

void main() {
  runApp(const App());
}

const sampleRate = 8000;
const bufferSize = 1024;
final stft = STFT(bufferSize);

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final streamController = StreamController<List<int>>();

  @override
  void initState() {
    super.initState();
    SoundRecording.onData(streamController.sink.add);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: WillPopScope(
        onWillPop: () async {
          await SoundRecording.stop();
          return true;
        },
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
                    SoundRecording.start(
                        sampleRate: sampleRate, bufferSize: bufferSize);
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
    );
  }
}

class Waveform extends StatelessWidget {
  final List<int> data;

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
  final List<int> data;

  WaveformPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    paintSpectrum(canvas, size);
    paintWaveForm(canvas, size);
  }

  void paintSpectrum(Canvas canvas, Size size) {
    stft.run(data.map((i) => i.toDouble()).toList(), (freq) {
      final spectrum = freq.magnitudes().sublist(0, data.length ~/ 2);
      final slice = size.width / (spectrum.length - 1);
      var x = 0.0;
      for (var index = 0; index < spectrum.length; index += 1) {
        final i = spectrum[index];
        final y = (sqrt(i) / 1024) * size.height;
        final hslColor =
            HSLColor.fromAHSL(1, 180 + index * 180 / spectrum.length, 1, 0.5);
        canvas.drawRect(
          Rect.fromLTWH(x, size.height - y, slice, y),
          Paint()..color = hslColor.toColor(),
        );
        x += slice;
      }
    });
  }

  void paintWaveForm(Canvas canvas, Size size) {
    final slice = size.width / (data.length - 1);
    var x = 0.0;
    final points = data.map((i) {
      final y = (0.5 + i / 65536) * size.height;
      final offset = Offset(x, y);
      x += slice;
      return offset;
    });
    canvas.drawPoints(
      PointMode.polygon,
      points.toList(),
      Paint()
        ..color = Colors.grey
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
