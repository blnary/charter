import 'dart:convert';

import 'package:flutter/material.dart';

class LevelProvider with ChangeNotifier {
  Level? _level;
  Level? get level => _level;

  Level initLevel(double bpm, int offset) {
    int offsetSamp = offset * 441 ~/ 10;
    Level result = Level(
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
    _level = result;
    return result;
  }

  void setLevel(String level) {
    _level = Level.fromJson(jsonDecode(level));
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
