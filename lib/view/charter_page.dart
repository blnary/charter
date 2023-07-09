import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:charter/model/chart.dart';
import 'package:charter/view/note.dart';
import 'package:charter/model/song.dart';
import 'package:charter/util/range.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _playbackRateController =
      TextEditingController(text: "1");
  late TextEditingController _chartNameController;
  late TextEditingController _difficultyController;
  final FocusNode _focusNode = FocusNode();

  bool _isAudioPlaying = false;
  DateTime _audioStartTime = DateTime.now();
  Duration _audioPosition = Duration.zero;
  double _sliderValue = 0;
  Duration _audioLength = const Duration(minutes: 1);
  int _decimal = 4;
  int _strength = 1;
  double _playbackRate = 1;

  double get elapsedTime {
    if (!_isAudioPlaying) {
      return _audioPosition.inMicroseconds / 1000;
    }
    final currentTime = DateTime.now();
    final difference = currentTime.difference(_audioStartTime) * _playbackRate;
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
        _audioStartTime = DateTime.now().subtract(event * (1 / _playbackRate));
        _sliderValue = event.inMilliseconds / _audioLength.inMilliseconds;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chartsProvider = Provider.of<ChartsProvider>(context);
    final level = chartsProvider.level;
    if (level == null) return;
    _chartNameController = TextEditingController(text: level.name);
    _difficultyController =
        TextEditingController(text: level.difficulty.toString());
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
    final audioOffset =
        _isAudioPlaying ? offsetProvider.audioOffset * _playbackRate : 0;
    final inputOffset =
        _isAudioPlaying ? offsetProvider.inputOffset * _playbackRate : 0;
    final displayTime = elapsedTime - audioOffset + inputOffset;
    final level = chartsProvider.level;
    if (level == null) {
      return const Center(child: Text("请选定关卡"));
    }

    // Render notes
    final mspb = 60000 / level.bpm;
    final unit = mspb / _decimal;
    final offsetMs = level.offsetSamp / 44.1;
    final lastBeat =
        ((displayTime - offsetMs) / mspb).round() * mspb + offsetMs;
    final notes = level.notes
        .map<Widget?>((e) {
          final startTime = Duration(milliseconds: e.p ~/ 44.1);
          final diff = e.p / 44.1 - displayTime;
          if (diff > period * 3 || diff < -period * 3) {
            return null;
          }
          return NoteWidget(
            startTime: startTime,
            audioStartTime: _audioStartTime,
            audioPosition: _audioPosition,
            isAudioPlaying: _isAudioPlaying,
            playbackRate: _playbackRate,
            direction: fromInt(e.d),
            strength: e.s,
          );
        })
        .whereType<Widget>()
        .toList();
    notes.addAll(range(-32, 32).map<Widget?>((e) {
      final timeMs = lastBeat + e * unit;
      final startTime = Duration(milliseconds: timeMs.round());
      final diff = timeMs - displayTime;
      if (diff > period * 3 || diff < period * -3) {
        return null;
      }
      return NoteWidget(
        startTime: startTime,
        audioStartTime: _audioStartTime,
        audioPosition: _audioPosition,
        isAudioPlaying: _isAudioPlaying,
        playbackRate: _playbackRate,
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

    // Helper functions
    void addAlignedNote(Direction d) {
      chartsProvider.addAlignedNoteAt(
          elapsedTime - audioOffset, d, _strength, _decimal);
    }

    void deleteNote() {
      chartsProvider.deleteNoteAt(elapsedTime - audioOffset);
    }

    Future<void> switchAudio() async {
      if (_isAudioPlaying) {
        _isAudioPlaying = false;
        _audioPlayer.pause();
      } else {
        _isAudioPlaying = true;
        final url = 'http://test.undecla.red${songsProvider.location}';
        await _audioPlayer.play(UrlSource(url));
        var duration = await _audioPlayer.getDuration();
        if (duration != null) {
          _audioLength = duration;
        }
      }
    }

    Future<void> seekAudio(int unitCount) async {
      await _audioPlayer.seek(Duration(
          milliseconds:
              ((((elapsedTime - offsetMs) / unit).round() + unitCount) * unit +
                      offsetMs)
                  .round()));
    }

    Future<void> setPlaybackRate(double playbackRate) async {
      setState(() {
        _playbackRate = playbackRate;
      });
      await _audioPlayer.setPlaybackRate(_playbackRate);
    }

    // Render page
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
              case LogicalKeyboardKey.keyH:
                deleteNote();
                break;
              case LogicalKeyboardKey.space:
                await switchAudio();
                break;
              case LogicalKeyboardKey.keyA:
                await setPlaybackRate(0.5);
                break;
              case LogicalKeyboardKey.semicolon:
                await setPlaybackRate(1);
                break;
              case LogicalKeyboardKey.keyX:
                await seekAudio(-64);
                break;
              case LogicalKeyboardKey.period:
                await seekAudio(64);
                break;
              case LogicalKeyboardKey.keyS:
                await seekAudio(-8);
                break;
              case LogicalKeyboardKey.keyL:
                await seekAudio(8);
                break;
              case LogicalKeyboardKey.keyW:
                await seekAudio(-1);
                break;
              case LogicalKeyboardKey.keyO:
                await seekAudio(1);
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
                        "DFJKG 左下上右中 H 删除 Space 控制音频",
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
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
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
                                } catch (_) {}
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
                                } catch (_) {}
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
                              controller: _playbackRateController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '速率',
                              ),
                              onChanged: (value) async {
                                try {
                                  final playbackRate = double.parse(value);
                                  if (playbackRate < 0.1) {
                                    throw "速率必须大于或等于 0.1";
                                  }
                                  if (playbackRate > 4) {
                                    throw "速率必须小于或等于 4";
                                  }
                                  await setPlaybackRate(playbackRate);
                                } catch (_) {}
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
                              controller: _difficultyController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '难度',
                              ),
                              onChanged: (value) async {
                                try {
                                  final difficulty = double.parse(value);
                                  if (difficulty <= 0) {
                                    throw "难度必须大于 0";
                                  }
                                  setState(() {
                                    chartsProvider.setDifficulty(difficulty);
                                  });
                                } catch (_) {}
                              },
                              onTapOutside: (_) {
                                _focusNode.requestFocus();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 160,
                            child: TextField(
                              controller: _chartNameController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: '谱面名称',
                              ),
                              onChanged: (value) async {
                                setState(() {
                                  chartsProvider.setName(value);
                                });
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