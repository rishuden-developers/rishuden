// credit_review_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ★レート表示に利用するパッケージをインポート
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'credit_input_page.dart'; // レビュー投稿画面への遷移用
import 'credit_explore_page.dart'; // ボトムナビゲーション用

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
  final String teacherName; // 追加
  final double overallSatisfaction;
  final double easiness;
  final LectureFormat lectureFormat;
  final AttendanceStrictness attendanceStrictness;
  final ExamType examType;
  final String teacherFeature;
  final String comment;
  final List<String> tags; // タグの追加
  final String reviewId; // レビューの一意なID
  final String reviewDate; // レビュー投稿日

  LectureReview({
    required this.lectureName,
    required this.teacherName,
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

class CreditReviewPage extends StatefulWidget {
  final String lectureName;
  final String teacherName;
  final String? initialDescription; // 講義の概要
  final double? initialOverallSatisfaction; // 講義全体の平均満足度
  final double? initialEasiness; // 講義全体の平均楽単度

  const CreditReviewPage({
    super.key,
    required this.lectureName,
    required this.teacherName,
    this.initialDescription,
    this.initialOverallSatisfaction,
    this.initialEasiness,
  });

  @override
  State<CreditReviewPage> createState() => _CreditReviewPageState();
}

class _CreditReviewPageState extends State<CreditReviewPage> {
  // ダミーのレビューデータ
  List<LectureReview> _allReviews = [];
  List<LectureReview> _filteredReviews = [];

  // フィルター用
  LectureFormat? _selectedFormatFilter;
  AttendanceStrictness? _selectedAttendanceFilter;
  ExamType? _selectedExamFilter;

  @override
  void initState() {
    super.initState();
    _allReviews = _generateDummyReviewsForLecture(
      widget.lectureName,
      widget.teacherName,
    );
    _applyFilters();
  }

  List<LectureReview> _generateDummyReviewsForLecture(
    String lectureName,
    String teacherName,
  ) {
    // 実際のアプリケーションでは、ここでlectureNameとteacherNameに基づいてデータベースからレビューを取得します
    return [
          LectureReview(
            lectureName: lectureName,
            teacherName: teacherName,
            overallSatisfaction: 5.0,
            easiness: 4.5,
            lectureFormat: LectureFormat.faceToFace,
            attendanceStrictness: AttendanceStrictness.noAttendance,
            examType: ExamType.report,
            teacherFeature: '非常に丁寧',
            comment:
                'この講義は最高でした！先生の説明も分かりやすく、内容も興味深かったです。レポートは大変でしたが、得るものが多かったです。',
            tags: ['レポート多め', 'オンライン完結', 'テストなし'],
            reviewId: 'rev001',
            reviewDate: '2023/04/15',
          ),
          LectureReview(
            lectureName: lectureName,
            teacherName: teacherName,
            overallSatisfaction: 4.0,
            easiness: 5.0,
            lectureFormat: LectureFormat.zoom,
            attendanceStrictness: AttendanceStrictness.flexible,
            examType: ExamType.none,
            teacherFeature: '面白い',
            comment: '楽単です！出席も緩く、テストもありませんでした。気軽に単位を取りたい人におすすめです。',
            tags: ['楽単', 'オンライン完結', 'テストなし'],
            reviewId: 'rev002',
            reviewDate: '2023/05/20',
          ),
          LectureReview(
            lectureName: lectureName,
            teacherName: teacherName,
            overallSatisfaction: 3.5,
            easiness: 3.0,
            lectureFormat: LectureFormat.onDemand,
            attendanceStrictness: AttendanceStrictness.everyTimeRollCall,
            examType: ExamType.written,
            teacherFeature: '普通',
            comment: '内容は普通。毎回出席確認があり、テストもあるので、真面目にやらないと単位は厳しいかも。',
            tags: ['出席必須', 'テストあり'],
            reviewId: 'rev003',
            reviewDate: '2023/06/01',
          ),
          LectureReview(
            lectureName: lectureName,
            teacherName: teacherName,
            overallSatisfaction: 4.2,
            easiness: 4.8,
            lectureFormat: LectureFormat.faceToFace,
            attendanceStrictness: AttendanceStrictness.noAttendance,
            examType: ExamType.report,
            teacherFeature: 'サポート充実',
            comment: '質問への対応がとても丁寧で助かりました。レポートは大変ですが、個別のフィードバックが充実しています。',
            tags: ['レポート多め', 'サポート充実'],
            reviewId: 'rev004',
            reviewDate: '2023/06/10',
          ),
        ]
        .where(
          (review) =>
              review.lectureName == lectureName &&
              review.teacherName == teacherName,
        )
        .toList();
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
    if (enumValue == null) return '';
    return enumValue.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lectureName,
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
        child: SafeArea(
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - 32, // Adjust for padding
                    ),
                    // ↓ IntrinsicHeight を削除し、Columnを直接childに
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 講義名と教員名
                        _buildLectureInfoCard(),
                        const SizedBox(height: 20),

                        // 全体評価と楽単度
                        _buildOverallRatingsCard(),
                        const SizedBox(height: 20),

                        // 新しいレビューを投稿するボタン
                        _buildPostReviewButton(context),
                        const SizedBox(height: 30),

                        // フィルターオプションのタイトル
                        _buildSectionTitle('レビューを絞り込む', Icons.filter_list),
                        const SizedBox(height: 10),
                        // フィルタードロップダウン
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
                        // フィルターリセットボタン
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
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

                        // レビュー表示
                        _buildSectionTitle('全てのレビュー', Icons.rate_review),
                        const SizedBox(height: 10),
                        _filteredReviews.isEmpty
                            ? const Center(
                              child: Text(
                                '該当するレビューがありません。',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredReviews.length,
                              itemBuilder: (context, index) {
                                final review = _filteredReviews[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            RatingBarIndicator(
                                              rating:
                                                  review.overallSatisfaction,
                                              itemBuilder:
                                                  (context, index) =>
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                      ),
                                              itemCount: 5,
                                              itemSize: 20.0,
                                              direction: Axis.horizontal,
                                            ),
                                            Text(
                                              review.reviewDate,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '形式: ${_formatEnum(review.lectureFormat)}',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '出席: ${_formatEnum(review.attendanceStrictness)}',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '試験: ${_formatEnum(review.examType)}',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '教員特徴: ${review.teacherFeature}',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'コメント: ${review.comment}',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6.0,
                                          children:
                                              review.tags
                                                  .map(
                                                    (tag) => Chip(
                                                      label: Text(
                                                        tag,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.brown[700],
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          Colors
                                                              .orangeAccent[50],
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigation(),
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
                ),
          ),
        );
      },
      icon: const Icon(Icons.rate_review, color: Colors.white),
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
