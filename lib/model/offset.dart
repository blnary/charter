import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OffsetProvider with ChangeNotifier {
  int _inputOffset = 0;
  int _audioOffset = 0;
  late SharedPreferences prefs;

  int get inputOffset => _inputOffset;
  int get audioOffset => _audioOffset;

  OffsetProvider() {
    loadConfiguration();
  }

  Future<void> setInputOffset(int offset) async {
    _inputOffset = offset;
    notifyListeners();
    await saveConfiguration();
  }

  Future<void> setAudioOffset(int offset) async {
    _audioOffset = offset;
    notifyListeners();
    await saveConfiguration();
  }

  Future<void> saveConfiguration() async {
    await prefs.setInt('inputOffset', _inputOffset);
    await prefs.setInt('audioOffset', _audioOffset);
  }

  Future<void> loadConfiguration() async {
    prefs = await SharedPreferences.getInstance();
    _inputOffset = prefs.getInt('inputOffset') ?? 0;
    _audioOffset = prefs.getInt('audioOffset') ?? 0;
  }
}
