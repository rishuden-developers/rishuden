import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// グローバルな授業名 → courseId のマッピングを管理するProvider
class GlobalCourseMappingNotifier extends StateNotifier<Map<String, String>> {
  GlobalCourseMappingNotifier() : super({}) {
    // 初期化時にFirebaseからデータを読み込み
    _initializeFromFirebase();
  }

  // ★★★ 初期化時にFirebaseからデータを読み込む ★★★
  Future<void> _initializeFromFirebase() async {
    try {
      await loadFromFirestore();
    } catch (e) {
      print('Error initializing global course mapping from Firebase: $e');
    }
  }

  // グローバルマッピングを更新
  void updateGlobalMapping(Map<String, String> mapping) {
    state = mapping;
    _saveToFirestore();
  }

  // 特定の授業名のcourseIdを取得（存在しない場合はnull）
  String? getCourseId(String normalizedSubjectName) {
    return state[normalizedSubjectName];
  }

  // 新しい授業名とcourseIdを追加
  void addCourseMapping(String normalizedSubjectName, String courseId) {
    final newMapping = Map<String, String>.from(state);
    newMapping[normalizedSubjectName] = courseId;
    updateGlobalMapping(newMapping);
  }

  // 授業名を正規化するメソッド
  String normalizeSubjectName(String subjectName) {
    return subjectName
        .replaceAll(RegExp(r'[（）()【】\[\]]'), '') // 括弧類を削除
        .replaceAllMapped(
          RegExp(r'[Ａ-Ｚａ-ｚ０-９]'),
          (Match m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0xFEE0),
        ) // 全角英数字を半角に
        .replaceAll(RegExp(r'\s+'), '') // 全ての空白文字を削除
        .replaceAll('　', '')
        .replaceAll('・', '')
        .replaceAll('Ⅰ', 'I')
        .replaceAll('Ⅱ', 'II')
        .replaceAll('Ⅲ', 'III')
        .replaceAll('Ⅳ', 'IV')
        .replaceAll('Ⅴ', 'V')
        .replaceAll('Ⅵ', 'VI')
        .replaceAll('Ⅶ', 'VII')
        .replaceAll('Ⅷ', 'VIII')
        .replaceAll('Ⅸ', 'IX')
        .replaceAll('Ⅹ', 'X')
        .toLowerCase() // 全て小文字に
        .trim();
  }

  // 授業名からcourseIdを取得または生成
  String getOrCreateCourseId(String subjectName) {
    final normalizedName = normalizeSubjectName(subjectName);

    // 既存のcourseIdを確認
    final existingCourseId = getCourseId(normalizedName);
    if (existingCourseId != null) {
      print('DEBUG: 既存の授業 "$subjectName" -> courseId: $existingCourseId');
      return existingCourseId;
    }

    // 新しいcourseIdを生成
    final newCourseId = 'course_${DateTime.now().millisecondsSinceEpoch}';
    addCourseMapping(normalizedName, newCourseId);
    print('DEBUG: 新しい授業 "$subjectName" -> courseId: $newCourseId');

    return newCourseId;
  }

  // Firestoreからデータを読み込み
  Future<void> loadFromFirestore() async {
    try {
      print('GlobalCourseMappingProvider - Starting loadFromFirestore');
      final doc =
          await FirebaseFirestore.instance
              .collection('global')
              .doc('course_mapping')
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        final mapping = Map<String, String>.from(data['mapping'] ?? {});
        state = mapping;
        print(
          'GlobalCourseMappingProvider - Loaded ${mapping.length} course mappings',
        );
      } else {
        print(
          'GlobalCourseMappingProvider - No mapping document found, using empty state',
        );
      }
    } catch (e) {
      print('Error loading global course mapping: $e');
    }
  }

  // Firestoreにデータを保存
  Future<void> _saveToFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('global')
          .doc('course_mapping')
          .set({
            'mapping': state,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      print(
        'GlobalCourseMappingProvider - Saved ${state.length} course mappings',
      );
    } catch (e) {
      print('Error saving global course mapping: $e');
    }
  }
}

// Providerの定義
final globalCourseMappingProvider =
    StateNotifierProvider<GlobalCourseMappingNotifier, Map<String, String>>((
      ref,
    ) {
      return GlobalCourseMappingNotifier();
    });
