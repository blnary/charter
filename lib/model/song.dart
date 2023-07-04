import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Song {
  final int id;
  final String name;
  final String location;
  final double bpm;
  final int offset;

  Song({
    required this.id,
    required this.name,
    required this.location,
    required this.bpm,
    required this.offset,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final bpm = json['bpm'] as num;
    final offset = json['offset'] as num;
    return Song(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
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
  String get location => songs[_selected].location;
  double get bpm => songs[_selected].bpm;
  int get offset => songs[_selected].offset;

  SongsProvider() {
    fetch();
  }

  Future<void> fetch() async {
    try {
      const url = "http://10.249.45.98/songs";
      _loading = true;
      notifyListeners();
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as dynamic;
        if (!jsonData["success"]) {
          throw Exception('获取歌曲列表失败: ${jsonData["msg"]}');
        }
        final jsonList = jsonData["songs"] as List<dynamic>;
        _songs = jsonList.map((json) => Song.fromJson(json)).toList();
      } else {
        throw Exception('获取歌曲列表失败: ${response.statusCode}');
      }
    } catch (e) {
      _failed = true;
      _failureMessage = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> sync() async {
    try {
      final url = 'http://10.249.45.98/sync/$id';
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as dynamic;
        if (!jsonData["success"]) {
          throw Exception('获取更新的 BPM 失败: ${jsonData["msg"]}');
        }
        final bpm = jsonData["bpm"] as num;
        final offset = jsonData["offset"] as num;
        songs[_selected] = Song(
          id: id,
          name: name,
          location: location,
          bpm: bpm.toDouble(),
          offset: offset.toInt(),
        );
        notifyListeners();
      } else {
        throw Exception('同步失败: ${response.statusCode}');
      }
    } catch (error) {
      return '错误: $error';
    }
    return '成功同步！';
  }

  Future<String> cal() async {
    try {
      final url = 'http://10.249.45.98/cal/$id';
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as dynamic;
        if (!jsonData["success"]) {
          throw Exception('获取更新的 BPM 失败: ${jsonData["msg"]}');
        }
        final bpm = jsonData["bpm"] as num;
        final offset = jsonData["offset"] as num;
        songs[_selected] = Song(
          id: id,
          name: name,
          location: location,
          bpm: bpm.toDouble(),
          offset: offset.toInt(),
        );
        notifyListeners();
      } else {
        throw Exception('计算失败: ${response.statusCode}');
      }
    } catch (error) {
      return '错误: $error';
    }
    return '成功计算！';
  }

  Future<String> set(double bpm, int offset) async {
    try {
      final url = 'http://10.249.45.98/bpm/$id';
      final jsonData = {
        'bpm': bpm,
        'offset': offset,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(jsonData),
      );
      if (response.statusCode == 200) {
        songs[_selected] = Song(
          id: id,
          name: name,
          location: location,
          bpm: bpm.toDouble(),
          offset: offset.toInt(),
        );
        notifyListeners();
      } else {
        throw Exception('设置失败: ${response.statusCode}');
      }
    } catch (error) {
      return '错误: $error';
    }
    return '成功设置！';
  }

  void select(int index) {
    _selected = index;
    notifyListeners();
  }

  void selectFromID(int id) {
    for (var i = 0; i < _songs.length; i++) {
      if (_songs[i].id == id) {
        _selected = i;
        notifyListeners();
        return;
      }
    }
  }
}
