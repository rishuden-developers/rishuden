// credit_review_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ★レート表示に利用するパッケージをインポート
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'credit_input_page.dart'; // レビュー投稿画面への遷移用
import 'credit_explore_page.dart'; // ボトムナビゲーション用
import 'providers/global_review_mapping_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// ★★★★ 補足: flutter_rating_bar パッケージの追加 ★★★★
// pubspec.yaml ファイルの dependencies: の下に追加してください。
// dependencies:
//   flutter:
//     sdk: flutter
//   flutter_rating_bar: ^5.1.1 # 最新バージョンを確認してください
// ----------------------------------------------------

enum LectureFormat { faceToFace, onDemand, zoom, other }

enum AttendanceStrictness {
  flexible,
  everyTimeRollCall,
  attendancePoints,
  noAttendance,
}

enum ExamType { report, written, attendanceBased, none, other }

// Dummy Review Data Structure (for demonstration of filtering)
class LectureReview {
  final String lectureName;
  final String teacherName;
  final String userId;
  final double overallSatisfaction;
  final double easiness;
  final LectureFormat lectureFormat;
  final AttendanceStrictness attendanceStrictness;
  final ExamType examType;
  final String teacherFeature;
  final String comment;
  final List<String> tags;
  final String reviewId;
  final String reviewDate;

  LectureReview({
    required this.lectureName,
    required this.teacherName,
    required this.userId,
    required this.overallSatisfaction,
    required this.easiness,
    required this.lectureFormat,
    required this.attendanceStrictness,
    required this.examType,
    required this.teacherFeature,
    required this.comment,
    required this.tags,
    required this.reviewId,
    required this.reviewDate,
  });
}

class CreditReviewPage extends ConsumerStatefulWidget {
  final String lectureName;
  final String teacherName;
  final String? code; // ★ codeを追加（秋冬学期用）
  final String? initialDescription; // 講義の概要
  final double? initialOverallSatisfaction; // 講義全体の平均満足度
  final double? initialEasiness; // 講義全体の平均楽単度

  const CreditReviewPage({
    super.key,
    required this.lectureName,
    required this.teacherName,
    this.code, // ★ codeを追加
    this.initialDescription,
    this.initialOverallSatisfaction,
    this.initialEasiness,
  });

  @override
  ConsumerState<CreditReviewPage> createState() => _CreditReviewPageState();
}

class _CreditReviewPageState extends ConsumerState<CreditReviewPage> {
  // 実際のレビューデータ
  List<LectureReview> _allReviews = [];
  List<LectureReview> _filteredReviews = [];
  bool _isLoading = true;
  StreamSubscription? _reviewsSubscription; // ★ Streamを監視するためのSubscription

  // フィルター用
  LectureFormat? _selectedFormatFilter;
  AttendanceStrictness? _selectedAttendanceFilter;
  ExamType? _selectedExamFilter;

