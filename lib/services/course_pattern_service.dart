import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../course_pattern.dart';

/// 科目パターンをFirebaseで管理するためのサービスクラス
class CoursePatternService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ユーザーの科目パターンを保存
  Future<void> saveCoursePattern(CoursePattern pattern) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('coursePatterns')
        .doc(pattern.courseId)
        .set(pattern.toJson());
  }

  /// ユーザーの全科目パターンを取得
  Future<List<CoursePattern>> getCoursePatterns() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('coursePatterns')
            .get();

    return snapshot.docs
        .map((doc) => CoursePattern.fromJson(doc.data()))
        .toList();
  }

  /// 科目パターンを削除
  Future<void> deleteCoursePattern(String courseId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('coursePatterns')
        .doc(courseId)
        .delete();
  }

  /// 科目パターンを更新
  Future<void> updateCoursePattern(CoursePattern pattern) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('coursePatterns')
        .doc(pattern.courseId)
        .update(pattern.toJson());
  }

  /// 科目パターンを取得
  Future<CoursePattern?> getCoursePattern(String courseId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final doc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('coursePatterns')
            .doc(courseId)
            .get();

    if (!doc.exists) {
      return null;
    }

    return CoursePattern.fromJson(doc.data()!);
  }

  /// 科目パターンの不規則な日程を追加
  Future<void> addIrregularSchedule(
    String courseId,
    String date,
    int dayOfWeek,
    int period,
  ) async {
    final pattern = await getCoursePattern(courseId);
    if (pattern == null) {
      throw Exception('科目パターンが見つかりません');
    }

    pattern.irregularSchedules[date] = (dayOfWeek: dayOfWeek, period: period);
    await updateCoursePattern(pattern);
  }

  /// 科目パターンの休講日を追加
  Future<void> addCancelledDate(String courseId, String date) async {
    final pattern = await getCoursePattern(courseId);
    if (pattern == null) {
      throw Exception('科目パターンが見つかりません');
    }

    if (!pattern.cancelledDates.contains(date)) {
      pattern.cancelledDates.add(date);
      await updateCoursePattern(pattern);
    }
  }
}
