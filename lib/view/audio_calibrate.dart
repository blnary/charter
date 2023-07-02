import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:charter/util/song_player.dart';
import 'package:charter/model/offset.dart';
import 'package:charter/util/offset_calculator.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({key}) : super(key: key);

  @override
  State createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OffsetCalculator _offsetCalculator = OffsetCalculator(65559, 140);
  DateTime _audioStartTime = DateTime.now();
  late StreamSubscription<Duration> _positionSubscription;

  int get elapsedTime {
    final currentTime = DateTime.now();
    final difference = currentTime.difference(_audioStartTime);
    return difference.inMilliseconds;
  }

  @override
  void initState() {
    super.initState();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((event) {
      setState(() {
        _audioStartTime = DateTime.now().subtract(event);
      });
    });
    _playAudio();
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    const url = 'http://10.249.45.98/songs/1';
    await playAudio(_audioPlayer, url);
  }

  @override
  Widget build(BuildContext context) {
    int lastDelay = _offsetCalculator.lastDelay;
    int avgDelay = _offsetCalculator.avgDelay;
    var offsetProvider = Provider.of<OffsetProvider>(context);

    Future<void> setDelay() async {
      setState(() {
        _offsetCalculator.setDelay(elapsedTime);
      });
      await offsetProvider.setAudioOffset(_offsetCalculator.avgDelay);
    }

    return Listener(
      onPointerDown: (event) async {
        await setDelay();
      },
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) async {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.space) {
            await setDelay();
          }
        },
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                child: const Center(
                  child: Text(
                    "请跟随乐曲节奏点击空格或鼠标",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "上次延迟: $lastDelay ms",
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        "平均延迟: $avgDelay ms",
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