  @override
  void initState() {
    super.initState();
    // initStateではrefが使えないため、WidgetsBinding.instance.addPostFrameCallbackを使用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToReviews();
    });
  }

  @override
  void dispose() {
    _reviewsSubscription?.cancel(); // ★ ページが破棄されるときにStreamの監視をキャンセル
    super.dispose();
  }

  // Firebaseのレビュー変更を監視
  void _subscribeToReviews() async {
    setState(() => _isLoading = true);
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('code', isEqualTo: widget.code)
              .orderBy('createdAt', descending: true)
              .get();
      final parsedReviews =
          query.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LectureReview(
              lectureName: data['lectureName'] ?? '',
              teacherName: data['teacherName'] ?? '',
              userId: data['userId'] ?? '',
              overallSatisfaction: _parseToDouble(
                data['overallSatisfaction'] ?? data['satisfaction'],
              ),
              easiness: _parseToDouble(data['easiness'] ?? data['ease']),
              lectureFormat: LectureFormat.values.firstWhere(
                (e) =>
                    e.toString() == data['lectureFormat'] ||
                    e.toString() == data['classFormat'],
                orElse: () => LectureFormat.other,
              ),
              attendanceStrictness: AttendanceStrictness.values.firstWhere(
                (e) =>
                    e.toString() == data['attendanceStrictness'] ||
                    e.toString() == data['attendance'],
                orElse: () => AttendanceStrictness.flexible,
              ),
              examType: ExamType.values.firstWhere(
                (e) => e.toString() == data['examType'],
                orElse: () => ExamType.other,
              ),
              teacherFeature: data['teacherFeature'] ?? '',
              comment: data['comment'] ?? '',
              tags: List<String>.from(
                data['tags'] ?? data['teacherTraits'] ?? [],
              ),
              reviewId: data['reviewId'] ?? '',
              reviewDate:
                  data['createdAt'] != null
                      ? DateFormat(
                        'yyyy/MM/dd',
                      ).format((data['createdAt'] as Timestamp).toDate())
                      : '',
            );
          }).toList();
      setState(() {
        _allReviews = parsedReviews;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      print('Error loading reviews: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredReviews =
        _allReviews.where((review) {
          bool matches = true;
          if (_selectedFormatFilter != null) {
            matches = matches && review.lectureFormat == _selectedFormatFilter;
          }
          if (_selectedAttendanceFilter != null) {
            matches =
                matches &&
                review.attendanceStrictness == _selectedAttendanceFilter;
          }
          if (_selectedExamFilter != null) {
            matches = matches && review.examType == _selectedExamFilter;
          }
          return matches;
        }).toList();
  }

  double get _averageOverallSatisfaction {
    if (_allReviews.isEmpty) return 0.0;
    return _allReviews
            .map((r) => r.overallSatisfaction)
            .reduce((a, b) => a + b) /
        _allReviews.length;
  }

  double get _averageEasiness {
    if (_allReviews.isEmpty) return 0.0;
    return _allReviews.map((r) => r.easiness).reduce((a, b) => a + b) /
        _allReviews.length;
  }

  String _formatEnum(dynamic enumValue) {
    if (enumValue == null) return '未指定';
    return enumValue.toString().split('.').last;
  }

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final myReview =
        user == null
            ? null
            : (_allReviews.firstWhereOrNull((r) => r.userId == user.uid));
    final otherReviews =
        user == null
            ? _allReviews
            : _allReviews.where((r) => r.userId != user.uid).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '講義レビュー',
          style: TextStyle(
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
        child: SafeArea(
          child:
              _isLoading
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'レビューを読み込み中...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                      ],
                    ),
                  )
                  : LayoutBuilder(
                    builder:
                        (context, constraints) => SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildLectureInfoCard(),
                                const SizedBox(height: 20),
                                _buildOverallRatingsCard(),
                                if (myReview != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 20.0,
                                      bottom: 16.0,
                                    ),
                                    child: FutureBuilder<DocumentSnapshot>(
                                      future:
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(myReview.userId)
                                              .get(),
                                      builder: (context, userSnapshot) {
                                        String? characterImage;
                                        if (userSnapshot.hasData &&
                                            userSnapshot.data != null) {
                                          final data =
                                              userSnapshot.data!.data()
                                                  as Map<String, dynamic>?;
                                          characterImage =
                                              data?['characterImage']
                                                  as String?;
                                        }
                                        return Card(
                                          color: Colors.cyan[50],
                                          elevation: 6,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // キャラクター画像
                                                Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    color: Colors.grey[200],
                                                  ),
                                                  child:
                                                      characterImage != null
                                                          ? Image.asset(
                                                            characterImage,
                                                            fit: BoxFit.cover,
                                                          )
                                                          : Image.asset(
                                                            'assets/character_gorilla.png',
                                                            fit: BoxFit.cover,
                                                          ),
                                                ),
                                                const SizedBox(width: 16),
                                                // レビュー内容
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'あなたのレビュー',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors.cyan,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          RatingBarIndicator(
                                                            rating:
                                                                myReview
                                                                    .overallSatisfaction,
                                                            itemBuilder:
                                                                (
                                                                  context,
                                                                  index,
                                                                ) => const Icon(
                                                                  Icons.star,
                                                                  color:
                                                                      Colors
                                                                          .amber,
                                                                ),
                                                            itemCount: 5,
                                                            itemSize: 20.0,
                                                            direction:
                                                                Axis.horizontal,
                                                          ),
                                                          Text(
                                                            myReview.reviewDate,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '形式: ${_formatEnum(myReview.lectureFormat)}',
                                                        style: const TextStyle(
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      Text(
                                                        '出席: ${_formatEnum(myReview.attendanceStrictness)}',
                                                        style: const TextStyle(
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      Text(
                                                        '試験: ${_formatEnum(myReview.examType)}',
                                                        style: const TextStyle(
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      Text(
                                                        '教員特徴: ${myReview.teacherFeature}',
                                                        style: const TextStyle(
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'コメント: ${myReview.comment}',
                                                        style: const TextStyle(
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 6.0,
                                                        children:
                                                            myReview.tags
                                                                .map(
                                                                  (tag) => Chip(
                                                                    label: Text(
                                                                      tag,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color:
                                                                            Colors.cyan[100],
                                                                      ),
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .cyan[100],
                                                                  ),
                                                                )
                                                                .toList(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                _buildSectionTitle(
                                  'レビューを絞り込む',
                                  Icons.filter_list,
                                ),
                                const SizedBox(height: 10),
                                _buildFilterDropdown<LectureFormat>(
                                  '形式で絞り込む',
                                  _selectedFormatFilter,
                                  LectureFormat.values,
                                  (newValue) {
                                    setState(() {
                                      _selectedFormatFilter = newValue;
                                      _applyFilters();
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                _buildFilterDropdown<AttendanceStrictness>(
                                  '出席厳しさで絞り込む',
                                  _selectedAttendanceFilter,
                                  AttendanceStrictness.values,
                                  (newValue) {
                                    setState(() {
                                      _selectedAttendanceFilter = newValue;
                                      _applyFilters();
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                _buildFilterDropdown<ExamType>(
                                  '試験形式で絞り込む',
                                  _selectedExamFilter,
                                  ExamType.values,
                                  (newValue) {
                                    setState(() {
                                      _selectedExamFilter = newValue;
                                      _applyFilters();
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                if (_selectedFormatFilter != null ||
                                    _selectedAttendanceFilter != null ||
                                    _selectedExamFilter != null)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFormatFilter = null;
                                        _selectedAttendanceFilter = null;
                                        _selectedExamFilter = null;
                                        _applyFilters();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.clear_all,
                                      color: Colors.indigo,
                                    ),
                                    label: const Text(
                                      'フィルターをリセット',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                        fontFamily: 'NotoSansJP',
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.indigo,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.indigo[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                _buildSectionTitle(
                                  '全てのレビュー',
                                  Icons.rate_review,
                                ),
                                const SizedBox(height: 10),
                                // ★ 他ユーザーのレビューを全体評価の下にカード形式で表示
                                if (otherReviews.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 10),
                                      ...otherReviews.map(
                                        (
                                          review,
                                        ) => FutureBuilder<DocumentSnapshot>(
                                          future:
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(review.userId)
                                                  .get(),
                                          builder: (context, userSnapshot) {
                                            String? characterImage;
                                            if (userSnapshot.hasData &&
                                                userSnapshot.data != null) {
                                              final data =
                                                  userSnapshot.data!.data()
                                                      as Map<String, dynamic>?;
                                              characterImage =
                                                  data?['characterImage']
                                                      as String?;
                                            }
                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              elevation: 5,
                                              color: Colors.white,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // キャラクター画像
                                                    Container(
                                                      width: 56,
                                                      height: 56,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        color: Colors.grey[200],
                                                      ),
                                                      child:
                                                          characterImage != null
                                                              ? Image.asset(
                                                                characterImage,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              )
                                                              : Image.asset(
                                                                'assets/character_gorilla.png',
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // レビュー内容
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              RatingBarIndicator(
                                                                rating:
                                                                    review
                                                                        .overallSatisfaction,
                                                                itemBuilder:
                                                                    (
                                                                      context,
                                                                      index,
                                                                    ) => const Icon(
                                                                      Icons
                                                                          .star,
                                                                      color:
                                                                          Colors
                                                                              .amber,
                                                                    ),
                                                                itemCount: 5,
                                                                itemSize: 20.0,
                                                                direction:
                                                                    Axis.horizontal,
                                                              ),
                                                              Text(
                                                                review
                                                                    .reviewDate,
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      Colors
                                                                          .grey[600],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            '形式: ${_formatEnum(review.lectureFormat)}',
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                            ),
                                                          ),
                                                          Text(
                                                            '出席: ${_formatEnum(review.attendanceStrictness)}',
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                            ),
                                                          ),
                                                          Text(
                                                            '試験: ${_formatEnum(review.examType)}',
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                            ),
                                                          ),
                                                          Text(
                                                            '教員特徴: ${review.teacherFeature}',
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'コメント: ${review.comment}',
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Wrap(
                                                            spacing: 6.0,
                                                            children:
                                                                review.tags
                                                                    .map(
                                                                      (
                                                                        tag,
                                                                      ) => Chip(
                                                                        label: Text(
                                                                          tag,
                                                                          style: const TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.brown,
                                                                          ),
                                                                        ),
                                                                        backgroundColor:
                                                                            Colors.orangeAccent[50],
                                                                      ),
                                                                    )
                                                                    .toList(),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          _TakoyakiButton(
                                                            userId:
                                                                review.userId,
                                                            reviewId:
                                                                review.reviewId,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                  ),
        ),
      ),
    );
  }

  Widget _buildLectureInfoCard() {
    return Card(
      margin: EdgeInsets.zero, // Remove margin to allow for specific padding
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lectureName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.teacherName,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontFamily: 'NotoSansJP',
              ),
            ),
            if (widget.initialDescription != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.initialDescription!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRatingsCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '全体の評価',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                RatingBarIndicator(
                  rating: _averageOverallSatisfaction,
                  itemBuilder:
                      (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 24.0,
                  direction: Axis.horizontal,
                ),
                const SizedBox(width: 12),
                Text(
                  _averageOverallSatisfaction.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_allReviews.length}件のレビュー)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.sentiment_satisfied,
                  color: Colors.lightGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '楽単度: ${_averageEasiness.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostReviewButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CreditInputPage(
                  lectureName: widget.lectureName,
                  teacherName: widget.teacherName,
                  code: widget.code,
                ),
          ),
        ).then((result) {
          if (result == true) {
            // 投稿完了時にレビューを再取得
            _subscribeToReviews();
          }
        });
      },
      icon: const Icon(Icons.edit, color: Colors.white),
      label: const Text(
        'この講義のレビューを投稿する',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'NotoSansJP',
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.teal[100]!, width: 1.5),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'NotoSansJP',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>(
    String hintText,
    T? selectedValue,
    List<T> items,
    ValueChanged<T?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: selectedValue,
          hint: Text(hintText, style: TextStyle(color: Colors.grey[700])),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          onChanged: onChanged,
          items:
              items.map<DropdownMenuItem<T>>((T value) {
                return DropdownMenuItem<T>(
                  value: value,
                  child: Text(_formatEnum(value)), // Enum値を整形して表示
                );
              }).toList(),
        ),
      ),
    );
  }
}

// --- たこ焼きボタンWidget ---
class _TakoyakiButton extends StatefulWidget {
  final String? userId;
  final String reviewId;
  const _TakoyakiButton({this.userId, required this.reviewId});

  @override
  State<_TakoyakiButton> createState() => _TakoyakiButtonState();
}

class _TakoyakiButtonState extends State<_TakoyakiButton> {
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _checkIfSent();
  }

  Future<void> _checkIfSent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sent =
          prefs.getBool('takoyaki_sent_${widget.reviewId}_${user.uid}') ??
          false;
    });
  }

  Future<void> _sendTakoyaki() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.userId == null) return;
    // Firestoreで投稿者にたこ焼きを1つ加算
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'takoyakiCount': FieldValue.increment(1)});
    // ローカルで送信済みフラグを保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('takoyaki_sent_${widget.reviewId}_${user.uid}', true);
    setState(() {
      _sent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'たこ焼きを送りました！',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _sent ? null : _sendTakoyaki,
          icon: Image.asset('assets/takoyaki.png', width: 24, height: 24),
          label: Text(
            _sent ? '送信済み' : '有益！たこ焼き',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _sent ? Colors.grey : Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
