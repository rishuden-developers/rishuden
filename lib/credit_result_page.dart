// credit_result_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'credit_review_page.dart'; // レビュー詳細ページへの遷移用
import 'search_credits_page/autumn_winter_course_review_page.dart'; // 秋冬学期用レビュー一覧画面
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
import 'package:rishuden/providers/timetable_provider.dart';
import 'package:rishuden/providers/background_image_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // 全授業データを読み込む（前期と後期の両方）
  Future<void> _loadAllCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final List<Map<String, dynamic>> allCourses = [];

      // 1. 前期（春夏学期）の授業データを取得
      final springSummerCourses = await _loadSpringSummerCourses();
      allCourses.addAll(springSummerCourses);

      // 2. 後期（秋冬学期）の授業データを取得
      final autumnWinterCourses = await _loadAutumnWinterCourses();
      allCourses.addAll(autumnWinterCourses);

      // カテゴリ一覧を抽出
      final categories = ['未分類', '前期', '後期'];

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
        'Loaded ${allCourses.length} total courses (${springSummerCourses.length} spring/summer + ${autumnWinterCourses.length} autumn/winter)',
      );
    } catch (e) {
      print('Error loading courses: $e');
      setState(() {
        _isLoadingCourses = false;
      });
    }
  }

  // 前期（春夏学期）の授業データを読み込む
  Future<List<Map<String, dynamic>>> _loadSpringSummerCourses() async {
    final List<Map<String, dynamic>> courses = [];

    try {
      // global/course_mappingドキュメントからmappingフィールドを取得
      final doc =
          await FirebaseFirestore.instance
              .collection('global')
              .doc('course_mapping')
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        final mapping = data['mapping'] as Map<String, dynamic>? ?? {};

        // mappingの各エントリを処理
        for (final entry in mapping.entries) {
          final courseId = entry.key; // 「講義名|教室|曜日|時限」形式
          final courseData = entry.value;

          // courseIdをパースして講義名と教室を取得
          String lectureName = '';
          String classroom = '';

          if (courseId.contains('|')) {
            final parts = courseId.split('|');
            if (parts.length >= 2) {
              lectureName = parts[0];
              classroom = parts[1];
            }
          } else {
            // 古い形式の場合はcourseIdをそのまま講義名として使用
            lectureName = courseId;
          }

          courses.add({
            'courseId': courseId,
            'lectureName': lectureName,
            'classroom': classroom,
            'teacherName': '', // 教員名は別途取得が必要な場合があります
            'category': '', // カテゴリは別途設定が必要
            'semester': '前期', // 前期として設定
            'avgSatisfaction': 0.0,
            'avgEasiness': 0.0,
            'reviewCount': 0,
            'hasMyReview': false,
          });
        }
      }
    } catch (e) {
      print('Error loading spring/summer courses: $e');
    }

    return courses;
  }

  // 後期（秋冬学期）の授業データを読み込む
  Future<List<Map<String, dynamic>>> _loadAutumnWinterCourses() async {
    final List<Map<String, dynamic>> courses = [];

    // 各授業のレビュー情報を取得
    for (int i = 0; i < courses.length; i++) {
      final courseId = courses[i]['courseId'];
      try {
        final reviewsSnapshot =
            await FirebaseFirestore.instance
                .collection('reviews')
                .where('courseId', isEqualTo: courseId)
                .get();

        final reviews = reviewsSnapshot.docs;
        if (reviews.isNotEmpty) {
          double totalSatisfaction = 0.0;
          double totalEasiness = 0.0;
          bool hasMyReview = false;
          final user = FirebaseAuth.instance.currentUser;

          // ★この内側の for を次のように書く
          for (final doc in reviews) {
            final d = doc.data();
            final s = (d['overallSatisfaction'] ?? d['satisfaction'] ?? 0);
            final e = (d['easiness'] ?? d['ease'] ?? 0);
            totalSatisfaction += (s is num ? s.toDouble() : 0.0);
            totalEasiness += (e is num ? e.toDouble() : 0.0);

            if (user != null && d['userId'] == user.uid) {
              hasMyReview = true;
            }
          }

          courses[i] = {
            ...courses[i],
            'avgSatisfaction': totalSatisfaction / reviews.length,
            'avgEasiness': totalEasiness / reviews.length,
            'reviewCount': reviews.length,
            'hasMyReview': hasMyReview,
          };
        }
      } catch (e) {
        print('Error fetching reviews for $courseId: $e');
      }
    }

    return courses;
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
    final double topOffset =
        kToolbarHeight + MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            ref.watch(backgroundImagePathProvider),
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
        Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  title: Text(
                    _getPageTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansJP',
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              // ListView（AppBarの下から画面の一番下まで）
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                bottom: 0,
                child:
                    _isLoadingCourses
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          children: [
                            // カテゴリフィルター
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
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
                            if (_courseCardModels.isEmpty)
                              const Center(
                                child: Text(
                                  '授業が見つかりませんでした',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            else
                              ..._courseCardModels.map(
                                (model) => CourseCard(
                                  course: {
                                    'courseId': model.courseId,
                                    'lectureName': model.lectureName,
                                    'teacherName': model.teacherName,
                                    'avgSatisfaction': model.avgSatisfaction,
                                    'avgEasiness': model.avgEasiness,
                                    'reviewCount': model.reviewCount,
                                    'hasMyReview': model.hasMyReview,
                                  },
                                  onTeacherNameChanged: (newTeacherName) {
                                    _updateTeacherName(
                                      model.courseId,
                                      newTeacherName,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
              ),
              // ボトムナビ
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: const CommonBottomNavigation(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final lectureName = course['lectureName'] ?? course['name'] ?? '';

    // 教員名をtimetableProviderから取得（時間割画面と同期）
    final courseId = course['courseId'] ?? '';
    String teacherName =
        course['teacherName'] ??
        course['instructor'] ??
        course['teacher'] ??
        '';
    if (courseId.isNotEmpty) {
      final timetableTeacherName =
          ref.watch(timetableProvider)['teacherNames']?[courseId];
      if (timetableTeacherName != null && timetableTeacherName.isNotEmpty) {
        teacherName = timetableTeacherName;
      }
    }

    final period = course['period'] ?? '';
    final semester = course['semester'] ?? '';
    final category = course['category'] ?? course['subject'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // 前期と後期で遷移先を分ける
          final semester = course['semester'] ?? '';
          if (semester == '後期') {
            // 後期の場合は秋冬学期用のレビュー一覧画面に遷移
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AutumnWinterCourseReviewPage(
                      lectureName: lectureName,
                      teacherName: teacherName,
                    ),
              ),
            );
          } else {
            // 前期の場合は従来のレビュー一覧画面に遷移
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
          }
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
                      teacherName.isNotEmpty ? teacherName : '未設定',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            teacherName.isNotEmpty
                                ? Colors.grey[700]
                                : Colors.grey[500],
                        fontStyle:
                            teacherName.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                      ),
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
                future: _getReviewStats(course),
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

  // レビュー統計を取得（前期と後期で異なるロジック）
  Future<Map<String, dynamic>> _getReviewStats(
    Map<String, dynamic> course,
  ) async {
    try {
      final semester = course['semester'] ?? '';
      final courseId = course['courseId'] ?? '';
      final lectureName = course['lectureName'] ?? '';
      final teacherName = course['teacherName'] ?? '';

      if (semester == '後期') {
        // 後期（秋冬学期）: lectureNameとteacherNameで検索
        if (lectureName.isEmpty) {
          return {'reviewCount': 0, 'avgSatisfaction': 0.0, 'avgEasiness': 0.0};
        }

        Query query = FirebaseFirestore.instance
            .collection('reviews')
            .where('lectureName', isEqualTo: lectureName);

        if (teacherName.isNotEmpty) {
          query = query.where('teacherName', isEqualTo: teacherName);
        }

        final querySnapshot = await query.get();
        final docs = querySnapshot.docs;

        if (docs.isEmpty) {
          return {'reviewCount': 0, 'avgSatisfaction': 0.0, 'avgEasiness': 0.0};
        }

        double sumSatisfaction = 0.0;
        double sumEasiness = 0.0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          sumSatisfaction +=
              (data['overallSatisfaction'] ?? data['satisfaction'] ?? 0.0) *
              1.0;
          sumEasiness += (data['easiness'] ?? data['ease'] ?? 0.0) * 1.0;
        }

        return {
          'reviewCount': docs.length,
          'avgSatisfaction': sumSatisfaction / docs.length,
          'avgEasiness': sumEasiness / docs.length,
        };
      } else {
        // 前期（春夏学期）: courseIdで検索
        if (courseId.isEmpty) {
          return {'reviewCount': 0, 'avgSatisfaction': 0.0, 'avgEasiness': 0.0};
        }

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
          final data = doc.data() as Map<String, dynamic>? ?? {};
          sumSatisfaction +=
              (data['overallSatisfaction'] ?? data['satisfaction'] ?? 0.0) *
              1.0;
          sumEasiness += (data['easiness'] ?? data['ease'] ?? 0.0) * 1.0;
        }

        return {
          'reviewCount': docs.length,
          'avgSatisfaction': sumSatisfaction / docs.length,
          'avgEasiness': sumEasiness / docs.length,
        };
      }
    } catch (e) {
      print('Error getting review stats: $e');
      return {'reviewCount': 0, 'avgSatisfaction': 0.0, 'avgEasiness': 0.0};
    }
  }

  // 教員名を更新するメソッド
  void _updateTeacherName(String courseId, String newTeacherName) {
    setState(() {
      // _allCoursesの該当する講義の教員名を更新
      for (int i = 0; i < _allCourses.length; i++) {
        if (_allCourses[i]['courseId'] == courseId) {
          _allCourses[i]['teacherName'] = newTeacherName;
          break;
        }
      }

      // _courseCardModelsの該当する講義の教員名を更新
      for (int i = 0; i < _courseCardModels.length; i++) {
        if (_courseCardModels[i].courseId == courseId) {
          _courseCardModels[i] = CourseCardModel(
            courseId: _courseCardModels[i].courseId,
            lectureName: _courseCardModels[i].lectureName,
            teacherName: newTeacherName,
            avgSatisfaction: _courseCardModels[i].avgSatisfaction,
            avgEasiness: _courseCardModels[i].avgEasiness,
            reviewCount: _courseCardModels[i].reviewCount,
            hasMyReview: _courseCardModels[i].hasMyReview,
          );
          break;
        }
      }
    });

    // TODO: 必要に応じてFirestoreにも保存
    print('Updated teacher name for $courseId to: $newTeacherName');
  }
}
