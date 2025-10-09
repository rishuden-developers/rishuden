import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'dart:convert';
import 'timetable_entry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rishuden/services/notification_service.dart';

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

// icsの表記形式をDateTimeに変換する関数
DateTime _parseIcsDateToDateTime(String dtStr) {
  // icsの表記形式は "20231001T120000Z" のような形式
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

// 時限ごとの開始・終了時刻を定義
final List<List<String>> _periodTimes = const [
  ["8:50", "10:20"],
  ["10:30", "12:00"],
  ["13:30", "15:00"],
  ["15:10", "16:40"],
  ["16:50", "18:20"],
  ["18:30", "20:00"],
];

// 時限番号から開始時刻と終了時刻をDateTimeオブジェクトとして取得するヘルパー関数
DateTime _getPeriodStartTime(DateTime date, int period) {
  final timeParts = _periodTimes[period - 1][0].split(':');
  return DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(timeParts[0]),
    int.parse(timeParts[1]),
  );
}

DateTime _getPeriodEndTime(DateTime date, int period) {
  final timeParts = _periodTimes[period - 1][1].split(':');
  return DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(timeParts[0]),
    int.parse(timeParts[1]),
  );
}

// 時限から開始・終了時刻を取得する公開関数
Map<String, DateTime> getPeriodStartAndEndTimes(DateTime date, int period) {
  if (period < 1 || period > _periodTimes.length) {
    // 不正な時限の場合は、現在時刻などを返すか、エラーを投げる
    // ここでは例として現在時刻を返す
    final now = DateTime.now();
    return {'start': now, 'end': now.add(const Duration(hours: 1))};
  }
  return {
    'start': _getPeriodStartTime(date, period),
    'end': _getPeriodEndTime(date, period),
  };
}

/// 今週のイベントをリストで返す（曜日・時限順ソート済み）
Future<List<Map<String, dynamic>>> _getWeeklyEventList(DateTime date) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('Error: User not logged in for timetable.');
    return [];
  }

  String calendarUrl = '';
  try {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (userDoc.exists && userDoc.data()!.containsKey('calendarUrl')) {
      calendarUrl = userDoc.data()!['calendarUrl'] as String? ?? '';
    }
  } catch (e) {
    print('Error fetching calendar URL from Firestore: $e');
    return [];
  }

  if (calendarUrl.isEmpty || !Uri.parse(calendarUrl).isAbsolute) {
    print('Calendar URL is empty or invalid: $calendarUrl');
    return [];
  }

  final url = Uri.parse(calendarUrl);

  final res = await http.get(url);
  if (res.statusCode != 200) {
    throw Exception('取得失敗');
  }

  String icsText = utf8.decode(res.bodyBytes);
  final calenderData = ICalendar.fromString(icsText);

  // 今週の月曜〜日曜を計算
  final monday = _getThisMonday(date);
  final sunday = _getThisSunday(date);

  final List<Map<String, dynamic>> holidays = [];
  final RegExp holidayReg = RegExp(r'^\[休\](\d+)限(.+)$');

  // 今週のイベントを抽出
  final events =
      calenderData.data
          .where((e) => e['dtend'] != null && e['type'] == 'VEVENT')
          .map((e) {
            final start = _parseIcsDateToDateTime(e['dtstart'].dt);
            final period = _getClassPeriodNumber(start);
            final actualStartTime = _getPeriodStartTime(start, period);
            final actualEndTime = _getPeriodEndTime(start, period);
            final subject = e['summary'];
            final match = holidayReg.firstMatch(subject);
            if (match != null) {
              holidays.add({
                'date': DateTime(start.year, start.month, start.day),
                'period': int.parse(match.group(1)!),
                'subject': match.group(2)!.trim(),
              });
              return null; // 休講は除外
            }
            return {
              'dtstart': actualStartTime,
              'dtend': actualEndTime,
              'weekday': start.weekday - 1, // 0=月曜, 6=日曜
              'period': period,
              'location': e["location"] ?? '（場所未定）',
              'subject': subject,
            };
          })
          .whereType<Map<String, dynamic>>() // null(休講)を除外
          .where(
            (ev) =>
                (
                // その週の月曜から日曜だけ取り出す
                ev['dtstart'].isAfter(monday) &&
                    ev['dtstart'].isBefore(sunday)),
          )
          .toList()
        ..sort((a, b) {
          // まず曜日で比較（0=月曜, 6=日曜）
          int cmp = a['weekday'].compareTo(b['weekday']);
          if (cmp != 0) return cmp;
          // 曜日が同じならclassPeriodNumber（時限）で比較
          return a['period'].compareTo(b['period']);
        });

  // 休講情報をイベントに追加
  for (final ev in events) {
    ev['isCancelled'] = holidays.any(
      (h) =>
          h['date'] ==
              DateTime(
                ev['dtstart'].year,
                ev['dtstart'].month,
                ev['dtstart'].day,
              ) &&
          h['period'] == ev['period'] &&
          h['subject'] == ev['subject'],
    );
  }

  return events;
}

