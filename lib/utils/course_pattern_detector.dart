import 'package:rishuden/course_pattern.dart';
import 'package:rishuden/timetable_entry.dart';
import 'package:rishuden/services/course_pattern_service.dart';

/// 科目パターンを判定するためのユーティリティクラス
class CoursePatternDetector {
  /// 時間割エントリーのリストから科目パターンを検出
  ///
  /// 同じ科目名と教室の組み合わせを持つエントリーを集め、
  /// 最も頻度の高い曜日と時限を通常の時間として判定します。
  /// 既存のユーザーのcourseIdと照合して、一致するものがあれば既存のcourseIdを使用します。
  static Future<List<CoursePattern>> detectPatterns(
    List<TimetableEntry> entries,
  ) async {
    // 科目名と教室の組み合わせでグループ化
    Map<String, List<TimetableEntry>> groups = {};
    for (var entry in entries) {
      String key = '${entry.subjectName}|${entry.classroom}';
      groups.putIfAbsent(key, () => []).add(entry);
    }

    // 各グループから科目パターンを生成
    List<CoursePattern> patterns = [];
    for (var group in groups.values) {
      if (group.isEmpty) continue;

      // 曜日と時限の頻度をカウント
      Map<String, int> scheduleFrequency = {};
      for (var entry in group) {
        String scheduleKey = '${entry.dayOfWeek}|${entry.period}';
        scheduleFrequency[scheduleKey] =
            (scheduleFrequency[scheduleKey] ?? 0) + 1;
      }

      // 最も頻度の高い曜日と時限を取得
      String mostFrequentSchedule =
          scheduleFrequency.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
      List<String> parts = mostFrequentSchedule.split('|');
      int regularDayOfWeek = int.parse(parts[0]);
      int regularPeriod = int.parse(parts[1]);

      // 不規則な日程を特定
      Map<String, ({int dayOfWeek, int period})> irregularSchedules = {};
      List<String> cancelledDates = [];

      for (var entry in group) {
        // エントリーの日付を取得（TimetableEntryにdateフィールドを追加する必要あり）
        String dateStr = entry.date; // この行は実装が必要

        if (entry.isCancelled) {
          cancelledDates.add(dateStr);
        } else if (entry.dayOfWeek != regularDayOfWeek ||
            entry.period != regularPeriod) {
          irregularSchedules[dateStr] = (
            dayOfWeek: entry.dayOfWeek,
            period: entry.period,
          );
        }
      }

      // ★★★ 既存のcourseIdを検索 ★★★
      String? existingCourseId = await _findExistingCourseId(
        group[0].subjectName,
        group[0].classroom,
        regularDayOfWeek,
        regularPeriod,
      );

      if (existingCourseId != null) {
        print('DEBUG: 既存のcourseIdを使用: $existingCourseId');
        // 既存のcourseIdを使用してCoursePatternを作成
        patterns.add(
          CoursePattern.withExistingId(
            subjectName: group[0].subjectName,
            classroom: group[0].classroom,
            regularDayOfWeek: regularDayOfWeek,
            regularPeriod: regularPeriod,
            courseId: existingCourseId,
            irregularSchedules: irregularSchedules,
            cancelledDates: cancelledDates,
          ),
        );
      } else {
        print('DEBUG: 新しいcourseIdを生成');
        // 新しいcourseIdを生成
        patterns.add(
          CoursePattern(
            subjectName: group[0].subjectName,
            classroom: group[0].classroom,
            regularDayOfWeek: regularDayOfWeek,
            regularPeriod: regularPeriod,
            irregularSchedules: irregularSchedules,
            cancelledDates: cancelledDates,
          ),
        );
      }
    }

    return patterns;
  }

  /// 既存のcourseIdを検索
  /// 同じ授業名・教室・曜日・時限の組み合わせを持つCoursePatternを探す
  static Future<String?> _findExistingCourseId(
    String subjectName,
    String classroom,
    int regularDayOfWeek,
    int regularPeriod,
  ) async {
    try {
      // 期待されるcourseIdの形式
      String expectedCourseId =
          '$subjectName|$classroom|$regularDayOfWeek|$regularPeriod';

      // Firestoreから既存のCoursePatternを検索
      final coursePatternService = CoursePatternService();
      final existingPattern = await coursePatternService.getCoursePattern(
        expectedCourseId,
      );

      if (existingPattern != null) {
        return existingPattern.courseId;
      }

      return null;
    } catch (e) {
      print('Error finding existing courseId: $e');
      return null;
    }
  }
}
