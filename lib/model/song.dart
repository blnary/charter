import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Song {
  final int id;
  final String name;
  final double bpm;
  final double offset;

  Song({
    required this.id,
    required this.name,
    required this.bpm,
    required this.offset,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as int,
      name: json['name'] as String,
      bpm: json['bpm'] as double,
      offset: json['offset'] as double,
    );
  }
}

class SongsProvider with ChangeNotifier {
  List<Song> _songs = [];
  int selected = 0;

  List<Song> get songs => _songs;
  int get id => songs[selected].id;
  String get name => songs[selected].name;
  double get bpm => songs[selected].bpm;
  int get offset => songs[selected].offset.round();

  Future<void> fetch(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonList = json.decode(response.body) as List<dynamic>;
      _songs = jsonList.map((json) => Song.fromJson(json)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to fetch song list: ${response.statusCode}');
    }
  }

  void select(int index) {
    selected = index;
    notifyListeners();
  }
}
