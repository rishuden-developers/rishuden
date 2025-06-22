import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 時間割のメモデータを管理するProvider
class TimetableNotifier extends StateNotifier<Map<String, dynamic>> {
  TimetableNotifier()
    : super({
        'cellNotes': <String, String>{},
        'weeklyNotes': <String, String>{},
        'attendancePolicies': <String, String>{},
        'attendanceStatus': <String, String>{},
        'absenceCount': <String, int>{},
        'lateCount': <String, int>{},
        'teacherNames': <String, String>{},
        'questSelectedClass': null,
        'questTaskType': null,
        'questDeadline': null,
        'questDescription': '',
      }) {
    // 初期化時にFirebaseからデータを読み込み
    _initializeFromFirebase();
  }

  // ★★★ 初期化時にFirebaseからデータを読み込む ★★★
  Future<void> _initializeFromFirebase() async {
    try {
      await loadFromFirestore();
    } catch (e) {
      print('Error initializing from Firebase: $e');
    }
  }

  // セルメモを更新
  void updateCellNotes(Map<String, String> cellNotes) {
    state = {...state, 'cellNotes': cellNotes};
    _saveToFirestore();
  }

  // 週次メモを更新
  void updateWeeklyNotes(Map<String, String> weeklyNotes) {
    state = {...state, 'weeklyNotes': weeklyNotes};
    _saveToFirestore();
  }

  // 出席ポリシーを更新
  void updateAttendancePolicies(Map<String, String> policies) {
    state = {...state, 'attendancePolicies': policies};
    _saveToFirestore();
  }

  // 出席状況を更新
  void updateAttendanceStatus(Map<String, Map<String, String>> status) {
    state = {...state, 'attendanceStatus': status};
    _saveToFirestore();
  }

  // 欠席回数を更新
  void updateAbsenceCount(Map<String, int> absenceCount) {
    state = {...state, 'absenceCount': absenceCount};
    _saveToFirestore();
  }

  // 遅刻回数を更新
  void updateLateCount(Map<String, int> count) {
    final currentData = Map<String, dynamic>.from(state);
    currentData['lateCount'] = count;
    state = currentData;
    _saveToFirestore();
  }

  // 教員名を更新
  void updateTeacherNames(Map<String, String> teacherNames) {
    final currentData = Map<String, dynamic>.from(state);
    currentData['teacherNames'] = teacherNames;
    state = currentData;
    _saveToFirestore();
  }

  // クエスト作成の状態を更新
  void updateQuestSelectedClass(Map<String, dynamic>? selectedClass) {
    print('TimetableProvider - Updating questSelectedClass: $selectedClass');
    state = {...state, 'questSelectedClass': selectedClass};
    _saveToFirestore();
  }

  void updateQuestTaskType(String? taskType) {
    print('TimetableProvider - Updating questTaskType: $taskType');
    state = {...state, 'questTaskType': taskType};
    _saveToFirestore();
  }

  void updateQuestDeadline(DateTime? deadline) {
    print('TimetableProvider - Updating questDeadline: $deadline');
    state = {...state, 'questDeadline': deadline?.toIso8601String()};
    _saveToFirestore();
  }

  void updateQuestDescription(String description) {
    print('TimetableProvider - Updating questDescription: $description');
    state = {...state, 'questDescription': description};
    _saveToFirestore();
  }

  // クエスト作成の状態をリセット
  void resetQuestData() {
    print('TimetableProvider - Resetting quest data');
    state = {
      ...state,
      'questSelectedClass': null,
      'questTaskType': null,
      'questDeadline': null,
      'questDescription': '',
    };
    _saveToFirestore();
  }

  // 特定のセルメモを追加・更新
  void setCellNote(String key, String note) {
    final cellNotes = Map<String, String>.from(state['cellNotes']);
    if (note.isEmpty) {
      cellNotes.remove(key);
    } else {
      cellNotes[key] = note;
    }
    updateCellNotes(cellNotes);
  }

  // 特定の週次メモを追加・更新
  void setWeeklyNote(String key, String note) {
    final weeklyNotes = Map<String, String>.from(state['weeklyNotes']);
    if (note.isEmpty) {
      weeklyNotes.remove(key);
    } else {
      weeklyNotes[key] = note;
    }
    updateWeeklyNotes(weeklyNotes);
  }

