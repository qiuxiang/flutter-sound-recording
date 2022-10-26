import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scidart/numdart.dart';
import 'package:sound_recording/sound_recording.dart';
import 'package:scidart/scidart.dart';

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
    {
      final spectrum = rfft(Array(data.map((i) => i.toDouble()).toList()));
      final items = spectrum.sublist(0, spectrum.length ~/ 2);
      final slice = size.width / (items.length - 1);
      var x = 0.0;
      for (final i in items) {
        items.indexOf(i);
        final abs = complexAbs(i);
        final y = (abs / 262144) * size.height;
        final color =
            HSLColor.fromAHSL(1, items.indexOf(i) * 360 / items.length, 1, 0.5);
        canvas.drawRect(
          Rect.fromLTWH(x, size.height - y, slice, y),
          Paint()..color = color.toColor(),
        );
        x += slice;
      }
    }
    {
      final slice = size.width / (data.length - 1);
      var x = 0.0;
      final wavePoints = data.map((i) {
        final y = (0.5 + i / 32768) * size.height;
        final offset = Offset(x, y);
        x += slice;
        return offset;
      });
      canvas.drawPoints(
        PointMode.lines,
        wavePoints.toList(),
        Paint()
          ..strokeWidth = 1
          ..color = Colors.grey,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
