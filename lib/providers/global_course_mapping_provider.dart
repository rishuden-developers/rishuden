import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// グローバルな授業名・教室・曜日・時限 → courseId のマッピングを管理するProvider
class GlobalCourseMappingNotifier extends StateNotifier<Map<String, String>> {
  int _idCounter = 0; // ★★★ 一意なIDを生成するためのカウンター ★★★

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

  // 授業名・教室・曜日・時限の組み合わせからcourseIdを取得（存在しない場合はnull）
  String? getCourseId(
    String subjectName,
    String classroom,
    int dayOfWeek,
    int period,
  ) {
    String key = _generateKey(subjectName, classroom, dayOfWeek, period);
    return state[key];
  }

  // 新しい授業名・教室・曜日・時限とcourseIdを追加
  void addCourseMapping(
    String subjectName,
    String classroom,
    int dayOfWeek,
    int period,
    String courseId,
  ) {
    String key = _generateKey(subjectName, classroom, dayOfWeek, period);
    final newMapping = Map<String, String>.from(state);
    newMapping[key] = courseId;
    updateGlobalMapping(newMapping);
  }

  // 授業名・教室・曜日・時限の組み合わせからキーを生成
  String _generateKey(
    String subjectName,
    String classroom,
    int dayOfWeek,
    int period,
  ) {
    return '$subjectName|$classroom|$dayOfWeek|$period';
  }

  // 授業名を正規化するメソッド（後方互換性のため残す）
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

  // 授業名・教室・曜日・時限からcourseIdを取得または生成
  String getOrCreateCourseId(
    String subjectName,
    String classroom,
    int dayOfWeek,
    int period,
  ) {
    // 既存のcourseIdを確認
    final existingCourseId = getCourseId(
      subjectName,
      classroom,
      dayOfWeek,
      period,
    );
    if (existingCourseId != null) {
      print(
        'DEBUG: 既存の授業 "$subjectName" ($classroom, 曜日:$dayOfWeek, 時限:$period) -> courseId: $existingCourseId',
      );
      return existingCourseId;
    }

    // ★★★ 新しいcourseIdを生成（授業名|教室|曜日|時限の形式） ★★★
    final newCourseId = '$subjectName|$classroom|$dayOfWeek|$period';

    // 新しいマッピングを追加
    addCourseMapping(subjectName, classroom, dayOfWeek, period, newCourseId);
    print(
      'DEBUG: 新しい授業 "$subjectName" ($classroom, 曜日:$dayOfWeek, 時限:$period) -> courseId: $newCourseId',
    );

    return newCourseId;
  }

  // 後方互換性のためのメソッド（授業名のみでcourseIdを取得）
  String? getCourseIdBySubjectName(String normalizedSubjectName) {
    // 古い形式のキーで検索
    return state[normalizedSubjectName];
  }

  // 後方互換性のためのメソッド（授業名のみでcourseIdを取得または生成）
  String getOrCreateCourseIdBySubjectName(String subjectName) {
    final normalizedName = normalizeSubjectName(subjectName);

    // 既存のcourseIdを確認
    final existingCourseId = getCourseIdBySubjectName(normalizedName);
    if (existingCourseId != null) {
      print('DEBUG: 既存の授業 "$subjectName" -> courseId: $existingCourseId');
      return existingCourseId;
    }

    // ★★★ 新しいcourseIdを生成（タイムスタンプ + カウンター） ★★★
    final newCourseId =
        'course_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

    // 新しいマッピングを追加
    final newMapping = Map<String, String>.from(state);
    newMapping[normalizedName] = newCourseId;
    updateGlobalMapping(newMapping);
    print('DEBUG: 新しい授業 "$subjectName" -> courseId: $newCourseId');

    return newCourseId;
  }

  // 後方互換性のためのメソッド（授業名のみでcourseIdを追加）
  void addCourseMappingBySubjectName(
    String normalizedSubjectName,
    String courseId,
  ) {
    final newMapping = Map<String, String>.from(state);
    newMapping[normalizedSubjectName] = courseId;
    updateGlobalMapping(newMapping);
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
