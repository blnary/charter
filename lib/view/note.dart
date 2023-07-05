import 'package:charter/model/chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'package:charter/model/offset.dart';

const double period = 400;
const double spanStart = -1;
const double spanEnd = 0;

class NoteWidget extends StatefulWidget {
  final DateTime audioStartTime;
  final Duration audioPosition;
  final Duration startTime;
  final double playbackRate;
  final bool isAudioPlaying;
  final int strength;
  final Direction direction;
  final bool isLine;
  final bool isMainLine;

  const NoteWidget(
      {Key? key,
      required this.startTime,
      required this.audioStartTime,
      required this.audioPosition,
      required this.playbackRate,
      required this.isAudioPlaying,
      this.strength = 0,
      this.direction = Direction.center,
      this.isLine = false,
      this.isMainLine = false})
      : super(key: key);

  @override
  State createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
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
    final difference =
        currentTime.difference(widget.audioStartTime) * widget.playbackRate;
    return difference.inMicroseconds / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final offsetProvider = Provider.of<OffsetProvider>(context);
    final audioOffset = widget.isAudioPlaying
        ? offsetProvider.audioOffset * widget.playbackRate
        : 0;
    final inputOffset = widget.isAudioPlaying
        ? offsetProvider.inputOffset * widget.playbackRate
        : 0;
    final displayTime = elapsedTime - audioOffset + inputOffset;
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
