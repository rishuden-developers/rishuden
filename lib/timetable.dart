import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'dart:convert';
import 'timetable_entry.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              'dtstart': start,
              'weekday': start.weekday - 1, // 0=月曜, 6=日曜
              'period': _getClassPeriodNumber(start),
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

    final info = TimetableEntry(
      id: '${weekday * 10 + period}', // IDは曜日と時限の組み合わせ
      subjectName: ev['subject'] as String,
      classroom: ev['location'] as String,
      dayOfWeek: weekday, // 曜日（0=月曜, 6=日曜）
      period: period, // 時限（1〜6）
      date: dateStr,
      isCancelled: ev['isCancelled'], // 休講フラグ
    );
    timetableEntries.add(info);
  }

  return timetableEntries;
}
