import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Song {
  final int id;
  final String name;

  Song({
    required this.id,
    required this.name,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class SongsProvider with ChangeNotifier {
  List<Song> _songs = [];

  List<Song> get songs => _songs;

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
}
