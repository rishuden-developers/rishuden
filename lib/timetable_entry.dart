import 'package:flutter/material.dart';

enum AttendancePolicy { mandatory, flexible, skip }

// 授業への態度を表すenum
enum AttendanceAttitude {
  everytime, // 毎回出席
  whenFeelLike, // 気分で出席
  skip, // きる
}

class TimetableEntry {
  final String id;
  final String subjectName;
  final String classroom;
  final int dayOfWeek;
  final int period;
  final Color color;
  final bool isCancelled;
  final AttendancePolicy initialPolicy;

  /// 授業の日付（yyyy-MM-dd形式）
  final String date;

  /// 同じ教科を判別するためのID（CoursePatternのcourseIdと一致）
  String? courseId;

  /// 出席回数
  int attendanceCount;

  /// 授業への態度
  AttendanceAttitude attitude;

  /// 最終更新日時
  DateTime lastUpdated;

  TimetableEntry({
    required this.id,
    required this.subjectName,
    required this.classroom,
    required this.dayOfWeek,
    required this.period,
    required this.date,
    this.isCancelled = false,
    this.color = Colors.white,
    this.initialPolicy = AttendancePolicy.flexible,
    this.attendanceCount = 0,
    this.attitude = AttendanceAttitude.everytime,
    DateTime? lastUpdated,
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();

  // Firestoreとの相互変換用のメソッド
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectName': subjectName,
      'classroom': classroom,
      'dayOfWeek': dayOfWeek,
      'period': period,
      'date': date,
      'isCancelled': isCancelled,
      'color': color.value,
      'initialPolicy': initialPolicy.index,
      'courseId': courseId,
      'attendanceCount': attendanceCount,
      'attitude': attitude.index,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      id: map['id'],
      subjectName: map['subjectName'],
      classroom: map['classroom'],
      dayOfWeek: map['dayOfWeek'],
      period: map['period'],
      date: map['date'],
      isCancelled: map['isCancelled'] ?? false,
      color: Color(map['color']),
      initialPolicy: AttendancePolicy.values[map['initialPolicy']],
      attendanceCount: map['attendanceCount'] ?? 0,
      attitude: AttendanceAttitude.values[map['attitude'] ?? 0],
      lastUpdated: DateTime.parse(
        map['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
    )..courseId = map['courseId'];
  }
}
