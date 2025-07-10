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
  final String originalLocation;
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

  /// 学部情報
  String? faculty;

  /// 最終更新日時
  DateTime lastUpdated;

  TimetableEntry({
    required this.id,
    required this.subjectName,
    required this.classroom,
    required this.originalLocation,
    required this.dayOfWeek,
    required this.period,
    required this.date,
    this.isCancelled = false,
    this.color = Colors.white,
    this.initialPolicy = AttendancePolicy.flexible,
    this.attendanceCount = 0,
    this.attitude = AttendanceAttitude.everytime,
    this.faculty,
    DateTime? lastUpdated,
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();

  // Firestoreとの相互変換用のメソッド
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectName': subjectName,
      'classroom': classroom,
      'originalLocation': originalLocation,
      'dayOfWeek': dayOfWeek,
      'period': period,
      'date': date,
      'isCancelled': isCancelled,
      'color': color.value,
      'initialPolicy': initialPolicy.index,
      'courseId': courseId,
      'attendanceCount': attendanceCount,
      'attitude': attitude.index,
      'faculty': faculty,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    try {
      // 必須フィールドの安全な取得
      final id = map['id']?.toString() ?? '';
      final subjectName = map['subjectName']?.toString() ?? '';
      final classroom = map['classroom']?.toString() ?? '';
      final originalLocation = map['originalLocation']?.toString() ?? classroom;

      // 数値フィールドの安全な取得
      final dayOfWeek =
          (map['dayOfWeek'] is int)
              ? map['dayOfWeek'] as int
              : (map['dayOfWeek'] is String)
              ? int.tryParse(map['dayOfWeek']) ?? 0
              : 0;
      final period =
          (map['period'] is int)
              ? map['period'] as int
              : (map['period'] is String)
              ? int.tryParse(map['period']) ?? 1
              : 1;

      final date = map['date']?.toString() ?? '';
      final isCancelled = map['isCancelled'] as bool? ?? false;

      // 色の安全な取得
      Color color;
      try {
        if (map['color'] is int) {
          color = Color(map['color'] as int);
        } else if (map['color'] is String) {
          color = Color(int.tryParse(map['color']) ?? 0xFFFFFFFF);
        } else {
          color = Colors.white;
        }
      } catch (e) {
        print('色の変換エラー: $e, 値: ${map['color']}');
        color = Colors.white;
      }

      // enumの安全な取得
      AttendancePolicy initialPolicy;
      try {
        final policyIndex =
            (map['initialPolicy'] is int)
                ? map['initialPolicy'] as int
                : (map['initialPolicy'] is String)
                ? int.tryParse(map['initialPolicy']) ?? 1
                : 1;
        initialPolicy =
            AttendancePolicy.values[policyIndex.clamp(
              0,
              AttendancePolicy.values.length - 1,
            )];
      } catch (e) {
        print('AttendancePolicy変換エラー: $e, 値: ${map['initialPolicy']}');
        initialPolicy = AttendancePolicy.flexible;
      }

      final attendanceCount =
          (map['attendanceCount'] is int)
              ? map['attendanceCount'] as int
              : (map['attendanceCount'] is String)
              ? int.tryParse(map['attendanceCount']) ?? 0
              : 0;

      AttendanceAttitude attitude;
      try {
        final attitudeIndex =
            (map['attitude'] is int)
                ? map['attitude'] as int
                : (map['attitude'] is String)
                ? int.tryParse(map['attitude']) ?? 0
                : 0;
        attitude =
            AttendanceAttitude.values[attitudeIndex.clamp(
              0,
              AttendanceAttitude.values.length - 1,
            )];
      } catch (e) {
        print('AttendanceAttitude変換エラー: $e, 値: ${map['attitude']}');
        attitude = AttendanceAttitude.everytime;
      }

      final faculty = map['faculty']?.toString();

      // 日時の安全な取得
      DateTime lastUpdated;
      try {
        final lastUpdatedStr = map['lastUpdated']?.toString();
        if (lastUpdatedStr != null && lastUpdatedStr.isNotEmpty) {
          lastUpdated = DateTime.parse(lastUpdatedStr);
        } else {
          lastUpdated = DateTime.now();
        }
      } catch (e) {
        print('日時変換エラー: $e, 値: ${map['lastUpdated']}');
        lastUpdated = DateTime.now();
      }

      final entry = TimetableEntry(
        id: id,
        subjectName: subjectName,
        classroom: classroom,
        originalLocation: originalLocation,
        dayOfWeek: dayOfWeek,
        period: period,
        date: date,
        isCancelled: isCancelled,
        color: color,
        initialPolicy: initialPolicy,
        attendanceCount: attendanceCount,
        attitude: attitude,
        faculty: faculty,
        lastUpdated: lastUpdated,
      );

      // courseIdの設定
      entry.courseId = map['courseId']?.toString();

      return entry;
    } catch (e, stackTrace) {
      print('TimetableEntry.fromMap エラー: $e');
      print('スタックトレース: $stackTrace');
      print('問題のマップ: $map');

      // フォールバック用の最小限のデータで作成
      return TimetableEntry(
        id:
            map['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        subjectName: map['subjectName']?.toString() ?? '不明な講義',
        classroom: map['classroom']?.toString() ?? '',
        originalLocation:
            map['originalLocation']?.toString() ??
            map['classroom']?.toString() ??
            '',
        dayOfWeek: 0,
        period: 1,
        date: '',
      );
    }
  }
}
