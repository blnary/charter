import 'dart:async';

import 'package:charter/model/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:charter/model/offset.dart';
import 'package:charter/util/offset_calculator.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({key}) : super(key: key);

  @override
  State createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OffsetCalculator _offsetCalculator = OffsetCalculator();
  bool _isAudioPlaying = false;
  DateTime _audioStartTime = DateTime.now();
  late StreamSubscription<Duration> _positionSubscription;

  double get elapsedTime {
    final currentTime = DateTime.now();
    final difference = currentTime.difference(_audioStartTime);
    return difference.inMicroseconds / 1000;
  }

  @override
  void initState() {
    super.initState();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((event) {
      setState(() {
        _audioStartTime = DateTime.now().subtract(event);
      });
    });
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color bgColor = colorScheme.primary.withOpacity(0.1);
    double lastDelay = _offsetCalculator.lastDelay;
    double avgDelay = _offsetCalculator.avgDelay;
    var offsetProvider = Provider.of<OffsetProvider>(context);
    var songsProvider = Provider.of<SongsProvider>(context);

    Future<void> setDelay() async {
      if (!_isAudioPlaying) {
        return;
      }
      setState(() {
        _offsetCalculator.setDelay(elapsedTime);
      });
      await offsetProvider.setAudioOffset(_offsetCalculator.avgDelay);
    }

    return RawKeyboardListener(
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
            child: Listener(
              onPointerDown: (event) async {
                await setDelay();
              },
              child: Container(
                color: Colors.transparent,
                child: const Center(
                  child: Text(
                    "请跟随乐曲节奏点击空格或鼠标",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: bgColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "上次延迟: ${lastDelay.round()} ms",
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      "平均延迟: ${avgDelay.round()} ms",
                      style: const TextStyle(fontSize: 20),
                    ),
                    ButtonBar(
                      alignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (_isAudioPlaying) {
                              _isAudioPlaying = false;
                              _audioPlayer.pause();
                            } else {
                              _isAudioPlaying = true;
                              final url =
                                  'http://10.249.45.98/songs/${songsProvider.id}';
                              _offsetCalculator.setBpm(songsProvider.bpm);
                              _offsetCalculator.setOffset(songsProvider.offset);
                              await _audioPlayer.play(UrlSource(url));
                            }
                          },
                          child: _isAudioPlaying
                              ? const Tab(icon: Icon(Icons.pause))
                              : const Tab(icon: Icon(Icons.play_arrow)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
