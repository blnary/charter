import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:charter/model/chart.dart';
import 'package:charter/model/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:charter/model/offset.dart';

const double period = 400;
const double spanStart = -1;
const double spanEnd = 0;

class CharterPage extends StatefulWidget {
  const CharterPage({Key? key}) : super(key: key);

  @override
  State createState() => _CharterPageState();
}

class _CharterPageState extends State<CharterPage> {
  late StreamSubscription<Duration> _positionSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _decimalController =
      TextEditingController(text: "4");
  final TextEditingController _strengthController =
      TextEditingController(text: "1");
  final FocusNode _focusNode = FocusNode();

  bool _isAudioPlaying = false;
  DateTime _audioStartTime = DateTime.now();
  Duration _audioPosition = Duration.zero;
  double _sliderValue = 0;
  Duration _audioLength = const Duration(minutes: 1);
  int _decimal = 4;
  int _strength = 1;

  double get elapsedTime {
    if (!_isAudioPlaying) {
      return _audioPosition.inMicroseconds / 1000;
    }
    final currentTime = DateTime.now();
    final difference = currentTime.difference(_audioStartTime);
    return difference.inMicroseconds / 1000;
  }

  void setStrength(int strength) {
    setState(() {
      _strengthController.text = strength.toString();
      _strength = strength;
    });
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
    final displayTime =
        elapsedTime - offsetProvider.audioOffset + offsetProvider.inputOffset;
    final level = chartsProvider.level;
    if (level == null) {
      return const Center(child: Text("请选定关卡"));
    }

    // Render notes
    final mspb = 60000 / level.bpm;
    final offset = level.offsetSamp / 44.1;
    final lastBeat = ((displayTime - offset) / mspb).round() * mspb + offset;
    final notes = level.notes
        .map<Widget?>((e) {
          final startTime = Duration(milliseconds: e.p ~/ 44.1);
          final diff = e.p / 44.1 - displayTime;
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
      final diff = timeMs - displayTime;
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

    void addAlignedNote(Direction d) {
      chartsProvider.addAlignedNoteAt(
          elapsedTime - offsetProvider.audioOffset, d, _strength, _decimal);
    }

    void deleteNote() {
      chartsProvider.deleteNoteAt(elapsedTime - offsetProvider.audioOffset);
    }

    Future<void> switchAudio() async {
      if (_isAudioPlaying) {
        _isAudioPlaying = false;
        _audioPlayer.pause();
      } else {
        _isAudioPlaying = true;
        final url = 'http://10.249.45.98${songsProvider.location}';
        await _audioPlayer.play(UrlSource(url));
        var duration = await _audioPlayer.getDuration();
        if (duration != null) {
          _audioLength = duration;
        }
      }
    }

    return Listener(
      onPointerDown: (event) async {
        _focusNode.requestFocus();
      },
      child: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (RawKeyEvent event) async {
          if (event is RawKeyDownEvent) {
            switch (event.logicalKey) {
              case LogicalKeyboardKey.keyD:
                addAlignedNote(Direction.left);
                break;
              case LogicalKeyboardKey.keyF:
                addAlignedNote(Direction.down);
                break;
              case LogicalKeyboardKey.keyJ:
                addAlignedNote(Direction.up);
                break;
              case LogicalKeyboardKey.keyK:
                addAlignedNote(Direction.right);
                break;
              case LogicalKeyboardKey.keyG:
                addAlignedNote(Direction.center);
                break;
              case LogicalKeyboardKey.keyX:
                deleteNote();
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
              case LogicalKeyboardKey.keyE:
                setStrength(1);
                break;
              case LogicalKeyboardKey.keyR:
                setStrength(2);
                break;
              case LogicalKeyboardKey.keyT:
                setStrength(3);
                break;
            }
          }
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
                        "DFJKG 左下上右中 X 删除 Space 控制音频",
                        style: TextStyle(fontSize: 20),
                      ),
                      const Text(
                        "ERT 小中大力度 SL 回退前进",
                        style: TextStyle(fontSize: 20),
                      ),
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
                              var msg = await chartsProvider
                                  .createOrSet(songsProvider.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(msg),
                                        duration: const Duration(seconds: 1)));
                              }
                            },
                            child: const Tab(icon: Icon(Icons.upload_sharp)),
                          ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 84,
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
                                          duration:
                                              const Duration(seconds: 1)));
                                }
                              },
                              onTapOutside: (_) {
                                _focusNode.requestFocus();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 84,
                            child: TextField(
                              controller: _strengthController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '力度',
                              ),
                              onChanged: (value) {
                                try {
                                  final strength = int.parse(value);
                                  if (strength <= 0) {
                                    throw "力度必须大于 0";
                                  }
                                  if (strength >= 4) {
                                    throw "力度必须小于 4";
                                  }
                                  setState(() {
                                    _strength = strength;
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(e.toString()),
                                          duration:
                                              const Duration(seconds: 1)));
                                }
                              },
                              onTapOutside: (_) {
                                _focusNode.requestFocus();
                              },
                            ),
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
    _ticker = Ticker((_) {
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
    final offsetProvider = Provider.of<OffsetProvider>(context);
    final displayTime = elapsedTime - offsetProvider.audioOffset;
    final delta = displayTime - widget.startTime.inMicroseconds / 1000;
    final posNote = getPosOf(delta);
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
