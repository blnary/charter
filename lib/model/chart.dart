import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChartsProvider with ChangeNotifier {
  List<Chart> _charts = [];
  bool _loading = false;
  bool _failed = false;
  String _failureMessage = '';

  Level? _level;
  int? _selected;

  List<Chart> get charts => _charts;
  bool get loading => _loading;
  bool get failed => _failed;
  String get failureMessage => _failureMessage;

  Level? get level => _level;
  int? get selected => _selected;
  int? get id {
    if (_selected == null) return null;
    return charts[_selected!].id;
  }

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

  void initLevel(double bpm, double offsetMs) {
    int offsetSamp = offsetMs * 441 ~/ 10;
    _level = Level(
      id: 0,
      name: 'Untitled',
      bpm: bpm,
      offset: offsetSamp,
      startPos: offsetSamp,
      hardStartPos: offsetSamp,
      endPos: offsetSamp,
      hardEndPos: offsetSamp,
      audioId: 0,
      difficulty: 4,
      sampleRate: 44100,
      difficultyLine: [],
      notes: [],
    );
    _selected = null;
    notifyListeners();
  }

  Future<String> create(int songId) async {
    try {
      const url = 'http://10.249.45.98/charts';
      final chart = Chart(id: 0, songId: songId, level: _level!);
      final jsonData = chart.toJson();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(jsonData),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as dynamic;
        if (!jsonData["success"]) {
          throw Exception('创建谱面失败: ${jsonData["msg"]}');
        }
        final newID = jsonData["chart_id"] as int;
        _charts.add(Chart(id: newID, songId: songId, level: _level!));
        _selected = _charts.length - 1;
        notifyListeners();
      } else {
        throw Exception('创建谱面失败: ${response.statusCode}');
      }
    } catch (error) {
      return '错误: $error';
    }
    return '成功设置！';
  }

  Future<String> set() async {
    try {
      final url = 'http://10.249.45.98/charts/${id!}';
      Level oldContent = _charts[_selected!].level;
      _charts[_selected!].level = level!;
      final jsonData = _charts[_selected!].toJson();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(jsonData),
      );
      if (response.statusCode != 200) {
        _charts[_selected!].level = oldContent;
        throw Exception('设置失败: ${response.statusCode}');
      }
    } catch (error) {
      return '错误: $error';
    }
    return '成功设置！';
  }

  void select(int index) {
    _selected = index;
    _level = _charts[index].level;
    notifyListeners();
  }
}

class Level {
  String name;
  double bpm;
  int id;
  int offset;
  int startPos;
  int hardStartPos;
  int endPos;
  int hardEndPos;
  int audioId;
  double difficulty;
  int sampleRate;
  List<Point> difficultyLine;
  List<Note> notes;

  Level({
    required this.name,
    required this.bpm,
    required this.id,
    required this.offset,
    required this.startPos,
    required this.hardStartPos,
    required this.endPos,
    required this.hardEndPos,
    required this.audioId,
    required this.difficulty,
    required this.sampleRate,
    required this.difficultyLine,
    required this.notes,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      name: json['name'] as String,
      bpm: json['bpm'] as double,
      id: json['id'] as int,
      offset: json['offset'] as int,
      startPos: json['startpos'] as int,
      hardStartPos: json['hardStartpos'] as int,
      endPos: json['endpos'] as int,
      hardEndPos: json['hardEndpos'] as int,
      audioId: json['audioId'] as int,
      difficulty: json['difficulty'] as double,
      sampleRate: json['sampleRate'] as int,
      difficultyLine: (json['difficultyLine'] as List<dynamic>)
          .map((pointJson) => Point.fromJson(pointJson))
          .toList(),
      notes: (json['notes'] as List<dynamic>)
          .map((noteJson) => Note.fromJson(noteJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bpm': bpm,
      'id': id,
      'offset': offset,
      'startpos': startPos,
      'hardStartpos': hardStartPos,
      'endpos': endPos,
      'hardEndpos': hardEndPos,
      'audioId': audioId,
      'difficulty': difficulty,
      'sampleRate': sampleRate,
      'difficultyLine': difficultyLine.map((point) => point.toJson()).toList(),
      'notes': notes.map((note) => note.toJson()).toList(),
    };
  }
}

class Point {
  double x;
  double y;

  Point({
    required this.x,
    required this.y,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      x: json['x'] as double,
      y: json['y'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}

class Note {
  int id;
  int p;
  int d;
  int s;

  Note({
    required this.id,
    required this.p,
    required this.d,
    required this.s,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      p: json['p'] as int,
      d: json['d'] as int,
      s: json['s'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'p': p,
      'd': d,
      's': s,
    };
  }
}

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
