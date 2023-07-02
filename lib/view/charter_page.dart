import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:charter/model/song.dart';
import 'package:charter/util/song_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:charter/model/offset.dart';

const int period = 1000;
const int pressIndTime = 320;
const double spanStart = -2;
const double spanEnd = 0.6;

double getPosOf(int time) {
  return (time / period * (spanEnd - spanStart) - (1 - spanEnd)) %
          (spanEnd - spanStart) +
      (1 - spanEnd) +
      spanStart;
}

class CharterPage extends StatefulWidget {
  const CharterPage({Key? key}) : super(key: key);

  @override
  State createState() => _CharterPageState();
}

class _CharterPageState extends State<CharterPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;
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
    final Color mainColor = colorScheme.primary.withOpacity(0.5);
    final Color bgColor = colorScheme.primary.withOpacity(0.1);

    var offsetProvider = Provider.of<OffsetProvider>(context);
    var songsProvider = Provider.of<SongsProvider>(context);

    return Listener(
      onPointerDown: (event) async {},
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) async {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.space) {}
        },
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Align(
                      alignment: const Alignment(0, spanEnd),
                      child: Container(
                        height: 4,
                        color: mainColor,
                      ),
                    ),
                    Note(
                      startTime: _audioStartTime,
                    ),
                  ],
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
                      const Text(
                        "D 左 F 下 J 上 K 右 Space 中",
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        "输入延迟：${offsetProvider.inputOffset}ms",
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        "音频延迟：${offsetProvider.audioOffset}ms",
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
                                await playAudio(_audioPlayer, url);
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
      ),
    );
  }
}

class Note extends StatefulWidget {
  final DateTime startTime;

  const Note({Key? key, required this.startTime}) : super(key: key);

  @override
  State createState() => _NoteState();
}

class _NoteState extends State<Note> {
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((elapsed) {
      setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  int get elapsedTime {
    final currentTime = DateTime.now();
    final difference = currentTime.difference(widget.startTime);
    return difference.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color noteColor = colorScheme.primary.withOpacity(0.8);

    double posNote = getPosOf(elapsedTime);
    return Align(
      alignment: Alignment(0, posNote),
      child: Container(
        height: 4,
        width: 128,
        color: noteColor,
      ),
    );
  }
}
