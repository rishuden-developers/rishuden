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
        'questSelectedClass': null,
        'questTaskType': null,
        'questDeadline': null,
        'questDescription': '',
      });

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
  void updateAttendanceStatus(Map<String, String> status) {
    state = {...state, 'attendanceStatus': status};
    _saveToFirestore();
  }

  // 欠席回数を更新
  void updateAbsenceCount(Map<String, int> absenceCount) {
    state = {...state, 'absenceCount': absenceCount};
    _saveToFirestore();
  }

  // 遅刻回数を更新
  void updateLateCount(Map<String, int> lateCount) {
    state = {...state, 'lateCount': lateCount};
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
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('timetable')
                .doc('notes')
                .get();

        if (doc.exists) {
          final data = doc.data()!;
          print('TimetableProvider - Firestore data: $data');
          state = {
            'cellNotes': Map<String, String>.from(data['cellNotes'] ?? {}),
            'weeklyNotes': Map<String, String>.from(data['weeklyNotes'] ?? {}),
            'attendancePolicies': Map<String, String>.from(
              data['attendancePolicies'] ?? {},
            ),
            'attendanceStatus': Map<String, String>.from(
              data['attendanceStatus'] ?? {},
            ),
            'absenceCount': Map<String, int>.from(data['absenceCount'] ?? {}),
            'lateCount': Map<String, int>.from(data['lateCount'] ?? {}),
            'questSelectedClass': data['questSelectedClass'],
            'questTaskType': data['questTaskType'],
            'questDeadline': data['questDeadline'],
            'questDescription': data['questDescription'] ?? '',
          };
          print('TimetableProvider - State updated: $state');
        } else {
          print('TimetableProvider - No document found');
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
}

// Providerの定義
final timetableProvider =
    StateNotifierProvider<TimetableNotifier, Map<String, dynamic>>((ref) {
      return TimetableNotifier();
    });
