import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:sound_recording/sound_recording.dart';

void main() {
  runApp(const App());
}

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
    SoundRecording.onData((buffer) {
      streamController.sink.add(buffer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
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
                  SoundRecording.init(sampleRate: 8000, bufferSize: 1024);
                }
              },
              child: const Text('INIT'),
            ),
            const ElevatedButton(
              onPressed: SoundRecording.start,
              child: Text('START'),
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
    final slice = size.width / (data.length - 1);
    var x = 0.0;
    final points = data.map((i) {
      final y = (0.5 + i / 16384) * size.height;
      final offset = Offset(x, y);
      x += slice;
      return offset;
    });
    canvas.drawPoints(PointMode.lines, points.toList(), Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
