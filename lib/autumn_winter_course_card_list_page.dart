import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'components/course_card.dart';

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
      final snapshot =
          await FirebaseFirestore.instance.collection('course_data').get();
      final List<Map<String, dynamic>> courses = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('data') &&
            data['data'] is Map &&
            data['data']['courses'] is List) {
          final List<dynamic> courseList = data['data']['courses'];
          for (final course in courseList) {
            if (course is Map<String, dynamic>) {
              final lectureName = course['lectureName'] ?? course['name'] ?? '';
              final teacherName =
                  course['teacherName'] ??
                  course['instructor'] ??
                  course['teacher'] ??
                  '';
              final period = course['period'] ?? '';
              final courseId = '$lectureName|$teacherName|$period';
              courses.add({
                ...course,
                'courseId': courseId,
                'lectureName': lectureName,
                'teacherName': teacherName,
                'avgSatisfaction': 0.0,
                'avgEasiness': 0.0,
                'reviewCount': 0,
                'hasMyReview': false,
              });
            }
          }
        }
      }
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading autumn/winter courses: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('秋冬学期の授業一覧'),
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
