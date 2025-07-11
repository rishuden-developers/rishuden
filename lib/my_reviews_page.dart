import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // StreamSubscriptionのためにインポート
import 'credit_input_page.dart'; // ★ 遷移先として追加
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用
import 'main_page.dart';
import 'providers/current_page_provider.dart';
import 'providers/background_image_provider.dart';

// ページの状態で使用するデータモデル
class MyCourseReviewModel {
  final String subjectName;
  final String teacherName;
  final String courseId;
  double avgSatisfaction;
  double avgEasiness;
  int reviewCount;

  MyCourseReviewModel({
    required this.subjectName,
    required this.teacherName,
    required this.courseId,
    this.avgSatisfaction = 0.0,
    this.avgEasiness = 0.0,
    this.reviewCount = 0,
  });
}

class MyReviewsPage extends ConsumerStatefulWidget {
  const MyReviewsPage({super.key});

  @override
  ConsumerState<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends ConsumerState<MyReviewsPage> {
  List<MyCourseReviewModel> _myCourses = [];
  bool _isLoading = true;
  StreamSubscription? _reviewsSubscription;

  @override
  void initState() {
    super.initState();
    _loadAndSubscribeToMyCourses();
  }

  @override
  void dispose() {
    _reviewsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAndSubscribeToMyCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _myCourses = [];
        _isLoading = false;
      });
      return;
    }

    // reviewsコレクションから全ユーザーのレビューを全件取得
    final query = await FirebaseFirestore.instance.collection('reviews').get();
    final allReviews =
        query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    // 履修情報を取得
    final timetableDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('timetable')
            .doc('notes')
            .get();
    final timetableData = timetableDoc.data();
    final userCourseIds = Map<String, String>.from(
      timetableData?['courseIds'] ?? {},
    );
    final userTeacherNames = Map<String, String>.from(
      timetableData?['teacherNames'] ?? {},
    );

    // 各授業ごとに全ユーザーのレビューを集計
    final courses = <MyCourseReviewModel>[];
    for (var entry in userCourseIds.entries) {
      final subjectName = entry.key;
      final courseId = entry.value;
      final teacherName = userTeacherNames[courseId] ?? '';
      final reviewsForCourse =
          allReviews
              .where(
                (r) =>
                    (r['courseId'] ?? '').toString().trim() ==
                    courseId.toString().trim(),
              )
              .toList();
      double avgSatisfaction = 0.0;
      double avgEasiness = 0.0;
      if (reviewsForCourse.isNotEmpty) {
        avgSatisfaction =
            reviewsForCourse
                .map((r) => (r['overallSatisfaction'] ?? 0.0) * 1.0)
                .reduce((a, b) => a + b) /
            reviewsForCourse.length;
        avgEasiness =
            reviewsForCourse
                .map((r) => (r['easiness'] ?? 0.0) * 1.0)
                .reduce((a, b) => a + b) /
            reviewsForCourse.length;
      }
      courses.add(
        MyCourseReviewModel(
          subjectName: subjectName,
          teacherName: teacherName,
          courseId: courseId,
          avgSatisfaction: avgSatisfaction,
          avgEasiness: avgEasiness,
          reviewCount: reviewsForCourse.length,
        ),
      );
    }
    setState(() {
      _myCourses = courses;
      _isLoading = false;
    });
  }

  void _subscribeToReviews() {
    _reviewsSubscription?.cancel();
    _reviewsSubscription = FirebaseFirestore.instance
        .collection('reviews')
        .snapshots()
        .listen((snapshot) {
          final Map<String, List<DocumentSnapshot>> reviewsByCourseId = {};
          for (var doc in snapshot.docs) {
            final courseId = doc.data()['courseId'] as String?;
            if (courseId != null) {
              reviewsByCourseId.putIfAbsent(courseId, () => []).add(doc);
            }
          }

          final updatedCourses = List<MyCourseReviewModel>.from(_myCourses);
          for (var course in updatedCourses) {
            final reviews = reviewsByCourseId[course.courseId] ?? [];
            if (reviews.isNotEmpty) {
              course.reviewCount = reviews.length;
              course.avgSatisfaction =
                  reviews
                      .map(
                        (r) =>
                            (r.data()
                                    as Map<
                                      String,
                                      dynamic
                                    >)['overallSatisfaction']
                                as num,
                      )
                      .reduce((a, b) => a + b) /
                  reviews.length;
              course.avgEasiness =
                  reviews
                      .map(
                        (r) =>
                            (r.data() as Map<String, dynamic>)['easiness']
                                as num,
                      )
                      .reduce((a, b) => a + b) /
                  reviews.length;
            } else {
              course.reviewCount = 0;
              course.avgSatisfaction = 0.0;
              course.avgEasiness = 0.0;
            }
          }

          if (mounted) {
            setState(() => _myCourses = updatedCourses);
          }
        });
  }

  Widget _buildResultCard(MyCourseReviewModel result) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreditInputPage(
                    courseId: result.courseId,
                    lectureName: result.subjectName,
                    teacherName: result.teacherName,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.subjectName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.teacherName,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '満足度: ${result.avgSatisfaction.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.sentiment_satisfied,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '楽単度: ${result.avgEasiness.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'レビュー数: ${result.reviewCount}件',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topOffset =
        kToolbarHeight + MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            ref.watch(backgroundImagePathProvider),
            fit: BoxFit.cover,
          ),
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
                  title: const Text('自分の授業をレビュー'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
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
                        : _myCourses.isEmpty
                        ? const Center(
                          child: Text(
                            '時間割に授業が登録されていません。',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                        : ListView.builder(
                          physics: ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _myCourses.length,
                          itemBuilder: (context, index) {
                            final course = _myCourses[index];
                            return _buildResultCard(course);
                          },
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
}
