import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'components/course_card.dart';
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用

class AutumnWinterCourseCardListPage extends StatefulWidget {
  const AutumnWinterCourseCardListPage({super.key});

  @override
  State<AutumnWinterCourseCardListPage> createState() =>
      _AutumnWinterCourseCardListPageState();
}

class _AutumnWinterCourseCardListPageState
    extends State<AutumnWinterCourseCardListPage> {
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
      print('Error loading autumn/winter courses: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('秋冬学期の授業一覧'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/night_view.png'),
            fit: BoxFit.cover,
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: 95.0,
                    top: kToolbarHeight + 24,
                  ),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    return CourseCard(course: _courses[index]);
                  },
                ),
      ),
      bottomNavigationBar: const CommonBottomNavigation(),
    );
  }
}
