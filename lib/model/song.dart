import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Song {
  final int id;
  final String name;
  final double bpm;
  final int offset;

  Song({
    required this.id,
    required this.name,
    required this.bpm,
    required this.offset,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final bpm = json['bpm'] as num;
    final offset = json['offset'] as num;
    return Song(
      id: json['id'] as int,
      name: json['name'] as String,
      bpm: bpm.toDouble(),
      offset: offset.toInt(),
    );
  }
}

class SongsProvider with ChangeNotifier {
  List<Song> _songs = [];
  bool _loading = false;
  bool _failed = false;
  String _failureMessage = '';
  int _selected = 0;

  List<Song> get songs => _songs;
  bool get loading => _loading;
  bool get failed => _failed;
  String get failureMessage => _failureMessage;
  int get selected => _selected;
  int get id => songs[_selected].id;
  String get name => songs[_selected].name;
  double get bpm => songs[_selected].bpm;
  int get offset => songs[_selected].offset;

  SongsProvider() {
    fetch("http://10.249.45.98/songs");
  }

  Future<void> fetch(String url) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as dynamic;
        if (!jsonData["success"]) {
          throw Exception('Failed to fetch song list: ${jsonData["message"]}');
        }
        final jsonList = jsonData["songs"] as List<dynamic>;
        _songs = jsonList.map((json) => Song.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch song list: ${response.statusCode}');
      }
    } catch (e) {
      _failed = true;
      _failureMessage = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void select(int index) {
    _selected = index;
    notifyListeners();
  }
}
