import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      var courses = <Map<String, dynamic>>[];

      // course_dataコレクションから全授業を取得
      final snapshot =
          await FirebaseFirestore.instance.collection('course_data').get();

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
              final classroom = course['classroom'] ?? course['room'] ?? '';
              final category = course['category'] ?? '';
              final semester = course['semester'] ?? '';

              // 教員名をtimetableProviderから取得（時間割画面と同期）
              String finalTeacherName = teacherName;
              if (lectureName.isNotEmpty) {
                final timetableTeacherName =
                    ref.read(timetableProvider)['teacherNames']?[lectureName];
                if (timetableTeacherName != null &&
                    timetableTeacherName.isNotEmpty) {
                  finalTeacherName = timetableTeacherName;
                }
              }

              courses.add({
                'lectureName': lectureName,
                'teacherName': finalTeacherName,
                'classroom': classroom,
                'category': category,
                'semester': semester,
                'avgSatisfaction': 0.0,
                'avgEasiness': 0.0,
                'reviewCount': 0,
                'hasMyReview': false,
              });
            }
          }
        }
      }

      // 各授業のレビュー情報を取得（lectureNameとteacherNameで検索）
      for (int i = 0; i < courses.length; i++) {
        final lectureName = courses[i]['lectureName'];
        final teacherName = courses[i]['teacherName'];

        try {
          final reviewsSnapshot =
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .where('lectureName', isEqualTo: lectureName)
                  .where('teacherName', isEqualTo: teacherName)
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
          print('Error fetching reviews for $lectureName ($teacherName): $e');
        }
      }

      setState(() {
        _courses = courses;
        _isLoading = false;
      });

      print('Loaded ${courses.length} courses from course_data');
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
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => CreditReviewPage(
                                                lectureName:
                                                    _courses[index]['lectureName'],
                                                teacherName:
                                                    _courses[index]['teacherName'],
                                                courseId:
                                                    null, // 秋冬学期ではcourseIdは使用しない
                                              ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 授業名
                                          Text(
                                            _courses[index]['lectureName'] ??
                                                '',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // 教室名
                                          if ((_courses[index]['classroom'] ??
                                                  '')
                                              .isNotEmpty)
                                            Text(
                                              '教室: ${_courses[index]['classroom']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),

                                          // 教員名（表示のみ）
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                '教員: ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  (_courses[index]['teacherName'] ??
                                                              '')
                                                          .isNotEmpty
                                                      ? _courses[index]['teacherName']
                                                      : '未設定',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        (_courses[index]['teacherName'] ??
                                                                    '')
                                                                .isNotEmpty
                                                            ? Colors.black
                                                            : Colors.grey[500],
                                                    fontStyle:
                                                        (_courses[index]['teacherName'] ??
                                                                    '')
                                                                .isEmpty
                                                            ? FontStyle.italic
                                                            : FontStyle.normal,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 12),

                                          // レビュー統計
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${(_courses[index]['avgSatisfaction'] ?? 0.0).toStringAsFixed(1)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.sentiment_satisfied,
                                                    color: Colors.green,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${(_courses[index]['avgEasiness'] ?? 0.0).toStringAsFixed(1)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.rate_review,
                                                    color: Colors.blue,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_courses[index]['reviewCount'] ?? 0}件',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue,
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
}
