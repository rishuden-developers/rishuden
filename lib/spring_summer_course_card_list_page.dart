import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/course_card.dart';
import 'providers/timetable_provider.dart';
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用
import 'package:firebase_auth/firebase_auth.dart';
import 'main_page.dart';
import 'providers/current_page_provider.dart';

class SpringSummerCourseCardListPage extends ConsumerStatefulWidget {
  const SpringSummerCourseCardListPage({super.key});

  @override
  ConsumerState<SpringSummerCourseCardListPage> createState() =>
      _SpringSummerCourseCardListPageState();
}

class _SpringSummerCourseCardListPageState
    extends ConsumerState<SpringSummerCourseCardListPage> {
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _pagedCourses = [];
  bool _isLoading = true;
  static const int pageSize = 20;
  int _currentPage = 1;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSpringSummerCourses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 春夏学期の授業データを読み込む
  Future<void> _loadSpringSummerCourses() async {
    try {
      var courses = <Map<String, dynamic>>[];

      // global/course_mappingドキュメントからmappingフィールドを取得
      final doc =
          await FirebaseFirestore.instance
              .collection('global')
              .doc('course_mapping')
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        final mapping = data['mapping'] as Map<String, dynamic>? ?? {};
        print('mapping runtimeType: \\${mapping.runtimeType}');

        // mappingの各エントリを処理
        for (final entry in mapping.entries) {
          final courseId = entry.key; // 「講義名|教室|曜日|時限」形式
          final courseData = entry.value;

          print(
            'courseData for $courseId: $courseData (type: ${courseData.runtimeType})',
          );

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

          // 教員名をtimetableProviderから取得（時間割画面と同期）
          String teacherName = '';

          // courseDataがMap型の場合のみアクセス
          if (courseData is Map<String, dynamic>) {
            teacherName =
                courseData['teacherName'] ?? courseData['instructor'] ?? '';
          }

          if (courseId.isNotEmpty) {
            final timetableTeacherName =
                ref.read(timetableProvider)['teacherNames']?[courseId];
            if (timetableTeacherName != null &&
                timetableTeacherName.isNotEmpty) {
              teacherName = timetableTeacherName;
            }
          }

          courses.add({
            'courseId': courseId,
            'lectureName': lectureName,
            'classroom': classroom,
            'teacherName': teacherName,
            'avgSatisfaction': 0.0,
            'avgEasiness': 0.0,
            'reviewCount': 0,
            'hasMyReview': false,
          });
        }
      }

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

            for (final doc in reviews) {
              final data = doc.data();
              final satisfaction =
                  (data['overallSatisfaction'] ?? data['satisfaction'] ?? 0.0) *
                  1.0;
              final easiness = (data['easiness'] ?? data['ease'] ?? 0.0) * 1.0;

              totalSatisfaction += satisfaction;
              totalEasiness += easiness;

              // 自分のレビューがあるかチェック
              if (user != null && data['userId'] == user.uid) {
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

      print('courses runtimeType before setState: \\${courses.runtimeType}');
      if (courses is Map) {
        print('courses is Map! Converting to List.');
        // 念のためvaluesをtoList
        // ignore: prefer_collection_literals
        courses = List<Map<String, dynamic>>.from((courses as Map).values);
      }

      setState(() {
        _allCourses = courses;
        _pagedCourses = _getPagedCourses(1);
        _isLoading = false;
      });

      print('Loaded ${courses.length} courses from course_mapping');
    } catch (e) {
      print('Error loading spring/summer courses: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getPagedCourses(int page) {
    final start = (page - 1) * pageSize;
    final end =
        (start + pageSize) > _allCourses.length
            ? _allCourses.length
            : (start + pageSize);
    return _allCourses.sublist(start, end);
  }

  void _nextPage() {
    if (_currentPage * pageSize < _allCourses.length) {
      setState(() {
        _currentPage++;
        _pagedCourses = _getPagedCourses(_currentPage);
      });
      _pageController.animateToPage(
        _currentPage - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _pagedCourses = _getPagedCourses(_currentPage);
      });
      _pageController.animateToPage(
        _currentPage - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topOffset =
        kToolbarHeight + MediaQuery.of(context).padding.top;
    final int totalPages = (_allCourses.length / pageSize).ceil();
    const double bottomNavHeight = 95.0;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/night_view.png', fit: BoxFit.cover),
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
                  title: const Text('春夏学期の授業一覧'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.white,
                ),
              ),
              // ページネーション＋PageView
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                bottom: 0,
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : Column(
                          children: [
                            // ページネーションUI
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      minimumSize: Size(32, 32),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed:
                                        _currentPage > 1 ? _prevPage : null,
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${((_currentPage - 1) * pageSize + 1)}-${((_currentPage - 1) * pageSize + _pagedCourses.length)}件 / 全${_allCourses.length}件',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      minimumSize: Size(32, 32),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed:
                                        _currentPage * pageSize <
                                                _allCourses.length
                                            ? _nextPage
                                            : null,
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 横スクロールPageView
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: totalPages,
                                onPageChanged: (pageIdx) {
                                  setState(() {
                                    _currentPage = pageIdx + 1;
                                    _pagedCourses = _getPagedCourses(
                                      _currentPage,
                                    );
                                  });
                                },
                                itemBuilder: (context, pageIdx) {
                                  final paged = _getPagedCourses(pageIdx + 1);
                                  return ListView.builder(
                                    physics: ClampingScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                      bottom: 80,
                                      top: 0,
                                      left: 16,
                                      right: 16,
                                    ),
                                    itemCount: paged.length,
                                    itemBuilder: (context, index) {
                                      final course = paged[index];
                                      return Align(
                                        alignment: Alignment.center,
                                        child: FractionallySizedBox(
                                          widthFactor: 0.80,
                                          child: CourseCard(
                                            key: ValueKey(course['courseId']),
                                            course: course,
                                            onTeacherNameChanged: (
                                              newTeacherName,
                                            ) {
                                              final idx = _allCourses
                                                  .indexWhere(
                                                    (c) =>
                                                        c['courseId'] ==
                                                        course['courseId'],
                                                  );
                                              if (idx != -1) {
                                                setState(() {
                                                  _allCourses[idx] = {
                                                    ..._allCourses[idx],
                                                    'teacherName':
                                                        newTeacherName,
                                                  };
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
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
                child: CommonBottomNavigation(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 教員名を更新するメソッド
  void _updateTeacherName(String courseId, String newTeacherName) {
    setState(() {
      for (int i = 0; i < _allCourses.length; i++) {
        if (_allCourses[i]['courseId'] == courseId) {
          _allCourses[i] = {..._allCourses[i], 'teacherName': newTeacherName};
          break;
        }
      }
    });
    print('Updated teacher name for $courseId to: $newTeacherName');
  }
}

class _DummyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  _DummyHeaderDelegate({required this.height});
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