Future<List<TimetableEntry>> getWeeklyTimetableEntries(DateTime date) async {
  final events = await _getWeeklyEventList(date);

  final List<TimetableEntry> timetableEntries = [];

  for (final ev in events) {
    final int weekday = ev['weekday'];
    final int period = ev['period'];
    final DateTime eventDate = ev['dtstart'];
    final String dateStr =
        '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';

    final description = ev['subject'] as String;
    final location = ev['location'] as String;
    final DateTime startTime = ev['dtstart'];
    final DateTime endTime = ev['dtend'];

    // ★★★ 教室名を整形するロジックを強化 ★★★
    String formattedLocation = '';
    if (location.toLowerCase().contains('zoom') ||
        location.toLowerCase().contains('webex') ||
        location.toLowerCase().contains('online')) {
      formattedLocation = 'オンライン';
    } else {
      // 1. 全角英数字を半角に変換
      final normalizedLocation = location.replaceAllMapped(
        RegExp(r'[Ａ-Ｚａ-ｚ０-９]'),
        (Match m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0xFEE0),
      );

      // 2. 優先順位を付けた正規表現で教室名を抽出
      final regex = RegExp(
        r'(全教/豊中総合学館\d+)|' // ★特定のパターンを追加
        r'([A-Z]+-?\d+)|' // A-101, C101など
        r'(\w+総合学館\d+)|' // 豊中総合学館302 → 豊中302
        r'(\d+号館-?\d+[a-zA-Z]?室?)|' // 5号館-201, 5号館201室など
        r'(\w+教室|\w+実習室|\w+ホール|総合体育館|武道館)|' // 〇〇教室など
        r'(\d+号館)|' // 5号館
        r'\(([^)]+)\)|' // (A-101)など括弧の中身
        r'(\b[A-Z]+\b)',
      ); // KIC, OICなどの大文字の略称

      final match = regex.firstMatch(normalizedLocation);

      if (match != null) {
        // マッチした部分（キャプチャグループ）を順番に探し、最初に見つかったものを採用
        for (int i = 1; i <= match.groupCount; i++) {
          if (match.group(i) != null) {
            formattedLocation = match.group(i)!;
            break;
          }
        }
        if (formattedLocation.isEmpty) {
          formattedLocation = match.group(0)!; // フォールバック
        }

        // ★★★ 特定の文字列を短縮する処理 ★★★
        if (formattedLocation.startsWith('全教/豊中総合学館')) {
          formattedLocation = formattedLocation.replaceAll('全教/豊中総合学館', '豊中');
        } else if (formattedLocation.contains('総合学館')) {
          formattedLocation = formattedLocation.replaceAll('総合学館', '');
        }
      } else {
        // 3. マッチしない場合のフォールバック（不要な部分を削除）
        formattedLocation =
            normalizedLocation
                .replaceAll(RegExp(r'【.*】'), '')
                .replaceAll(RegExp(r'全教/共|OIC |BKC |KIC '), '')
                .replaceAll(RegExp(r'\(.*?\)'), '')
                .trim();
      }
    }

    final info = TimetableEntry(
      id: '${weekday * 10 + period}', // IDは曜日と時限の組み合わせ
      subjectName: description,
      classroom: formattedLocation, // ★★★ 整形した教室名を使用 ★★★
      originalLocation: location, // ★★★ 整形前の正式名称を保存 ★★★
      dayOfWeek: weekday, // 曜日（0=月曜, 6=日曜）
      period: period, // 時限（1〜6）
      date: dateStr,
      startTime: startTime,
      endTime: endTime,
      isCancelled: ev['isCancelled'], // 休講フラグ
    );
    timetableEntries.add(info);

    // 授業終了時に通知をスケジュール
    if (info.attitude == AttendanceAttitude.everytime && !info.isCancelled) {
      NotificationService().scheduleAttendanceNotification(
        id: info.hashCode, // ユニークな通知ID
        subjectName: info.subjectName,
        period: info.period.toString(),
        date: info.date,
        endTime: info.endTime,
      );
    }
  }

  return timetableEntries;
}
