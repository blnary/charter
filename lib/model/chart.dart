import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChartsProvider with ChangeNotifier {
  List<Chart> _charts = [];
  bool _loading = false;
  bool _failed = false;
  String _failureMessage = '';

  int _levelNotes = 0;
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
      const url = "http://test.undecla.red/charts";
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

  void initLevel(double bpm, double offsetMs, String name) {
    int offsetSamp = (offsetMs * 44.1).round();
    _level = Level(
      id: 0,
      name: name,
      bpm: bpm,
      offsetSamp: offsetSamp,
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

  void setName(String name) {
    if (_level == null) return;
    _level!.name = name;
  }

  void setDifficulty(double diffculty) {
    if (_level == null) return;
    _level!.difficulty = diffculty;
  }

  void addAlignedNoteAt(double time, Direction dir, int strength, int decimal) {
    if (_level == null) return;
    double bpm = _level!.bpm;
    double unit = 60000 / bpm / decimal;
    double offsetMs = _level!.offsetSamp / 44.1;
    double unitCount = (time - offsetMs) / unit;
    double alignedTime = unitCount.round() * unit + offsetMs;
    addNoteAt(alignedTime, dir, strength);
  }

  void addNoteAt(double time, Direction dir, int strength) {
    _level?.notes.add(Note(
        id: _levelNotes, p: (time * 44.1).round(), d: toInt(dir), s: strength));
    notifyListeners();
  }

  void deleteNoteAt(double time) {
    _level?.notes
        .removeWhere((element) => (time - element.p / 44.1 + 150).abs() < 150);
    notifyListeners();
  }

  Future<String> createOrSet(int songId) async {
    if (_selected == null) {
      return create(songId);
    } else {
      return set();
    }
  }

  Future<String> create(int songId) async {
    try {
      const url = 'http://test.undecla.red/charts';
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
      // Sort notes for level, generate endPos and hardStartPos for level
      level!.notes.sort((a, b) => a.p.compareTo(b.p));
      level!.notes.asMap().forEach((index, note) => note.id = index);
      level!.endPos = level!.notes.last.p;
      level!.startPos = level!.notes.first.p;
      level!.hardStartPos = level!.notes.firstWhere((note) => note.s == 3).p;
      final url = 'http://test.undecla.red/charts/${id!}';
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
    _levelNotes = _level!.notes.length;
    notifyListeners();
  }
}

class Level {
  String name;
  double bpm;
  int id;
  int offsetSamp;
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
    required this.offsetSamp,
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
      offsetSamp: json['offset'] as int,
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
      'offset': offsetSamp,
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

enum Direction {
  center,
  up,
  down,
  left,
  right,
}

int toInt(Direction direction) {
  return direction.index;
}

Direction fromInt(int value) {
  return Direction.values[value];
}

double toAlign(Direction direction) {
  const unit = 0.4;
  switch (direction) {
    case Direction.center:
      return 0;
    case Direction.left:
      return -unit * 2;
    case Direction.down:
      return -unit;
    case Direction.up:
      return unit;
    case Direction.right:
      return unit * 2;
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
      'content': jsonEncode(level.toJson()),
      'song_id': songId,
    };
  }
}