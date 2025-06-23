import 'package:flutter/material.dart';

/// 科目パターンを表すクラス
///
/// 科目名、教室、通常の曜日・時限から科目を一意に識別します。
/// 不規則な日程変更にも対応できるよう、通常の曜日・時限と実際の日程を分けて管理します。
class CoursePattern {
  /// 科目名
  final String subjectName;

  /// 教室
  final String classroom;

  /// 通常の曜日（0=月曜, 6=日曜）
  final int regularDayOfWeek;

  /// 通常の時限（1-6）
  final int regularPeriod;

  /// 科目の一意なID
  /// subjectName + classroom + regularDayOfWeek + regularPeriodから生成
  late final String courseId;

  /// 不規則な日程のマップ
  /// キー: 日付（yyyy-MM-dd形式）
  /// 値: 変更後の曜日と時限のペア
  final Map<String, ({int dayOfWeek, int period})> irregularSchedules;

  /// 休講日のリスト（yyyy-MM-dd形式）
  final List<String> cancelledDates;

  CoursePattern({
    required this.subjectName,
    required this.classroom,
    required this.regularDayOfWeek,
    required this.regularPeriod,
    Map<String, ({int dayOfWeek, int period})>? irregularSchedules,
    List<String>? cancelledDates,
  }) : irregularSchedules = irregularSchedules ?? {},
       cancelledDates = cancelledDates ?? [] {
    courseId = _generateCourseId();
  }

  /// 既存のcourseIdを使用するコンストラクタ
  CoursePattern._withExistingId({
    required this.subjectName,
    required this.classroom,
    required this.regularDayOfWeek,
    required this.regularPeriod,
    required String courseId,
    Map<String, ({int dayOfWeek, int period})>? irregularSchedules,
    List<String>? cancelledDates,
  }) : irregularSchedules = irregularSchedules ?? {},
       cancelledDates = cancelledDates ?? [] {
    this.courseId = courseId;
  }

  /// 既存のcourseIdを使用するファクトリーメソッド
  factory CoursePattern.withExistingId({
    required String subjectName,
    required String classroom,
    required int regularDayOfWeek,
    required int regularPeriod,
    required String courseId,
    Map<String, ({int dayOfWeek, int period})>? irregularSchedules,
    List<String>? cancelledDates,
  }) {
    return CoursePattern._withExistingId(
      subjectName: subjectName,
      classroom: classroom,
      regularDayOfWeek: regularDayOfWeek,
      regularPeriod: regularPeriod,
      courseId: courseId,
      irregularSchedules: irregularSchedules,
      cancelledDates: cancelledDates,
    );
  }

  /// 科目の一意なIDを生成
  String _generateCourseId() {
    return '$subjectName|$classroom|$regularDayOfWeek|$regularPeriod';
  }

  /// 指定された日付の曜日と時限を取得
  ///
  /// 不規則な日程がある場合はその値を、
  /// ない場合は通常の曜日・時限を返します。
  /// 休講の場合はnullを返します。
  ({int dayOfWeek, int period})? getScheduleForDate(String date) {
    if (cancelledDates.contains(date)) {
      return null;
    }
    return irregularSchedules[date] ??
        (dayOfWeek: regularDayOfWeek, period: regularPeriod);
  }

  /// 指定された期間の授業回数を計算
  int countClassesBetween(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;

    while (!current.isAfter(end)) {
      String dateStr =
          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      var schedule = getScheduleForDate(dateStr);
      if (schedule != null) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  /// 科目パターンをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'subjectName': subjectName,
      'classroom': classroom,
      'regularDayOfWeek': regularDayOfWeek,
      'regularPeriod': regularPeriod,
      'courseId': courseId,
      'irregularSchedules': irregularSchedules.map(
        (key, value) => MapEntry(key, {
          'dayOfWeek': value.dayOfWeek,
          'period': value.period,
        }),
      ),
      'cancelledDates': cancelledDates,
    };
  }

  /// JSONから科目パターンを生成
  factory CoursePattern.fromJson(Map<String, dynamic> json) {
    return CoursePattern(
      subjectName: json['subjectName'],
      classroom: json['classroom'],
      regularDayOfWeek: json['regularDayOfWeek'],
      regularPeriod: json['regularPeriod'],
      irregularSchedules: (json['irregularSchedules'] as Map<String, dynamic>)
          .map(
            (key, value) => MapEntry(key, (
              dayOfWeek: value['dayOfWeek'],
              period: value['period'],
            )),
          ),
      cancelledDates: List<String>.from(json['cancelledDates']),
    );
  }
}