  // Firestoreからデータを読み込み
  Future<void> loadFromFirestore() async {
    try {
      print('TimetableProvider - Starting loadFromFirestore');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('TimetableProvider - User found: ${user.uid}');
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('timetable')
                .doc('notes')
                .get();

        if (doc.exists) {
          final data = doc.data()!;
          print('TimetableProvider - Firestore data loaded: ${data.keys}');
          print(
            'TimetableProvider - Cell notes count: ${(data['cellNotes'] as Map<String, dynamic>?)?.length ?? 0}',
          );
          print(
            'TimetableProvider - Weekly notes count: ${(data['weeklyNotes'] as Map<String, dynamic>?)?.length ?? 0}',
          );

          // ★★★ 出席状態のデータ構造を変換 ★★★
          Map<String, Map<String, String>> attendanceStatus = {};
          final oldAttendanceStatus = data['attendanceStatus'];
          if (oldAttendanceStatus != null) {
            if (oldAttendanceStatus is Map<String, dynamic>) {
              // 新しい形式の場合
              for (var entry in oldAttendanceStatus.entries) {
                if (entry.value is Map<String, dynamic>) {
                  attendanceStatus[entry.key] = Map<String, String>.from(
                    entry.value,
                  );
                }
              }
            } else {
              // 古い形式の場合：後方互換性のための変換
              print(
                'TimetableProvider - Converting old attendance status format',
              );
              final oldStatus = Map<String, String>.from(oldAttendanceStatus);
              for (var entry in oldStatus.entries) {
                // 古い形式: "courseId_20241201" -> "absent"
                // 新しい形式: "courseId" -> {"20241201": "absent"}
                final parts = entry.key.split('_');
                if (parts.length >= 2) {
                  final date = parts.last;
                  final courseId = parts.sublist(0, parts.length - 1).join('_');

                  if (!attendanceStatus.containsKey(courseId)) {
                    attendanceStatus[courseId] = {};
                  }
                  attendanceStatus[courseId]![date] = entry.value;
                }
              }
            }
          }

          state = {
            'cellNotes': Map<String, String>.from(data['cellNotes'] ?? {}),
            'weeklyNotes': Map<String, String>.from(data['weeklyNotes'] ?? {}),
            'attendancePolicies': Map<String, String>.from(
              data['attendancePolicies'] ?? {},
            ),
            'attendanceStatus': attendanceStatus, // ★★★ 新しい構造を使用 ★★★
            'absenceCount': Map<String, int>.from(data['absenceCount'] ?? {}),
            'lateCount': Map<String, int>.from(data['lateCount'] ?? {}),
            'teacherNames': Map<String, String>.from(
              data['teacherNames'] ?? {},
            ),
            'questSelectedClass': data['questSelectedClass'],
            'questTaskType': data['questTaskType'],
            'questDeadline': data['questDeadline'],
            'questDescription': data['questDescription'] ?? '',
          };
          print('TimetableProvider - State updated successfully');
        } else {
          print('TimetableProvider - No document found, using default state');
        }
      } else {
        print('TimetableProvider - No user found');
      }
    } catch (e) {
      print('Error loading timetable data: $e');
    }
  }

  // Firestoreにデータを保存
  Future<void> _saveToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('timetable')
            .doc('notes')
            .set({
              'cellNotes': state['cellNotes'],
              'weeklyNotes': state['weeklyNotes'],
              'attendancePolicies': state['attendancePolicies'],
              'attendanceStatus': state['attendanceStatus'],
              'absenceCount': state['absenceCount'],
              'lateCount': state['lateCount'],
              'teacherNames': state['teacherNames'],
              'questSelectedClass': state['questSelectedClass'],
              'questTaskType': state['questTaskType'],
              'questDeadline': state['questDeadline'],
              'questDescription': state['questDescription'],
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving timetable data: $e');
    }
  }

  // ★★★ 新しいメソッド：特定の授業の特定の日付の出席状態を設定 ★★★
  void setAttendanceStatus(String courseId, String date, String status) {
    final attendanceStatus = Map<String, Map<String, String>>.from(
      state['attendanceStatus'],
    );

    if (!attendanceStatus.containsKey(courseId)) {
      attendanceStatus[courseId] = {};
    }

    if (status.isEmpty) {
      attendanceStatus[courseId]!.remove(date);
      if (attendanceStatus[courseId]!.isEmpty) {
        attendanceStatus.remove(courseId);
      }
    } else {
      attendanceStatus[courseId]![date] = status;
    }

    updateAttendanceStatus(attendanceStatus);
  }

  // ★★★ 新しいメソッド：特定の授業の特定の日付の出席状態を取得 ★★★
  String? getAttendanceStatus(String courseId, String date) {
    final attendanceStatus =
        state['attendanceStatus'] as Map<String, Map<String, String>>;
    return attendanceStatus[courseId]?[date];
  }

  // 特定のcourseIdの教員名を取得
  String? getTeacherName(String courseId) {
    final teacherNames = state['teacherNames'] as Map<String, String>?;
    return teacherNames?[courseId];
  }

  // 特定のcourseIdの教員名を設定
  void setTeacherName(String courseId, String teacherName) {
    final currentData = Map<String, dynamic>.from(state);
    final teacherNames = Map<String, String>.from(
      currentData['teacherNames'] ?? {},
    );
    teacherNames[courseId] = teacherName;
    currentData['teacherNames'] = teacherNames;
    state = currentData;
    _saveToFirestore();
  }

  // 教員名が設定されている講義の一覧を取得
  List<Map<String, String>> getLecturesWithTeachers() {
    final teacherNames = state['teacherNames'] as Map<String, String>? ?? {};

    final lectures = <Map<String, String>>[];
    teacherNames.forEach((courseId, teacherName) {
      if (teacherName.isNotEmpty) {
        lectures.add({'name': courseId, 'teacher': teacherName});
      }
    });

    return lectures;
  }
}

// Providerの定義
final timetableProvider =
    StateNotifierProvider<TimetableNotifier, Map<String, dynamic>>((ref) {
      return TimetableNotifier();
    });
