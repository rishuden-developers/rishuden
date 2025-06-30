import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// グローバルな教員名+授業名 → reviewId のマッピングを管理するProvider
class GlobalReviewMappingNotifier extends StateNotifier<Map<String, String>> {
  GlobalReviewMappingNotifier() : super({}) {
    // 初期化時にFirebaseからデータを読み込み
    _initializeFromFirebase();
  }

  // ★★★ 初期化時にFirebaseからデータを読み込む ★★★
  Future<void> _initializeFromFirebase() async {
    try {
      await loadFromFirestore();
    } catch (e) {
      print('Error initializing global review mapping from Firebase: $e');
    }
  }

  // グローバルレビューマッピングを更新
  void updateGlobalMapping(Map<String, String> mapping) {
    state = mapping;
    _saveToFirestore();
  }

  // 特定の教員名+授業名のreviewIdを取得（存在しない場合はnull）
  String? getReviewId(String subjectName, String teacherName) {
    final key = _createKey(subjectName, teacherName);
    return state[key];
  }

  // 新しい教員名+授業名とreviewIdを追加
  void addReviewMapping(
    String subjectName,
    String teacherName,
    String reviewId,
  ) {
    final key = _createKey(subjectName, teacherName);
    final newMapping = Map<String, String>.from(state);
    newMapping[key] = reviewId;
    updateGlobalMapping(newMapping);
  }

  // 教員名+授業名からreviewIdを取得または生成
  String getOrCreateReviewId(String subjectName, String teacherName) {
    final existingReviewId = getReviewId(subjectName, teacherName);
    if (existingReviewId != null) {
      print(
        'DEBUG: 既存のレビュー "$subjectName($teacherName)" -> reviewId: $existingReviewId',
      );
      return existingReviewId;
    }

    // 新しいreviewIdを生成
    final newReviewId = 'review_${DateTime.now().millisecondsSinceEpoch}';
    addReviewMapping(subjectName, teacherName, newReviewId);
    print(
      'DEBUG: 新しいレビュー "$subjectName($teacherName)" -> reviewId: $newReviewId',
    );

    return newReviewId;
  }

  // キー生成用のヘルパーメソッド
  String _createKey(String subjectName, String teacherName) {
    return '${subjectName}_$teacherName';
  }

  // Firestoreからデータを読み込み
  Future<void> loadFromFirestore() async {
    try {
      print('GlobalReviewMappingProvider - Starting loadFromFirestore');
      final doc =
          await FirebaseFirestore.instance
              .collection('global')
              .doc('review_mapping')
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        final mapping = Map<String, String>.from(data['mapping'] ?? {});
        state = mapping;
        print(
          'GlobalReviewMappingProvider - Loaded ${mapping.length} review mappings',
        );
      } else {
        print(
          'GlobalReviewMappingProvider - No mapping document found, using empty state',
        );
      }
    } catch (e) {
      print('Error loading global review mapping: $e');
    }
  }

  // Firestoreにデータを保存
  Future<void> _saveToFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('global')
          .doc('review_mapping')
          .set({
            'mapping': state,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      print(
        'GlobalReviewMappingProvider - Saved ${state.length} review mappings',
      );
    } catch (e) {
      print('Error saving global review mapping: $e');
    }
  }
}

// Providerの定義
final globalReviewMappingProvider =
    StateNotifierProvider<GlobalReviewMappingNotifier, Map<String, String>>((
      ref,
    ) {
      return GlobalReviewMappingNotifier();
    });
