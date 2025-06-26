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
import 'current_semester_reviews_page.dart' show _CourseCard;
import 'components/course_card.dart';

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

class CourseCardModel {
  final String courseId;
  final String lectureName;
  final String teacherName;
  final double avgSatisfaction;
  final double avgEasiness;
  final int reviewCount;
  final bool hasMyReview;

  CourseCardModel({
    required this.courseId,
    required this.lectureName,
    required this.teacherName,
    required this.avgSatisfaction,
    required this.avgEasiness,
    required this.reviewCount,
    required this.hasMyReview,
  });

  // ファクトリ: Mapから生成
  factory CourseCardModel.fromMap(Map<String, dynamic> map) {
    return CourseCardModel(
      courseId: map['courseId'] ?? '',
      lectureName: map['lectureName'] ?? map['name'] ?? '',
      teacherName: map['teacherName'] ?? map['instructor'] ?? '',
      avgSatisfaction: (map['avgSatisfaction'] ?? 0.0) * 1.0,
      avgEasiness: (map['avgEasiness'] ?? 0.0) * 1.0,
      reviewCount: map['reviewCount'] ?? 0,
      hasMyReview: map['hasMyReview'] ?? false,
    );
  }
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
  String? _selectedCategory;
  List<String> _categories = [];
  List<Map<String, dynamic>> _allCourses = [];
  bool _isLoadingCourses = true;
  List<CourseCardModel> _courseCardModels = [];

  @override
  void initState() {
    super.initState();
    _loadAllCourses();
  }

  // 全授業データを読み込む
  Future<void> _loadAllCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final List<Map<String, dynamic>> allCourses = [];

