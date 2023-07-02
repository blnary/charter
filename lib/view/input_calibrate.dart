import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:charter/model/offset.dart';
import 'package:charter/util/offset_calculator.dart';

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

class InputPage extends StatefulWidget {
  const InputPage({Key? key}) : super(key: key);

  @override
  State createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final DateTime _startTime = DateTime.now();
  final OffsetCalculator _offsetCalculator = OffsetCalculator();

  int get elapsedTime {
    final currentTime = DateTime.now();
    final difference = currentTime.difference(_startTime);
    return difference.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color mainColor = colorScheme.primary.withOpacity(0.5);
    final Color bgColor = colorScheme.primary.withOpacity(0.1);

    int lastPressTime = _offsetCalculator.lastPressTime;
    int lastDelay = _offsetCalculator.lastDelay;
    int avgDelay = _offsetCalculator.avgDelay;
    double posPress = getPosOf(lastPressTime);
    var offsetProvider = Provider.of<OffsetProvider>(context);

    Future<void> setDelay() async {
      setState(() {
        _offsetCalculator.setDelay(elapsedTime);
      });
      await offsetProvider.setInputOffset(_offsetCalculator.avgDelay);
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
                    Align(
                      alignment: Alignment(0, posPress),
                      child: Container(
                        height: 4,
                        color: bgColor,
                      ),
                    ),
                    Note(
                      startTime: _startTime,
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
                        "空格或点击以测试延迟",
                        style: TextStyle(fontSize: 20),
                      ),
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
