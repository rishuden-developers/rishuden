import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // StreamSubscriptionのためにインポート

import 'providers/timetable_provider.dart';
import 'providers/global_course_mapping_provider.dart';
import 'providers/global_review_mapping_provider.dart';
import 'credit_input_page.dart'; // ★ 遷移先として追加

// ページの状態で使用するデータモデル
class MyCourseReviewModel {
  final String subjectName;
  final String teacherName;
  final String reviewId;
  double avgSatisfaction;
  double avgEasiness;
  int reviewCount;

  MyCourseReviewModel({
    required this.subjectName,
    required this.teacherName,
    required this.reviewId,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndSubscribeToMyCourses();
    });
  }

  @override
  void dispose() {
    _reviewsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAndSubscribeToMyCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final courseMapping = ref.read(globalCourseMappingProvider);
    final teacherNames =
        ref.read(timetableProvider)['teacherNames'] as Map<String, String>? ??
        {};
    final reviewMapping = ref.read(globalReviewMappingProvider);

    final courses = <MyCourseReviewModel>[];
    for (var entry in courseMapping.entries) {
      final subjectName = entry.key;
      final teacherName = teacherNames[entry.value] ?? '';
      final reviewId = reviewMapping[subjectName] ?? '';

      courses.add(
        MyCourseReviewModel(
          subjectName: subjectName,
          teacherName: teacherName,
          reviewId: reviewId,
        ),
      );
    }
    _myCourses = courses;

    _subscribeToReviews();
    setState(() => _isLoading = false);
  }

  void _subscribeToReviews() {
    _reviewsSubscription?.cancel();
    _reviewsSubscription = FirebaseFirestore.instance
        .collection('reviews')
        .snapshots()
        .listen((snapshot) {
          final Map<String, List<DocumentSnapshot>> reviewsByReviewId = {};
          for (var doc in snapshot.docs) {
            final reviewId = doc.data()['reviewId'] as String?;
            if (reviewId != null) {
              reviewsByReviewId.putIfAbsent(reviewId, () => []).add(doc);
            }
          }

          final updatedCourses = List<MyCourseReviewModel>.from(_myCourses);
          for (var course in updatedCourses) {
            final reviews = reviewsByReviewId[course.reviewId] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自分の授業をレビュー'),
        backgroundColor: Colors.indigo[800],
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
                : _myCourses.isEmpty
                ? const Center(
                  child: Text(
                    '時間割に授業が登録されていません。',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _myCourses.length,
                  itemBuilder: (context, index) {
                    final course = _myCourses[index];
                    return _buildResultCard(course);
                  },
                ),
      ),
    );
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
}
