import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:charter/model/chart.dart';
import 'package:charter/model/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:charter/model/offset.dart';

const double period = 500;
const double spanStart = -1;
const double spanEnd = 0.6;

class CharterPage extends StatefulWidget {
  const CharterPage({Key? key}) : super(key: key);

  @override
  State createState() => _CharterPageState();
}

class _CharterPageState extends State<CharterPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _decimalController =
      TextEditingController(text: "4");
  bool _isAudioPlaying = false;
  DateTime _audioStartTime = DateTime.now();
  Duration _audioPosition = Duration.zero;
  double _sliderValue = 0;
  Duration _audioLength = const Duration(minutes: 1);
  int _decimal = 4;
  late StreamSubscription<Duration> _positionSubscription;

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
    final Color mainColor = colorScheme.primary.withOpacity(0.5);
    final Color bgColor = colorScheme.primary.withOpacity(0.1);

    final offsetProvider = Provider.of<OffsetProvider>(context);
    final songsProvider = Provider.of<SongsProvider>(context);
    final chartsProvider = Provider.of<ChartsProvider>(context);
    final level = chartsProvider.level;
    if (level == null) {
      // TOOD create level button
      return const Center(child: Text("请选定关卡"));
    }

    final mspb = 60000 / level.bpm;
    final offset = level.offset / 44.1;
    final lastBeat = ((elapsedTime - offset) / mspb).round() * mspb + offset;
    final notes = level.notes
        .map<Widget?>((e) {
          final startTime = Duration(milliseconds: e.p ~/ 44.1);
          final diff = e.p ~/ 44.1 - elapsedTime;
          if (diff > period * 3 || diff < -period * 3) {
            return null;
          }
          return Note(
            startTime: startTime,
            audioStartTime: _audioStartTime,
            audioPosition: _audioPosition,
            isAudioPlaying: _isAudioPlaying,
            direction: fromInt(e.d),
            strength: e.s,
          );
        })
        .whereType<Widget>()
        .toList();
    notes.addAll(range(-32, 32).map<Widget?>((e) {
      final timeMs = lastBeat + e * mspb / _decimal;
      final startTime = Duration(milliseconds: timeMs.round());
      final diff = timeMs - elapsedTime;
      if (diff > period * 3 || diff < -period * 3) {
        return null;
      }
      return Note(
        startTime: startTime,
        audioStartTime: _audioStartTime,
        audioPosition: _audioPosition,
        isAudioPlaying: _isAudioPlaying,
        isLine: true,
        isMainLine: e % _decimal == 0,
      );
    }).whereType<Widget>());
    notes.add(Align(
      alignment: const Alignment(0, spanEnd),
      child: Container(
        height: 6,
        color: mainColor,
      ),
    ));

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
                  children: notes,
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
                      // TODO make everything avaliable with keyboard
                      Text(
                        "输入延迟：${offsetProvider.inputOffset.round()} ms",
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        "音频延迟：${offsetProvider.audioOffset.round()} ms",
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
                            onPressed: () async {
                              if (_isAudioPlaying) {
                                _isAudioPlaying = false;
                                _audioPlayer.pause();
                              } else {
                                _isAudioPlaying = true;
                                final url =
                                    'http://10.249.45.98${songsProvider.location}';
                                await _audioPlayer.play(UrlSource(url));
                                var duration = await _audioPlayer.getDuration();
                                if (duration != null) {
                                  _audioLength = duration;
                                }
                              }
                            },
                            child: _isAudioPlaying
                                ? const Tab(icon: Icon(Icons.pause_sharp))
                                : const Tab(icon: Icon(Icons.play_arrow_sharp)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await _audioPlayer.seek(_audioPosition +
                                  const Duration(milliseconds: 1000));
                            },
                            child:
                                const Tab(icon: Icon(Icons.forward_10_sharp)),
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
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _decimalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '分母',
                          ),
                          onChanged: (value) {
                            try {
                              final decimal = int.parse(value);
                              if (decimal <= 0) {
                                throw "分母必须大于 0";
                              }
                              setState(() {
                                _decimal = decimal;
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(e.toString()),
                                      duration: const Duration(seconds: 1)));
                            }
                          },
                        ),
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
  final DateTime audioStartTime;
  final Duration audioPosition;
  final Duration startTime;
  final bool isAudioPlaying;
  final int strength;
  final Direction direction;
  final bool isLine;
  final bool isMainLine;

  const Note(
      {Key? key,
      required this.startTime,
      required this.audioStartTime,
      required this.audioPosition,
      required this.isAudioPlaying,
      this.strength = 0,
      this.direction = Direction.center,
      this.isLine = false,
      this.isMainLine = false})
      : super(key: key);

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

  double get elapsedTime {
    if (!widget.isAudioPlaying) {
      return widget.audioPosition.inMicroseconds / 1000;
    }
    final currentTime = DateTime.now();
    final difference = currentTime.difference(widget.audioStartTime);
    return difference.inMicroseconds / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final double delta = elapsedTime - widget.startTime.inMicroseconds / 1000;
    final double posNote = getPosOf(delta);
    if (widget.isLine) {
      final opacity = widget.isMainLine ? 0.05 : 0.02;
      return Align(
        alignment: Alignment(0, posNote),
        child: Container(
          height: 6,
          color: Colors.black.withOpacity(opacity),
        ),
      );
    }
    return Align(
      alignment: Alignment(toAlign(widget.direction), posNote),
      child: Container(
        height: 6,
        width: 128,
        decoration: BoxDecoration(
          color: strengthToColor(widget.strength),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

double getPosOf(double time) {
  return time / period * (spanEnd - spanStart) + spanEnd;
}

enum Direction {
  center,
  up,
  down,
  left,
  right,
}

int toInt(Direction direction) {
  return direction.index;
}

Direction fromInt(int value) {
  return Direction.values[value];
}

double toAlign(Direction direction) {
  const unit = 0.4;
  switch (direction) {
    case Direction.center:
      return 0;
    case Direction.left:
      return -unit * 2;
    case Direction.down:
      return -unit;
    case Direction.up:
      return unit;
    case Direction.right:
      return unit * 2;
  }
}

Color strengthToColor(int strength) {
  switch (strength) {
    case 1:
      return Colors.lightGreen;
    case 2:
      return Colors.lightBlue;
    case 3:
      return Colors.red;
    default:
      return Colors.black;
  }
}

Iterable<int> range(int start, int end, {int step = 1}) sync* {
  for (int i = start; i < end; i += step) {
    yield i;
  }
}
