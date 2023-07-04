import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OffsetProvider with ChangeNotifier {
  double _inputOffset = 0;
  double _audioOffset = 0;
  late SharedPreferences prefs;

  double get inputOffset => _inputOffset;
  double get audioOffset => _audioOffset;

  OffsetProvider() {
    loadConfiguration();
  }

  Future<void> setInputOffset(double offset) async {
    _inputOffset = offset;
    notifyListeners();
    await saveConfiguration();
  }

  Future<void> setAudioOffset(double offset) async {
    _audioOffset = offset;
    notifyListeners();
    await saveConfiguration();
  }

  Future<void> saveConfiguration() async {
    await prefs.setDouble('input_offset', _inputOffset);
    await prefs.setDouble('audio_offset', _audioOffset);
  }

  Future<void> loadConfiguration() async {
    prefs = await SharedPreferences.getInstance();
    _inputOffset = prefs.getDouble('input_offset') ?? 0;
    _audioOffset = prefs.getDouble('audio_offset') ?? 0;
  }
}
