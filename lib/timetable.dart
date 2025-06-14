import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'dart:convert';
import 'timetable_entry.dart';

final urlStr =
    "https://g-calendar.koan.osaka-u.ac.jp/calendar/ebe7de71ce859c00d7fdb647a65002b03694b867-J.ics";

// dateを含む週の月曜日と日曜日のDateTimeを計算する関数
DateTime _getThisMonday(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  // 時・分・秒・ミリ秒を0にして返す
  return DateTime(monday.year, monday.month, monday.day);
}

DateTime _getThisSunday(DateTime date) {
  final sunday = date.add(Duration(days: DateTime.daysPerWeek - date.weekday));
  // 時・分・秒・ミリ秒を0にして返す
  return DateTime(sunday.year, sunday.month, sunday.day);
}

// icsのdtstart->dtをDateTimeに変換する関数
DateTime _parseIcsDate(String dtStr) {
  // dtStrの形式は "20231001T120000Z" のような形式
  // これをiso8601形式に変換した後、DateTimeに変換する
  return DateTime.parse(
    '${dtStr.substring(0, 4)}-${dtStr.substring(4, 6)}-${dtStr.substring(6, 8)}'
    'T${dtStr.substring(9, 11)}:${dtStr.substring(11, 13)}:${dtStr.substring(13, 15)}',
  );
}

int _getClassPeriodNumber(DateTime start) {
  // 開始時間から授業の時限を計算する
  switch (start.hour) {
    case 8:
      return 1; // 開始が8時台は1時限
    case 10:
      return 2; // 開始が10時台は2時限
    case 13:
      return 3; // 開始が13時台は3時限
    case 14:
      return 4; // 開始が15時台が4時限だが、ics上ではなぜか14時台に設定されているので、14時台を4時限とする
    case 16:
      return 5; // 開始が16時台は5時限
    case 18:
      return 6; // 開始が18時台は6時限
    default:
      break;
  }
  return 0; // 該当しない場合は0を返す
}

/// 今週のイベントをリストで返す（曜日・時限順ソート済み）
Future<List<Map<String, dynamic>>> _getWeeklyEventList(DateTime date) async {
  final url = Uri.parse(urlStr);

  final res = await http.get(url);
  if (res.statusCode != 200) {
    throw Exception('取得失敗');
  }

  String icsText = utf8.decode(res.bodyBytes);
  final calenderData = ICalendar.fromString(icsText);

  // 今週の月曜〜日曜を計算
  final monday = _getThisMonday(date);
  final sunday = _getThisSunday(date);

  // 今週のイベントを抽出
  final events =
      calenderData.data
          .where((e) => e['dtend'] != null && e['type'] == 'VEVENT')
          .map<Map<String, dynamic>>((e) {
            final start = _parseIcsDate(e['dtstart'].dt);
            return {
              'weekday': start.weekday - 1, // 0=月曜, 6=日曜
              'classPeriodNumber': _getClassPeriodNumber(start),
              'location': e["location"] ?? '（場所未定）',
              'summary': e['summary'] ?? '（タイトルなし）',
            };
          })
          .where(
            (ev) =>
                (ev['weekday'] >= monday.weekday &&
                    ev['weekday'] <= sunday.weekday),
          )
          .toList()
        ..sort((a, b) {
          // まず曜日で比較（0=月曜, 6=日曜）
          int cmp = a['weekday'].compareTo(b['weekday']);
          if (cmp != 0) return cmp;
          // 曜日が同じならclassPeriodNumber（時限）で比較
          return a['classPeriodNumber'].compareTo(b['classPeriodNumber']);
        });

  return events;
}

Future<List<TimetableEntry>> getWeeklyTimetableEntries(DateTime date) async {
  final events = await _getWeeklyEventList(date);

  final List<TimetableEntry> timetableEntries = [];

  for (final ev in events) {
    final int weekday = ev['weekday'];
    final int period = ev['classPeriodNumber'];
    final info = TimetableEntry(
      id: '${weekday * 10 + period}', // IDは曜日と時限の組み合わせ
      subjectName: ev['summary'] as String,
      classroom: ev['location'] as String,
      dayOfWeek: weekday, // 曜日（0=月曜, 6=日曜）
      period: period, // 時限（1〜6）
    );
    timetableEntries.add(info);
  }

  return timetableEntries;
}
