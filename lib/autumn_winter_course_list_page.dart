import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'credit_input_page.dart';
import 'credit_review_page.dart';
import 'autumn_winter_course_detail_page.dart';

class AutumnWinterCourseListPage extends StatefulWidget {
  final String category;

  const AutumnWinterCourseListPage({super.key, required this.category});

  @override
  State<AutumnWinterCourseListPage> createState() =>
      _AutumnWinterCourseListPageState();
}

class _AutumnWinterCourseListPageState
    extends State<AutumnWinterCourseListPage> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _fetchAutumnWinterCourses();
  }

  // course_dataコレクションからcategory一致の授業を全て取得（category名の前後空白や全角半角違いも無視）
  Future<List<Map<String, dynamic>>> _fetchAutumnWinterCourses() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('course_data').get();
      final List<Map<String, dynamic>> allCourses = [];
      final normalizedTarget = _normalizeCategory(widget.category);

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('data') &&
            data['data'] is Map &&
            data['data']['courses'] is List) {
          final List<dynamic> courses = data['data']['courses'];
          for (final course in courses) {
            if (course is Map<String, dynamic>) {
              final category = course['category'] ?? '';
              if (_normalizeCategory(category) == normalizedTarget) {
                allCourses.add(course);
              }
            }
          }
        }
      }
      return allCourses;
    } catch (e) {
      print('Error fetching autumn/winter courses: $e');
      return [];
    }
  }

  // カテゴリ名の正規化（前後空白除去・全角半角統一）
  String _normalizeCategory(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[\u3000\s]+'), '')
        .replaceAll('ｰ', 'ー');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} - 秋冬学期'),
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
                  '秋冬学期の授業データがありません',
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
                final lectureName =
                    course['lectureName'] ?? course['name'] ?? '';
                final teacherName =
                    course['teacherName'] ??
                    course['instructor'] ??
                    course['teacher'] ??
                    '';
                final semester = course['semester'] ?? '';
                final code = course['code'] ?? '';

                print(
                  'DEBUG: 秋冬学期授業カード - 授業: $lectureName, 教員: $teacherName, code: $code',
                );

                return _AutumnWinterCourseCard(
                  lectureName: lectureName,
                  teacherName: teacherName,
                  semester: semester,
                  category: widget.category,
                  code: code,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AutumnWinterCourseDetailPage(
                              lectureName: lectureName,
                              teacherName: teacherName,
                              code: code,
                              category: widget.category,
                              semester: semester,
                            ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AutumnWinterCourseCard extends StatefulWidget {
  final String lectureName;
  final String teacherName;
  final String semester;
  final String category;
  final String code;
  final VoidCallback? onTap;

  const _AutumnWinterCourseCard({
    required this.lectureName,
    required this.teacherName,
    required this.semester,
    required this.category,
    required this.code,
    this.onTap,
  });

  @override
  State<_AutumnWinterCourseCard> createState() =>
      _AutumnWinterCourseCardState();
}

class _AutumnWinterCourseCardState extends State<_AutumnWinterCourseCard> {
  double avgSatisfaction = 0.0;
  double avgEasiness = 0.0;
  int reviewCount = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _allReviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviewStats();
    _fetchAllReviews();
  }

  Future<void> _fetchReviewStats() async {
    try {
      if (widget.code.isEmpty) return;
      final query =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('code', isEqualTo: widget.code)
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
        final data = doc.data() as Map<String, dynamic>?;
        sumSatisfaction += (data?['overallSatisfaction'] ?? 0.0) * 1.0;
        sumEasiness += (data?['easiness'] ?? 0.0) * 1.0;
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

  Future<void> _fetchAllReviews() async {
    try {
      if (widget.code.isEmpty) return;
      final query =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('code', isEqualTo: widget.code)
              .orderBy('createdAt', descending: true)
              .get();
      setState(() {
        _allReviews =
            query.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
      });
    } catch (e) {
      print('Error fetching all reviews: $e');
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
        onTap: widget.onTap,
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
              const SizedBox(height: 16),
              if (_allReviews.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'みんなのレビュー',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._allReviews.map(
                      (review) => FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(review['userId'] as String)
                                .get(),
                        builder: (context, userSnapshot) {
                          String? characterImage;
                          if (userSnapshot.hasData &&
                              userSnapshot.data != null) {
                            final data =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                            characterImage = data?['characterImage'] as String?;
                          }
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            color: Colors.cyan[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[200],
                                    ),
                                    child:
                                        characterImage != null
                                            ? Image.asset(
                                              characterImage,
                                              fit: BoxFit.cover,
                                            )
                                            : Image.asset(
                                              'assets/character_gorilla.png',
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  (review['overallSatisfaction'] ??
                                                          0.0)
                                                      .toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Colors.deepOrange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              review['createdAt'] != null &&
                                                      review['createdAt']
                                                          is Timestamp
                                                  ? (review['createdAt']
                                                          as Timestamp)
                                                      .toDate()
                                                      .toString()
                                                      .split(' ')[0]
                                                  : '',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '形式: ${review['lectureFormat'] ?? ''}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          '出席: ${review['attendanceStrictness'] ?? ''}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          '試験: ${review['examType'] ?? ''}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          '教員特徴: ${review['teacherFeature'] ?? ''}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'コメント: ${review['comment'] ?? ''}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        if (review['tags'] != null &&
                                            review['tags'] is List)
                                          Wrap(
                                            spacing: 6.0,
                                            children:
                                                (review['tags'] as List)
                                                    .map<Widget>(
                                                      (tag) => Chip(
                                                        label: Text(
                                                          tag.toString(),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                        backgroundColor:
                                                            Colors.cyan[100],
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AutumnWinterCourseDetailPage(
                                  lectureName: widget.lectureName,
                                  teacherName: widget.teacherName,
                                  code: widget.code,
                                  category: widget.category,
                                  semester: widget.semester,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.rate_review, color: Colors.white),
                      label: const Text(
                        'レビューを見る',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CreditInputPage(
                                  lectureName: widget.lectureName,
                                  teacherName: widget.teacherName,
                                  code: widget.code,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        'レビューを書く',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
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
