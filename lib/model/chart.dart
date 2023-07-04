import 'dart:convert';
import 'package:charter/model/level.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Chart {
  int id;
  Level level;
  int songId;

  Chart({
    required this.id,
    required this.level,
    required this.songId,
  });

  factory Chart.fromJson(Map<String, dynamic> json) {
    return Chart(
      id: json['id'] as int,
      level: Level.fromJson(jsonDecode(json['content'] as String)),
      songId: json['song_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': level,
      'song_id': songId,
    };
  }
}

class ChartsProvider with ChangeNotifier {
  List<Chart> _charts = [];
  bool _loading = false;
  bool _failed = false;
  String _failureMessage = '';
  int _selected = 0;

  List<Chart> get charts => _charts;
  bool get loading => _loading;
  bool get failed => _failed;
  String get failureMessage => _failureMessage;
  int get selected => _selected;
  int get id => charts[_selected].id;
  Level get level => charts[_selected].level;

  ChartsProvider() {
    fetch();
  }

  Future<void> fetch() async {
    try {
      const url = "http://10.249.45.98/charts";
      _loading = true;
      notifyListeners();
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as dynamic;
        if (!jsonData["success"]) {
          throw Exception('获取谱面列表失败: ${jsonData["msg"]}');
        }
        final jsonList = jsonData["charts"] as List<dynamic>;
        _charts = jsonList.map((json) => Chart.fromJson(json)).toList();
      } else {
        throw Exception('获取谱面列表失败: ${response.statusCode}');
      }
    } catch (e) {
      _failed = true;
      _failureMessage = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> create(int songId, Level level) async {
    try {
      const url = 'http://10.249.45.98/charts';
      final jsonData = Chart(id: 0, songId: songId, level: level).toJson();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(jsonData),
      );
      if (response.statusCode != 200) {
        throw Exception('谱面创建失败: ${response.statusCode}');
      }
    } catch (error) {
      return '错误: $error';
    }
    return '成功设置！';
  }

  Future<String> set(int id, Level level) async {
    try {
      final url = 'http://10.249.45.98/charts/$id';
      Level oldContent = _charts[id].level;
      _charts[id].level = level;
      final jsonData = _charts[id].toJson();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(jsonData),
      );
      if (response.statusCode != 200) {
        _charts[id].level = oldContent;
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
}