      // 1. course_dataコレクションから後期の授業を取得
      final courseDataSnapshot =
          await FirebaseFirestore.instance.collection('course_data').get();
      for (final doc in courseDataSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('data') &&
            data['data'] is Map &&
            data['data']['courses'] is List) {
          final List<dynamic> courses = data['data']['courses'];
          for (final course in courses) {
            if (course is Map<String, dynamic>) {
              // courseIdを生成（授業名|教員名|曜日|時限の形式）
              final lectureName = course['lectureName'] ?? course['name'] ?? '';
              final teacherName =
                  course['teacherName'] ??
                  course['instructor'] ??
                  course['teacher'] ??
                  '';
              final period = course['period'] ?? '';
              final courseId = '$lectureName|$teacherName|$period';

              allCourses.add({
                ...course,
                'courseId': courseId,
                'semester': course['semester'] ?? '後期',
              });
            }
          }
        }
      }

      // 2. master_coursesコレクションから前期の授業を取得
      final masterCoursesSnapshot =
          await FirebaseFirestore.instance.collection('master_courses').get();
      for (final doc in masterCoursesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.isNotEmpty) {
          // courseIdを生成（授業名|教員名|曜日|時限の形式）
          final lectureName = data['name'] ?? '';
          final teacherName = data['instructor'] ?? '';
          final period = data['period'] ?? '';
          final courseId = '$lectureName|$teacherName|$period';

          allCourses.add({
            'lectureName': lectureName,
            'teacherName': teacherName,
            'period': period,
            'category': data['category'] ?? '',
            'semester': '前期',
            'courseId': courseId,
            // 他のフィールドも追加
            'name': lectureName,
            'instructor': teacherName,
            'day': data['day'] ?? '',
            'subject': data['category'] ?? '',
          });
        }
      }

      // カテゴリ一覧を抽出
      final allCategoriesRaw =
          allCourses.map((course) {
            return (course['category'] ?? course['subject'] ?? '').toString();
          }).toList();
      final categorySet = allCategoriesRaw.toSet();
      final categories =
          categorySet.where((c) => c.isNotEmpty).toList()..sort();
      if (allCategoriesRaw.any((c) => c.isEmpty)) {
        categories.insert(0, '未分類');
      }

      // 既存のallCoursesリストをList<CourseCardModel>に変換してsetState
      final courseCardModels =
          allCourses.map((course) {
            return CourseCardModel.fromMap(course);
          }).toList();

      setState(() {
        _allCourses = allCourses;
        _categories = categories;
        _isLoadingCourses = false;
        _courseCardModels = courseCardModels;
      });

      print(
        'Loaded ${allCourses.length} courses (${courseDataSnapshot.docs.length} from course_data, ${masterCoursesSnapshot.docs.length} from master_courses)',
      );
    } catch (e) {
      print('Error loading courses: $e');
      setState(() {
        _isLoadingCourses = false;
      });
    }
  }

  // フィルタリングされた授業を取得
  List<Map<String, dynamic>> get _filteredCourses {
    return _allCourses.where((course) {
      final lectureName =
          (course['lectureName'] ?? course['name'] ?? '')
              .toString()
              .toLowerCase();
      final teacherName =
          (course['teacherName'] ??
                  course['instructor'] ??
                  course['teacher'] ??
                  '')
              .toString()
              .toLowerCase();
      final category =
          (course['category'] ?? course['subject'] ?? '').toString();

      // 検索クエリでフィルタリング
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        final searchLower = widget.searchQuery!.toLowerCase();
        if (!lectureName.contains(searchLower) &&
            !teacherName.contains(searchLower)) {
          return false;
        }
      }

      // カテゴリでフィルタリング
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (_selectedCategory == '未分類') {
          if (category.isNotEmpty) return false;
        } else {
          if (category != _selectedCategory) return false;
        }
      }

      return true;
    }).toList();
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
            _isLoadingCourses
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : Column(
                  children: [
                    // カテゴリフィルター
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blueAccent[100]!,
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            hint: const Text('教科で絞り込む'),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.indigo,
                            ),
                            items:
                                _categories
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    // 結果件数表示
                    if (widget.searchQuery != null &&
                        widget.searchQuery!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          '${_filteredCourses.length}件の授業が見つかりました',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    // 授業一覧
                    Expanded(
                      child:
                          _courseCardModels.isEmpty
                              ? const Center(
                                child: Text(
                                  '授業が見つかりませんでした',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _courseCardModels.length,
                                itemBuilder: (context, index) {
                                  final model = _courseCardModels[index];
                                  return CourseCard(
                                    course: {
                                      'courseId': model.courseId,
                                      'lectureName': model.lectureName,
                                      'teacherName': model.teacherName,
                                      'avgSatisfaction': model.avgSatisfaction,
                                      'avgEasiness': model.avgEasiness,
                                      'reviewCount': model.reviewCount,
                                      'hasMyReview': model.hasMyReview,
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final lectureName = course['lectureName'] ?? course['name'] ?? '';
    final teacherName =
        course['teacherName'] ??
        course['instructor'] ??
        course['teacher'] ??
        '';
    final period = course['period'] ?? '';
    final semester = course['semester'] ?? '';
    final category = course['category'] ?? course['subject'] ?? '';
    final courseId = course['courseId'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreditReviewPage(
                    lectureName: lectureName,
                    teacherName: teacherName,
                    courseId: courseId,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 授業名
              Text(
                lectureName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 教員名と時間
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      teacherName,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (period.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // 学期とカテゴリ
              Row(
                children: [
                  if (semester.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        semester,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (category.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // レビュー情報（非同期で取得）
              FutureBuilder<Map<String, dynamic>>(
                future: _getReviewStats(courseId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final reviewData = snapshot.data;
                  if (reviewData == null || reviewData['reviewCount'] == 0) {
                    return Row(
                      children: [
                        Icon(
                          Icons.rate_review,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'レビューなし',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${reviewData['avgSatisfaction'].toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.sentiment_satisfied,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reviewData['avgEasiness'].toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${reviewData['reviewCount']}件のレビュー',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // レビュー統計を取得
  Future<Map<String, dynamic>> _getReviewStats(String courseId) async {
    try {
      if (courseId.isEmpty)
        return {'reviewCount': 0, 'avgSatisfaction': 0.0, 'avgEasiness': 0.0};

      final query =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('courseId', isEqualTo: courseId)
              .get();

      final docs = query.docs;
      if (docs.isEmpty) {
        return {'reviewCount': 0, 'avgSatisfaction': 0.0, 'avgEasiness': 0.0};
      }

      double sumSatisfaction = 0.0;
      double sumEasiness = 0.0;

      for (final doc in docs) {
        final data = doc.data();
        sumSatisfaction +=
            (data['overallSatisfaction'] ?? data['satisfaction'] ?? 0.0) * 1.0;
        sumEasiness += (data['easiness'] ?? data['ease'] ?? 0.0) * 1.0;
      }

      return {
        'reviewCount': docs.length,
        'avgSatisfaction': sumSatisfaction / docs.length,
        'avgEasiness': sumEasiness / docs.length,
      };
    } catch (e) {
      print('Error getting review stats: $e');
      return {'reviewCount': 0, 'avgSatisfaction': 0.0, 'avgEasiness': 0.0};
    }
  }
}
