import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'credit_review_page.dart';
import 'components/course_card.dart';
import 'providers/timetable_provider.dart';
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用

class AutumnWinterCourseCardListPage extends ConsumerStatefulWidget {
  const AutumnWinterCourseCardListPage({super.key});

  @override
  ConsumerState<AutumnWinterCourseCardListPage> createState() =>
      _AutumnWinterCourseCardListPageState();
}

class _AutumnWinterCourseCardListPageState
    extends ConsumerState<AutumnWinterCourseCardListPage> {
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAutumnWinterCourses();
  }

  // 秋冬学期の授業データを読み込む
  Future<void> _loadAutumnWinterCourses() async {
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
      print('Error loading autumn/winter courses: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topOffset =
        kToolbarHeight + MediaQuery.of(context).padding.top;
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
                  title: const Text('秋冬学期の授業一覧'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.white,
                ),
              ),
              // ListView（AppBarの下から画面の一番下まで）
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
                            return Align(
                              alignment: Alignment.center,
                              child: FractionallySizedBox(
                                widthFactor: 0.80,
                                child: CourseCard(
                                  course: _courses[index],
                                  onTeacherNameChanged: (newTeacherName) {
                                    _updateTeacherName(
                                      _courses[index]['courseId'],
                                      newTeacherName,
                                    );
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
          _courses[i]['teacherName'] = newTeacherName;
          break;
        }
      }
    });

    // TODO: 必要に応じてFirestoreにも保存
    print('Updated teacher name for $courseId to: $newTeacherName');
  }
}
