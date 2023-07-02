import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:charter/util/song_player.dart';

class MyAudioPlayerWidget extends StatefulWidget {
  final int id;

  const MyAudioPlayerWidget({required this.id, key}) : super(key: key);

  @override
  State createState() => _MyAudioPlayerWidgetState();
}

class _MyAudioPlayerWidgetState extends State<MyAudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _audioPosition = const Duration();
  late StreamSubscription<Duration> _positionSubscription;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((event) {
      setState(() {
        _audioPosition = event;
      });
    });
  }

  @override
  void dispose() async {
    _positionSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    final url = 'http://10.249.45.98/songs/${widget.id}';
    await playAudio(_audioPlayer, url);
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () => _playAudio(),
          child: const Text('Play'),
        ),
        ElevatedButton(
          onPressed: _pauseAudio,
          child: const Text('Pause'),
        ),
        Text(_formatDuration(_audioPosition)),
      ],
    );
  }
}
