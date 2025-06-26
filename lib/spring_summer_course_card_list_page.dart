import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'components/course_card.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('春夏学期の授業一覧'),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
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
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    return CourseCard(course: _courses[index]);
                  },
                ),
      ),
    );
  }
}
