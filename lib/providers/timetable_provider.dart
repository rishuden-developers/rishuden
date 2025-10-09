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
        'attendanceStatus': <String, Map<String, String>>{},
        'absenceCount': <String, int>{},
        'lateCount': <String, int>{},
        'teacherNames': <String, String>{},
        'courseIds': <String, String>{},
        'questSelectedClass': null,
        'questTaskType': null,
        'questDeadline': null,
        'questDescription': '',
        'isLoading': true, // ★★★ ローディング状態を追加 ★★★
      }) {
    // 初期化時にFirebaseからデータを読み込み
    _initializeFromFirebase();
  }

  // ★★★ 初期化時にFirebaseからデータを読み込む ★★★
  Future<void> _initializeFromFirebase() async {
    try {
      print('TimetableProvider - Initializing from Firebase...');
      await loadFromFirestore();
      print('TimetableProvider - Initialization completed');
    } catch (e) {
      print('Error initializing from Firebase: $e');
      // ★★★ エラー時もローディング状態を解除 ★★★
      state = {...state, 'isLoading': false};
    }
  }

  // セルメモを更新
  void updateCellNotes(Map<String, String> cellNotes) {
    print(
      'TimetableProvider - updateCellNotes called. Count: ${cellNotes.length}',
    );
    print('TimetableProvider - Cell notes content: $cellNotes');
    state = {...state, 'cellNotes': cellNotes};
    _saveToFirestore();
  }

  // 週次メモを更新
  void updateWeeklyNotes(Map<String, String> weeklyNotes) {
    print(
      'TimetableProvider - updateWeeklyNotes called. Count: ${weeklyNotes.length}',
    );
    print('TimetableProvider - Weekly notes content: $weeklyNotes');
    state = {...state, 'weeklyNotes': weeklyNotes};
    _saveToFirestore();
  }

  // 出席ポリシーを更新
  void updateAttendancePolicies(Map<String, String> policies) {
    state = {...state, 'attendancePolicies': policies};
    _saveToFirestore();
  }

  // 出席状態を更新
  void updateAttendanceStatus(Map<String, Map<String, String>> status) {
    state = {...state, 'attendanceStatus': status};
    _saveToFirestore();
  }

  // 欠席回数を更新
  void updateAbsenceCount(Map<String, int> count) {
    state = {...state, 'absenceCount': count};
    _saveToFirestore();
  }

  // 遅刻回数を更新
  void updateLateCount(Map<String, int> count) {
    state = {...state, 'lateCount': count};
    _saveToFirestore();
  }

  // 教員名を更新
  void updateTeacherNames(Map<String, String> teacherNames) {
    state = {...state, 'teacherNames': teacherNames};
    _saveToFirestore();
  }

  // 出席状態を設定
  void setAttendanceStatus(String courseId, String date, String status) {
    final attendanceStatus = Map<String, Map<String, String>>.from(
      state['attendanceStatus'] ?? {},
    );
    if (!attendanceStatus.containsKey(courseId)) {
      attendanceStatus[courseId] = {};
    }
    if (status.isEmpty) {
      attendanceStatus[courseId]!.remove(date);
    } else {
      attendanceStatus[courseId]![date] = status;
    }
    updateAttendanceStatus(attendanceStatus);
  }

  // 欠席回数を設定
  void setAbsenceCount(String courseId, int count) {
    final absenceCount = Map<String, int>.from(state['absenceCount'] ?? {});
    if (count <= 0) {
      absenceCount.remove(courseId);
    } else {
      absenceCount[courseId] = count;
    }
    updateAbsenceCount(absenceCount);
  }

  // 遅刻回数を設定
  void setLateCount(String courseId, int count) {
    final lateCount = Map<String, int>.from(state['lateCount'] ?? {});
    if (count <= 0) {
      lateCount.remove(courseId);
    } else {
      lateCount[courseId] = count;
    }
    updateLateCount(lateCount);
  }

  // クエストデータをリセット
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
          print('TimetableProvider - Loaded cellNotes: ${data['cellNotes']}');
          print(
            'TimetableProvider - Loaded weeklyNotes: ${data['weeklyNotes']}',
          );

          // ★★★ 型チェックを強化 ★★★
          final cellNotesRaw = data['cellNotes'];
          final weeklyNotesRaw = data['weeklyNotes'];

          Map<String, String> cellNotes;
          Map<String, String> weeklyNotes;

          if (cellNotesRaw is Map) {
            try {
              cellNotes = Map<String, String>.from(cellNotesRaw);
              print(
                'TimetableProvider - Cell notes converted successfully: ${cellNotes.length} items',
              );
            } catch (e) {
              print('TimetableProvider - Error converting cellNotes: $e');
              cellNotes = <String, String>{};
            }
          } else {
            print(
              'TimetableProvider - cellNotes is not a Map, type: ${cellNotesRaw.runtimeType}',
            );
            cellNotes = <String, String>{};
          }

          if (weeklyNotesRaw is Map) {
            try {
              weeklyNotes = Map<String, String>.from(weeklyNotesRaw);
              print(
                'TimetableProvider - Weekly notes converted successfully: ${weeklyNotes.length} items',
              );
            } catch (e) {
              print('TimetableProvider - Error converting weeklyNotes: $e');
              weeklyNotes = <String, String>{};
            }
          } else {
            print(
              'TimetableProvider - weeklyNotes is not a Map, type: ${weeklyNotesRaw.runtimeType}',
            );
            weeklyNotes = <String, String>{};
          }

          state = {
            'cellNotes': cellNotes,
            'weeklyNotes': weeklyNotes,
            'attendancePolicies': Map<String, String>.from(
              data['attendancePolicies'] ?? {},
            ),
            'attendanceStatus': _convertAttendanceStatus(
              data['attendanceStatus'],
            ),
            'absenceCount': Map<String, int>.from(data['absenceCount'] ?? {}),
            'lateCount': Map<String, int>.from(data['lateCount'] ?? {}),
            'teacherNames': Map<String, String>.from(
              data['teacherNames'] ?? {},
            ),
            'courseIds': Map<String, String>.from(data['courseIds'] ?? {}),
            'questSelectedClass': data['questSelectedClass'],
            'questTaskType': data['questTaskType'],
            'questDeadline': data['questDeadline'],
            'questDescription': data['questDescription'] ?? '',
            'isLoading': false, // ★★★ ローディング完了 ★★★
          };
          print('TimetableProvider - State updated successfully');
          print(
            'TimetableProvider - Final cellNotes count: ${cellNotes.length}',
          );
          print(
            'TimetableProvider - Final weeklyNotes count: ${weeklyNotes.length}',
          );
        } else {
          print('TimetableProvider - No document found, using default state');
          state = {...state, 'isLoading': false};
        }
      } else {
        print('TimetableProvider - No user found');
        state = {...state, 'isLoading': false};
      }
    } catch (e) {
      print('Error loading timetable data: $e');
      state = {...state, 'isLoading': false};
    }
  }

  // 出席状態のデータ構造を変換
  Map<String, Map<String, String>> _convertAttendanceStatus(
    dynamic oldAttendanceStatus,
  ) {
    if (oldAttendanceStatus is Map) {
      final converted = <String, Map<String, String>>{};
      oldAttendanceStatus.forEach((key, value) {
        if (value is Map) {
          converted[key.toString()] = Map<String, String>.from(value);
        }
      });
      return converted;
    }
    return <String, Map<String, String>>{};
  }

  // Firestoreにデータを保存
  Future<void> _saveToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('TimetableProvider - Saving data to Firestore...');
        final cellNotes =
            state['cellNotes'] is Map<String, String>
                ? state['cellNotes'] as Map<String, String>
                : <String, String>{};
        final weeklyNotes =
            state['weeklyNotes'] is Map<String, String>
                ? state['weeklyNotes'] as Map<String, String>
                : <String, String>{};
        print('TimetableProvider - Cell notes count: ${cellNotes.length}');
        print('TimetableProvider - Weekly notes count: ${weeklyNotes.length}');
        print('TimetableProvider - Cell notes to save: $cellNotes');
        print('TimetableProvider - Weekly notes to save: $weeklyNotes');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('timetable')
            .doc('notes')
            .set({
              'cellNotes': cellNotes,
              'weeklyNotes': weeklyNotes,
              'attendancePolicies': state['attendancePolicies'],
              'attendanceStatus': state['attendanceStatus'],
              'absenceCount': state['absenceCount'],
              'lateCount': state['lateCount'],
              'teacherNames': state['teacherNames'],
              'courseIds': state['courseIds'],
              'questSelectedClass': state['questSelectedClass'],
              'questTaskType': state['questTaskType'],
              'questDeadline': state['questDeadline'],
              'questDescription': state['questDescription'],
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        print('TimetableProvider - Data saved successfully');
      } else {
        print('TimetableProvider - No user found, skipping save');
      }
    } catch (e) {
      print('Error saving timetable data: $e');
      // ★★★ 保存エラー時はUIに通知する仕組みを追加 ★★★
      state = {...state, 'saveError': e.toString()};
    }
  }

  // 教員名を設定
  void setTeacherName(String courseId, String teacherName) {
    final teacherNames = Map<String, String>.from(state['teacherNames']);
    if (teacherName.isEmpty) {
      teacherNames.remove(courseId);
    } else {
      teacherNames[courseId] = teacherName;
    }
    updateTeacherNames(teacherNames);
  }

  // 教員名を取得
  String getTeacherName(String courseId) {
    final teacherNames = state['teacherNames'] as Map<String, String>? ?? {};
    return teacherNames[courseId] ?? '';
  }

  // 教員名のリストを取得
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

  // ★★★ courseIdを更新するメソッドを追加 ★★★
  void updateCourseIds(Map<String, String> courseIds) {
    state = {...state, 'courseIds': courseIds};
    _saveToFirestore();
  }

  // ★★★ 特定のセルのcourseIdを設定するメソッドを追加 ★★★
  void setCourseId(String cellKey, String courseId) {
    final courseIds = Map<String, String>.from(state['courseIds']);
    if (courseId.isEmpty) {
      courseIds.remove(cellKey);
    } else {
      courseIds[cellKey] = courseId;
    }
    updateCourseIds(courseIds);
  }

  // ★★★ 特定のセルのcourseIdを取得するメソッドを追加 ★★★
  String? getCourseId(String cellKey) {
    final courseIds = state['courseIds'] as Map<String, String>?;
    return courseIds?[cellKey];
  }

  // ★★★ クエスト作成用: 選択中の授業を設定 ★★★
  void setQuestSelectedClass(Map<String, dynamic>? classData) {
    state = {...state, 'questSelectedClass': classData};
    _saveToFirestore();
  }

  // ★★★ クエスト作成用: 入力中のタスク種別/締切/説明を設定 ★★★
  void setQuestData({
    String? taskType,
    DateTime? deadline,
    String? description,
  }) {
    state = {
      ...state,
      if (taskType != null) 'questTaskType': taskType,
      if (deadline != null) 'questDeadline': deadline.toIso8601String(),
      if (description != null) 'questDescription': description,
    };
    _saveToFirestore();
  }

  // ★★★ ローディング状態を取得 ★★★
  bool get isLoading => state['isLoading'] ?? false;

  // ★★★ 保存エラーを取得 ★★★
  String? get saveError => state['saveError'];

  // ★★★ 保存エラーをクリア ★★★
  void clearSaveError() {
    state = {...state, 'saveError': null};
  }
}

// Providerの定義
final timetableProvider =
    StateNotifierProvider<TimetableNotifier, Map<String, dynamic>>((ref) {
      return TimetableNotifier();
    });
