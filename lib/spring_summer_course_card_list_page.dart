import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'credit_review_page.dart';
import 'components/course_card.dart';
import 'providers/timetable_provider.dart';
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用

class SpringSummerCourseCardListPage extends ConsumerStatefulWidget {
  const SpringSummerCourseCardListPage({super.key});

  @override
  ConsumerState<SpringSummerCourseCardListPage> createState() =>
      _SpringSummerCourseCardListPageState();
}

class _SpringSummerCourseCardListPageState
    extends ConsumerState<SpringSummerCourseCardListPage> {
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpringSummerCourses();
  }

  // 春夏学期の授業データを読み込む
  Future<void> _loadSpringSummerCourses() async {
    try {
      final List<Map<String, dynamic>> courses = [];

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

          // 教員名をtimetableProviderから取得（時間割画面と同期）
          String teacherName =
              courseData['teacherName'] ?? courseData['instructor'] ?? '';
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

      setState(() {
        _courses = courses;
        _isLoading = false;
      });

      print('Loaded ${courses.length} courses from course_mapping');
    } catch (e) {
      print('Error loading spring/summer courses: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topOffset =
        kToolbarHeight + MediaQuery.of(context).padding.top;
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
              // ListView（AppBarの下からボトムナビの上まで）
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
                        : ListView.builder(
                          physics: ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _courses.length,
                          itemBuilder: (context, index) {
                            final course = _courses[index];
                            return Align(
                              alignment: Alignment.center,
                              child: FractionallySizedBox(
                                widthFactor: 0.80,
                                child: CourseCard(
                                  key: ValueKey(course['courseId']),
                                  course: course,
                                  onTeacherNameChanged: (newTeacherName) {
                                    final idx = _courses.indexWhere(
                                      (c) =>
                                          c['courseId'] == course['courseId'],
                                    );
                                    if (idx != -1) {
                                      setState(() {
                                        _courses[idx] = {
                                          ..._courses[idx],
                                          'teacherName': newTeacherName,
                                        };
                                      });
                                      print(
                                        'Updated teacher name for \\${course['courseId']} to: \\$newTeacherName',
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
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

  // 教員名を更新するメソッド
  void _updateTeacherName(String courseId, String newTeacherName) {
    setState(() {
      for (int i = 0; i < _courses.length; i++) {
        if (_courses[i]['courseId'] == courseId) {
          _courses[i] = {..._courses[i], 'teacherName': newTeacherName};
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
