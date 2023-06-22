import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

class ConfigProvider with ChangeNotifier {
  String songListUrl = '';
  String songFileUrl = '';
  String songPostUrl = '';

  ConfigProvider() {
    loadConfig();
  }

  Future<void> loadConfig() async {
    final configYaml = await rootBundle.loadString('config.yaml');
    final config = loadYaml(configYaml);

    songListUrl = config['song_list_url'] ?? '';
    songFileUrl = config['song_file_url'] ?? '';
    songPostUrl = config['song_post_url'] ?? '';

    notifyListeners();
  }
}
