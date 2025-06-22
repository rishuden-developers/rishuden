import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'providers/timetable_provider.dart';
import 'providers/global_course_mapping_provider.dart';
import 'providers/global_review_mapping_provider.dart';

// ページの状態で使用するデータモデル
class MyCourseReviewModel {
  final String subjectName;
  final String courseId;
  final TextEditingController teacherNameController;
  final TextEditingController commentController;
  double rating;
  bool isSaving;

  MyCourseReviewModel({
    required this.subjectName,
    required this.courseId,
    required String initialTeacherName,
    required this.rating,
    required String initialComment,
    this.isSaving = false,
  }) : teacherNameController = TextEditingController(text: initialTeacherName),
       commentController = TextEditingController(text: initialComment);
}

class MyReviewsPage extends ConsumerStatefulWidget {
  const MyReviewsPage({super.key});

  @override
  ConsumerState<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends ConsumerState<MyReviewsPage> {
  List<MyCourseReviewModel> _myCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyCourses();
    });
  }

  Future<void> _loadMyCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final courseMapping = ref.read(globalCourseMappingProvider);
    final teacherNames =
        ref.read(timetableProvider)['teacherNames'] as Map<String, String>? ??
        {};
    final user = FirebaseAuth.instance.currentUser;

    final courses = <MyCourseReviewModel>[];
    for (var entry in courseMapping.entries) {
      final subjectName = entry.key;
      final courseId = entry.value;
      final teacherName = teacherNames[courseId] ?? '';

      // 既存のレビュー情報を取得
      String reviewId = '';
      if (teacherName.isNotEmpty) {
        reviewId = ref
            .read(globalReviewMappingProvider.notifier)
            .getOrCreateReviewId(subjectName, teacherName);
      }

      double currentRating = 3.0;
      String currentComment = '';

      if (reviewId.isNotEmpty && user != null) {
        final reviewSnapshot =
            await FirebaseFirestore.instance
                .collection('reviews')
                .where('reviewId', isEqualTo: reviewId)
                .where('userId', isEqualTo: user.uid)
                .limit(1)
                .get();

        if (reviewSnapshot.docs.isNotEmpty) {
          final reviewData = reviewSnapshot.docs.first.data();
          currentRating =
              (reviewData['overallSatisfaction'] as num? ?? 3.0).toDouble();
          currentComment = reviewData['comment'] as String? ?? '';
        }
      }

      courses.add(
        MyCourseReviewModel(
          subjectName: subjectName,
          courseId: courseId,
          initialTeacherName: teacherName,
          rating: currentRating,
          initialComment: currentComment,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _myCourses = courses;
      _isLoading = false;
    });
  }

  Future<void> _saveReview(MyCourseReviewModel course) async {
    if (!mounted) return;
    setState(() => course.isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ログインしていません。')));
      setState(() => course.isSaving = false);
      return;
    }

    final teacherName = course.teacherNameController.text.trim();
    if (teacherName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('教員名を入力してください。')));
      setState(() => course.isSaving = false);
      return;
    }

    try {
      // 教員名をTimetableProviderに保存
      ref
          .read(timetableProvider.notifier)
          .setTeacherName(course.courseId, teacherName);

      // reviewIdを取得または生成
      final reviewId = ref
          .read(globalReviewMappingProvider.notifier)
          .getOrCreateReviewId(course.subjectName, teacherName);

      // Firestoreで既存のレビューを検索
      final reviewQuery = FirebaseFirestore.instance
          .collection('reviews')
          .where('reviewId', isEqualTo: reviewId)
          .where('userId', isEqualTo: user.uid)
          .limit(1);

      final existingReviews = await reviewQuery.get();

      final reviewData = {
        'lectureName': course.subjectName,
        'teacherName': teacherName,
        'reviewId': reviewId,
        'userId': user.uid,
        'overallSatisfaction': course.rating,
        'comment': course.commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (existingReviews.docs.isEmpty) {
        // 新規作成
        await FirebaseFirestore.instance.collection('reviews').add(reviewData);
      } else {
        // 更新
        await existingReviews.docs.first.reference.update(reviewData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${course.subjectName} のレビューを保存しました。')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラー: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => course.isSaving = false);
      }
    }
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
                : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _myCourses.length,
                  itemBuilder: (context, index) {
                    final course = _myCourses[index];
                    return _buildCourseReviewCard(course);
                  },
                ),
      ),
    );
  }

  Widget _buildCourseReviewCard(MyCourseReviewModel course) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.subjectName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: course.teacherNameController,
              decoration: const InputDecoration(
                labelText: '教員名',
                border: OutlineInputBorder(),
                hintText: '教員名を入力してください',
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontFamily: 'NotoSansJP'),
            ),
            const SizedBox(height: 16),
            const Text(
              '総合満足度',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: RatingBar.builder(
                initialRating: course.rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder:
                    (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  setState(() {
                    course.rating = rating;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: course.commentController,
              decoration: const InputDecoration(
                labelText: 'レビューコメント',
                border: OutlineInputBorder(),
                hintText: '授業の感想などを入力してください',
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'NotoSansJP'),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: course.isSaving ? null : () => _saveReview(course),
                icon:
                    course.isSaving
                        ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Icon(Icons.save),
                label: const Text('保存'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
