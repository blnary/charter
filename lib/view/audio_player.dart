import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../util/song_player.dart';
import '../model/config.dart';

class MyAudioPlayerWidget extends StatefulWidget {
  final int id;

  const MyAudioPlayerWidget({required this.id, key}) : super(key: key);

  @override
  State createState() => _MyAudioPlayerWidgetState();
}

class _MyAudioPlayerWidgetState extends State<MyAudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  Duration _audioPosition = const Duration();

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPositionChanged.listen((event) {
      setState(() {
        _audioPosition = event;
      });
    });
  }

  Future<void> _playAudio(String songFileUrl) async {
    final url = '$songFileUrl/${widget.id}';
    await playAudio(_audioPlayer, url);
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, configProvider, _) {
        final songFileUrl = configProvider.songFileUrl;

        return Row(
          children: [
            ElevatedButton(
              onPressed: () => _playAudio(songFileUrl),
              child: const Text('Play'),
            ),
            ElevatedButton(
              onPressed: _pauseAudio,
              child: const Text('Pause'),
            ),
            ElevatedButton(
              onPressed: _stopAudio,
              child: const Text('Stop'),
            ),
            Text(_formatDuration(_audioPosition)),
          ],
        );
      },
    );
  }
}
