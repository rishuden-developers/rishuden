import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'components/course_card.dart';
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用

class SpringSummerCourseCardListPage extends StatefulWidget {
  const SpringSummerCourseCardListPage({super.key});

  @override
  State<SpringSummerCourseCardListPage> createState() =>
      _SpringSummerCourseCardListPageState();
}

class _SpringSummerCourseCardListPageState
    extends State<SpringSummerCourseCardListPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      // global/course_mappingドキュメントからmappingフィールドを取得
      final doc =
          await FirebaseFirestore.instance
              .collection('global')
              .doc('course_mapping')
              .get();

      final List<Map<String, dynamic>> courses = [];

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
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/night_view.png', fit: BoxFit.cover),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
        Scaffold(
          backgroundColor: Colors.transparent,
          body:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : CustomScrollView(
                    physics: ClampingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        title: const Text('春夏学期の授業一覧'),
                        foregroundColor: Colors.white,
                      ),
                      SliverPersistentHeader(
                        pinned: false,
                        delegate: _DummyHeaderDelegate(height: 16),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 95.0,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return Align(
                              alignment: Alignment.center,
                              child: FractionallySizedBox(
                                widthFactor: 0.80,
                                child: CourseCard(course: _courses[index]),
                              ),
                            );
                          }, childCount: _courses.length),
                        ),
                      ),
                    ],
                  ),
          bottomNavigationBar: const CommonBottomNavigation(),
        ),
      ],
    );
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
