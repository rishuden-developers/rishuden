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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rishuden/providers/global_course_mapping_provider.dart';
import 'package:rishuden/providers/global_review_mapping_provider.dart';

// 検索結果の各講義を表すデータモデル
class LectureSearchResult {
  final String lectureName;
  final String teacherName;
  final String? reviewId;
  double avgSatisfaction;
  double avgEasiness;
  int reviewCount;

  LectureSearchResult({
    required this.lectureName,
    required this.teacherName,
    this.reviewId,
    this.avgSatisfaction = 0.0,
    this.avgEasiness = 0.0,
    this.reviewCount = 0,
  });
}

class CreditResultPage extends ConsumerStatefulWidget {
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
  ConsumerState<CreditResultPage> createState() => _CreditResultPageState();
}

class _CreditResultPageState extends ConsumerState<CreditResultPage> {
  StreamSubscription? _reviewsSubscription;

  @override
  void initState() {
    super.initState();
    // _performSearch() is no longer needed here.
  }

  @override
  void dispose() {
    _reviewsSubscription?.cancel();
    super.dispose();
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
    // Providersからマスターデータを読み込む
    final allCourses = ref.watch(globalCourseMappingProvider);
    // teacherNamesはリビルドのたびに読み込む必要があるかもしれない
    // final teacherNames = ref.watch(timetableProvider.select((t) => t['teacherNames']));

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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                allCourses.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'エラーが発生しました',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            // 1. 全ての講義をベースにリストを作成
            Map<String, LectureSearchResult> resultsMap = {};
            final reviewMapping = ref.watch(globalReviewMappingProvider);

            allCourses.forEach((lectureName, courseId) {
              // まずはレビューがない状態として全講義を追加
              final tempTeacherName = '教員未設定';
              final key = '${lectureName}_$tempTeacherName';
              resultsMap[key] = LectureSearchResult(
                lectureName: lectureName,
                teacherName: tempTeacherName,
                // reviewIdはここでは設定しない (null)
              );
            });

            // 2. レビューのある講義情報を上書き
            reviewMapping.forEach((key, reviewId) {
              final parts = key.split('_');
              final lectureName = parts.first;
              final teacherName = parts.length > 1 ? parts.last : '教員未設定';

              resultsMap[key] = LectureSearchResult(
                lectureName: lectureName,
                teacherName: teacherName,
                reviewId: reviewId,
              );
            });

            // 3. 評価を計算
            final reviewsByReviewId = <String, List<DocumentSnapshot>>{};
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final reviewId = data['reviewId'] as String?;
                if (reviewId != null) {
                  reviewsByReviewId.putIfAbsent(reviewId, () => []).add(doc);
                }
              }
            }

            List<LectureSearchResult> allResults = resultsMap.values.toList();
            for (var result in allResults) {
              if (result.reviewId == null) continue; // レビューがなければスキップ
              final reviews = reviewsByReviewId[result.reviewId!] ?? [];
              if (reviews.isNotEmpty) {
                result.reviewCount = reviews.length;
                result.avgSatisfaction =
                    reviews
                        .map(
                          (r) =>
                              ((r.data()
                                          as Map<
                                            String,
                                            dynamic
                                          >)['overallSatisfaction']
                                      as num)
                                  .toDouble(),
                        )
                        .reduce((a, b) => a + b) /
                    reviews.length;
                final easinessReviews =
                    reviews
                        .where(
                          (r) =>
                              (r.data() as Map<String, dynamic>)['easiness'] !=
                              null,
                        )
                        .toList();
                if (easinessReviews.isNotEmpty) {
                  result.avgEasiness =
                      easinessReviews
                          .map(
                            (r) =>
                                ((r.data() as Map<String, dynamic>)['easiness']
                                        as num)
                                    .toDouble(),
                          )
                          .reduce((a, b) => a + b) /
                      easinessReviews.length;
                }
              }
            }

            // 4. 検索クエリでフィルタリング
            if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
              allResults =
                  allResults.where((r) {
                    return r.lectureName.toLowerCase().contains(
                          widget.searchQuery!.toLowerCase(),
                        ) ||
                        r.teacherName.toLowerCase().contains(
                          widget.searchQuery!.toLowerCase(),
                        );
                  }).toList();
            }

            if (allResults.isEmpty) {
              return const Center(
                child: Text(
                  '該当する講義が見つかりませんでした。',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: allResults.length,
              itemBuilder: (context, index) {
                final result = allResults[index];
                return _buildResultCard(result);
              },
            );
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
