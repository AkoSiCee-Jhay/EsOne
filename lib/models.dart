import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  @HiveField(0)
  String title;
  @HiveField(1)
  String content;
  @HiveField(2)
  DateTime updatedAt;

  // THE FIX: Added defaultValue: false
  @HiveField(3, defaultValue: false)
  bool isThread;

  NoteModel({
    required this.title,
    required this.content,
    required this.updatedAt,
    this.isThread = false,
  });
}

@HiveType(typeId: 1)
class WhiteboardStroke extends HiveObject {
  @HiveField(0)
  List<Offset> points;
  @HiveField(1)
  int colorValue;
  @HiveField(2)
  double strokeWidth;

  WhiteboardStroke({
    required this.points,
    required this.colorValue,
    required this.strokeWidth,
  });
}
