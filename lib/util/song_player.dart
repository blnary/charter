import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

Future<void> loadAudio(String url) async {
  final filename = url.hashCode.toString();
  final appDir = await getApplicationDocumentsDirectory();
  final filePath = '${appDir.path}/$filename';

  // Check if file already exists in application storage
  final file = File(filePath);
  if (!await file.exists()) {
    // File doesn't exist, download it from the URI
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }
}

Future<AudioPlayer> playAudio(AudioPlayer player, String url) async {
  await loadAudio(url);
  await player.play(UrlSource(url));
  return player;
}
