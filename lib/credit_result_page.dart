// credit_result_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'credit_review_page.dart'; // レビュー詳細ページへの遷移用
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'credit_explore_page.dart'; // ボトムナビゲーション用
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ★レート表示に利用するパッケージをインポート

// 検索結果の各講義を表すデータモデル
class LectureSearchResult {
  final String lectureName;
  final String teacherName;
  final String reviewId;
  double avgSatisfaction;
  double avgEasiness;
  int reviewCount;

  LectureSearchResult({
    required this.lectureName,
    required this.teacherName,
    required this.reviewId,
    this.avgSatisfaction = 0.0,
    this.avgEasiness = 0.0,
    this.reviewCount = 0,
  });
}

class CreditResultPage extends StatefulWidget {
  final String? searchQuery; // 検索クエリがあれば受け取る
  final String? filterFaculty; // 学部フィルター
  final String? filterTag; // タグフィルター
  final String? filterCategory; // 種類フィルター (必修/選択)
  final String? filterDayOfWeek; // 曜日フィルター
  final String?
  rankingType; // ランキングの種類 ('easiness', 'satisfaction', 'faculty_specific')

  const CreditResultPage({
    super.key,
    this.searchQuery,
    this.filterFaculty,
    this.filterTag,
    this.filterCategory,
    this.filterDayOfWeek,
    this.rankingType,
  });

  @override
  State<CreditResultPage> createState() => _CreditResultPageState();
}

class _CreditResultPageState extends State<CreditResultPage> {
  List<LectureSearchResult> _results = [];
  bool _isLoading = true;
  StreamSubscription? _reviewsSubscription;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _reviewsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    // ★★★ Firestoreから講義情報を取得する（実際のクエリは要件に合わせて調整） ★★★
    // ここでは、ダミーとして全てのレビューを持つ講義を取得します
    final reviewMappingSnapshot =
        await FirebaseFirestore.instance
            .collection('global')
            .doc('review_mapping')
            .get();

    if (!reviewMappingSnapshot.exists) {
      setState(() => _isLoading = false);
      return;
    }

    final mapping = Map<String, String>.from(
      reviewMappingSnapshot.data()!['mapping'],
    );
    List<LectureSearchResult> initialResults = [];

    mapping.forEach((key, reviewId) {
      final parts = key.split('_');
      final lectureName = parts.first;
      final teacherName = parts.length > 1 ? parts.last : '教員未設定';
      initialResults.add(
        LectureSearchResult(
          lectureName: lectureName,
          teacherName: teacherName,
          reviewId: reviewId,
        ),
      );
    });

    // ★★★ 検索条件で絞り込む（実際のロジック） ★★★
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      initialResults =
          initialResults
              .where((r) => r.lectureName.contains(widget.searchQuery!))
              .toList();
    }

    setState(() {
      _results = initialResults;
    });

    _subscribeToReviews();
  }

  void _subscribeToReviews() {
    // 全てのレビューを監視（効率は悪いがデモとして）
    _reviewsSubscription = FirebaseFirestore.instance
        .collection('reviews')
        .snapshots()
        .listen((snapshot) {
          // レビューIDごとに集計
          final Map<String, List<Map<String, dynamic>>> reviewsByReviewId = {};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final reviewId = data['reviewId'] as String?;
            if (reviewId != null) {
              reviewsByReviewId.putIfAbsent(reviewId, () => []).add(data);
            }
          }

          // 各講義の評価を再計算
          final updatedResults = List<LectureSearchResult>.from(_results);
          for (var result in updatedResults) {
            final reviews = reviewsByReviewId[result.reviewId] ?? [];
            if (reviews.isNotEmpty) {
              result.reviewCount = reviews.length;
              result.avgSatisfaction =
                  reviews
                      .map((r) => (r['overallSatisfaction'] as num).toDouble())
                      .reduce((a, b) => a + b) /
                  reviews.length;
              // TODO: `easiness`も同様に計算
              // result.avgEasiness = ...
            } else {
              result.reviewCount = 0;
              result.avgSatisfaction = 0.0;
              result.avgEasiness = 0.0;
            }
          }

          if (mounted) {
            setState(() {
              _results = updatedResults;
              _isLoading = false; // ★ データの更新が終わったらローディングを解除
            });
          }
        });
  }

  String _getPageTitle() {
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      return '検索結果: "${widget.searchQuery}"';
    } else if (widget.rankingType == 'easiness') {
      return '楽単ランキング';
    } else if (widget.rankingType == 'satisfaction') {
      return '総合満足度ランキング';
    } else if (widget.rankingType == 'faculty_specific') {
      return '${widget.filterFaculty ?? '全学部'} 注目授業';
    } else if (widget.filterFaculty != null &&
        widget.filterFaculty!.isNotEmpty) {
      return '${widget.filterFaculty} の講義';
    }
    return '講義一覧';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansJP',
          ),
        ),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo[800]!, Colors.indigo[600]!],
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : _results.isEmpty
                ? const Center(
                  child: Text(
                    '該当する講義が見つかりませんでした。',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return _buildResultCard(result);
                  },
                ),
      ),
    );
  }

  Widget _buildResultCard(LectureSearchResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreditReviewPage(
                    lectureName: result.lectureName,
                    teacherName: result.teacherName,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.lectureName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansJP',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.teacherName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontFamily: 'NotoSansJP',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  RatingBarIndicator(
                    rating: result.avgSatisfaction,
                    itemBuilder:
                        (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 20.0,
                    direction: Axis.horizontal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result.avgSatisfaction.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // TODO: 楽単度も表示
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'レビュー数: ${result.reviewCount}件',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
