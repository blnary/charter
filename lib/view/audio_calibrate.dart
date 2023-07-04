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
  late StreamSubscription<Duration> _positionSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OffsetCalculator _offsetCalculator = OffsetCalculator();

  bool _isAudioPlaying = false;
  DateTime _audioStartTime = DateTime.now();
  Duration _audioPosition = Duration.zero;
  Duration _audioLength = const Duration(minutes: 1);
  double _sliderValue = 0;

  double get elapsedTime {
    if (!_isAudioPlaying) {
      return _audioPosition.inMicroseconds / 1000;
    }
    final currentTime = DateTime.now();
    final difference = currentTime.difference(_audioStartTime);
    return difference.inMicroseconds / 1000;
  }

  @override
  void initState() {
    super.initState();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((event) {
      setState(() {
        _audioPosition = event;
        _audioStartTime = DateTime.now().subtract(event);
        _sliderValue = event.inMilliseconds / _audioLength.inMilliseconds;
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
    final Color primColor = colorScheme.primary;
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

    Future<void> switchAudio() async {
      if (_isAudioPlaying) {
        _isAudioPlaying = false;
        _audioPlayer.pause();
      } else {
        _isAudioPlaying = true;
        final url = 'http://10.249.45.98${songsProvider.location}';
        await _audioPlayer.play(UrlSource(url));
        _offsetCalculator.setBpm(songsProvider.bpm);
        _offsetCalculator.setOffsetMs(songsProvider.offsetMs);
        var duration = await _audioPlayer.getDuration();
        if (duration != null) {
          _audioLength = duration;
        }
      }
    }

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (RawKeyEvent event) async {
        if (event is RawKeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.space:
              await setDelay();
              break;
            case LogicalKeyboardKey.space:
              await switchAudio();
              break;
            case LogicalKeyboardKey.keyS:
              await _audioPlayer
                  .seek(_audioPosition - const Duration(milliseconds: 1000));
              break;
            case LogicalKeyboardKey.keyL:
              await _audioPlayer
                  .seek(_audioPosition + const Duration(milliseconds: 1000));
              break;
          }
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
                            await _audioPlayer.seek(_audioPosition -
                                const Duration(milliseconds: 1000));
                          },
                          child: const Tab(icon: Icon(Icons.replay_10_sharp)),
                        ),
                        ElevatedButton(
                          onPressed: switchAudio,
                          child: _isAudioPlaying
                              ? const Tab(icon: Icon(Icons.pause_sharp))
                              : const Tab(icon: Icon(Icons.play_arrow_sharp)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _audioPlayer.seek(_audioPosition +
                                const Duration(milliseconds: 1000));
                          },
                          child: const Tab(icon: Icon(Icons.forward_10_sharp)),
                        ),
                      ],
                    ),
                    Slider(
                      autofocus: false,
                      value: _sliderValue.clamp(0, 1),
                      min: 0,
                      activeColor: primColor,
                      max: 1,
                      onChanged: (val) async {
                        setState(() {
                          _sliderValue = val;
                        });
                        await _audioPlayer.seek(Duration(
                            milliseconds:
                                (_audioLength.inMilliseconds * val).toInt()));
                      },
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
