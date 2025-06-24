import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'credit_input_page.dart';

class CurrentSemesterReviewsPage extends StatefulWidget {
  const CurrentSemesterReviewsPage({super.key});

  @override
  State<CurrentSemesterReviewsPage> createState() =>
      _CurrentSemesterReviewsPageState();
}

class _CurrentSemesterReviewsPageState
    extends State<CurrentSemesterReviewsPage> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _fetchCurrentSemesterCourses();
  }

  // 今学期（春夏学期）のcourseIdを持つ全ての授業を取得
  Future<List<Map<String, dynamic>>> _fetchCurrentSemesterCourses() async {
    try {
      // reviewsコレクションから今学期のcourseIdを取得
      final reviewsSnapshot =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('semester', whereIn: ['春', '夏', '春～夏'])
              .get();

      // courseIdの重複を除去
      final Set<String> courseIds = {};
      for (final doc in reviewsSnapshot.docs) {
        final data = doc.data();
        if (data['courseId'] != null) {
          courseIds.add(data['courseId']);
        }
      }

      // courseIdを持つ授業情報を取得
      final List<Map<String, dynamic>> courses = [];
      for (final courseId in courseIds) {
        final courseDoc =
            await FirebaseFirestore.instance
                .collection('courses')
                .doc(courseId)
                .get();

        if (courseDoc.exists) {
          final courseData = courseDoc.data()!;
          courses.add({
            'courseId': courseId,
            'lectureName':
                courseData['lectureName'] ?? courseData['name'] ?? '',
            'teacherName':
                courseData['teacherName'] ??
                courseData['instructor'] ??
                courseData['teacher'] ??
                '',
            'semester': courseData['semester'] ?? '',
            'category': courseData['category'] ?? '',
          });
        }
      }

      return courses;
    } catch (e) {
      print('Error fetching current semester courses: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今学期の履修レビュー'),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  '今学期の履修データがありません',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            final courses = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _CurrentSemesterCourseCard(
                  courseId: course['courseId'],
                  lectureName: course['lectureName'],
                  teacherName: course['teacherName'],
                  semester: course['semester'],
                  category: course['category'],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CurrentSemesterCourseCard extends StatefulWidget {
  final String courseId;
  final String lectureName;
  final String teacherName;
  final String semester;
  final String category;

  const _CurrentSemesterCourseCard({
    required this.courseId,
    required this.lectureName,
    required this.teacherName,
    required this.semester,
    required this.category,
  });

  @override
  State<_CurrentSemesterCourseCard> createState() =>
      _CurrentSemesterCourseCardState();
}

class _CurrentSemesterCourseCardState
    extends State<_CurrentSemesterCourseCard> {
  double avgSatisfaction = 0.0;
  double avgEasiness = 0.0;
  int reviewCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviewStats();
  }

  Future<void> _fetchReviewStats() async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('courseId', isEqualTo: widget.courseId)
              .get();

      final docs = query.docs;
      if (docs.isEmpty) {
        setState(() {
          avgSatisfaction = 0.0;
          avgEasiness = 0.0;
          reviewCount = 0;
          _loading = false;
        });
        return;
      }

      double sumSatisfaction = 0.0;
      double sumEasiness = 0.0;
      for (final doc in docs) {
        final data = doc.data();
        sumSatisfaction += (data['overallSatisfaction'] ?? 0.0) * 1.0;
        sumEasiness += (data['easiness'] ?? 0.0) * 1.0;
      }

      setState(() {
        avgSatisfaction = sumSatisfaction / docs.length;
        avgEasiness = sumEasiness / docs.length;
        reviewCount = docs.length;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching review stats: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      elevation: 8.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.indigo[200]!, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreditInputPage(
                    lectureName: widget.lectureName,
                    teacherName: widget.teacherName,
                    courseId: widget.courseId,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book, color: Colors.indigo[700], size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.lectureName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.grey[700], size: 18),
                  const SizedBox(width: 6),
                  Text(
                    widget.teacherName,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.category, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.category} (${widget.semester})',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            avgSatisfaction.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('満足度', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.sentiment_satisfied,
                            color: Colors.green,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            avgEasiness.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('楽単度', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.rate_review,
                            color: Colors.blueGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$reviewCount件',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
