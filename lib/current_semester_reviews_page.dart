import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'credit_input_page.dart';
import 'character_data.dart';
import 'credit_review_page.dart';
import 'components/course_card.dart';
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用

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

  Future<List<Map<String, dynamic>>> _fetchCurrentSemesterCourses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in');
        return [];
      }

      print('Fetching courses for user: ${user.uid}');

      // ユーザーの時間割からcourseIdを取得
      final userCourses = <String>{};
      try {
        final timetableNotesDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('timetable')
                .doc('notes')
                .get();

        print('Timetable notes doc exists: ${timetableNotesDoc.exists}');

        if (timetableNotesDoc.exists) {
          final data = timetableNotesDoc.data()!;
          print('Timetable notes data keys: ${data.keys}');
          final courseIds = data['courseIds'] as Map<String, dynamic>? ?? {};
          print('Found ${courseIds.length} courseIds');

          for (var entry in courseIds.entries) {
            final courseId = entry.value as String?;
            if (courseId != null && courseId.isNotEmpty) {
              userCourses.add(courseId);
              print('Added courseId: $courseId');
            } else {
              print('Entry ${entry.key} has no courseId or empty courseId');
            }
          }
        } else {
          print('Timetable notes document does not exist');
        }
      } catch (e) {
        print('Error fetching user timetable notes: $e');
      }

      print('User courses from timetable: $userCourses');

      // 各授業の情報とレビュー統計を取得
      final List<Map<String, dynamic>> courses = [];

      for (final courseId in userCourses) {
        try {
          // courseIdから講義名と教員名を抽出
          final parts = courseId.split('|');
          final lectureName = parts.isNotEmpty ? parts[0] : courseId;
          final teacherName = parts.length > 1 ? parts[1] : '';

          // その授業のレビューを取得（courseIdで検索）
          final reviewsSnapshot =
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .where('courseId', isEqualTo: courseId)
                  .get();

          final allReviews = <Map<String, dynamic>>[];
          final Set<String> addedReviewIds = <String>{};

          // courseIdで取得したレビューを追加
          for (final doc in reviewsSnapshot.docs) {
            final data = doc.data();
            data['reviewId'] = doc.id; // reviewIdを追加
            allReviews.add(data);
            addedReviewIds.add(doc.id);
          }

          // ユーザーが投稿したレビューで、まだ追加されていないものを取得
          // courseIdが設定されていない場合のフォールバック
          final userReviewsSnapshot =
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .where('userId', isEqualTo: user.uid)
                  .where('lectureName', isEqualTo: lectureName)
                  .get();

          // 重複していないレビューのみを追加
          for (final doc in userReviewsSnapshot.docs) {
            if (!addedReviewIds.contains(doc.id)) {
              final data = doc.data();
              data['reviewId'] = doc.id; // reviewIdを追加
              allReviews.add(data);
              addedReviewIds.add(doc.id);
            }
          }

          // レビュー統計を計算
          double avgSatisfaction = 0.0;
          double avgEasiness = 0.0;
          int reviewCount = allReviews.length;
          bool hasMyReview = false;

          if (allReviews.isNotEmpty) {
            double totalSatisfaction = 0.0;
            double totalEasiness = 0.0;

            for (final review in allReviews) {
              final satisfaction =
                  (review['overallSatisfaction'] ??
                      review['satisfaction'] ??
                      0.0) *
                  1.0;
              final easiness =
                  (review['easiness'] ?? review['ease'] ?? 0.0) * 1.0;
              totalSatisfaction += satisfaction;
              totalEasiness += easiness;

              // 自分のレビューがあるかチェック
              if (review['userId'] == user.uid) {
                hasMyReview = true;
              }
            }

            avgSatisfaction = totalSatisfaction / allReviews.length;
            avgEasiness = totalEasiness / allReviews.length;
          }

          courses.add({
            'courseId': courseId,
            'lectureName': lectureName,
            'teacherName': teacherName,
            'avgSatisfaction': avgSatisfaction,
            'avgEasiness': avgEasiness,
            'reviewCount': reviewCount,
            'hasMyReview': hasMyReview,
          });

          print(
            'Added course: $lectureName with $reviewCount reviews (unique)',
          );
        } catch (e) {
          print('Error processing course $courseId: $e');
        }
      }

      print('Processed ${courses.length} courses');
      return courses;
    } catch (e) {
      print('Error fetching current semester courses: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('今学期の履修授業'),
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
                  '今学期の履修授業がありません',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }
            final courses = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 95.0,
                top: kToolbarHeight + 24,
                left: 16.0,
                right: 16.0,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                return CourseCard(course: courses[index]);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigation(),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          print('遷移時のcourseId: \\${course['courseId']}');
          // 授業詳細画面に遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreditReviewPage(
                    lectureName: course['lectureName'],
                    teacherName: course['teacherName'],
                    courseId: course['courseId'], // courseIdに統一
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 授業名と教員名
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['lectureName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course['teacherName'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // レビュー投稿済みバッジ
                  if (course['hasMyReview'])
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '投稿済み',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 評価統計
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRatingItem(
                    '満足度',
                    course['avgSatisfaction'].toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildRatingItem(
                    '楽単度',
                    course['avgEasiness'].toStringAsFixed(1),
                    Icons.sentiment_satisfied,
                    Colors.green,
                  ),
                  _buildRatingItem(
                    'レビュー数',
                    '${course['reviewCount']}件',
                    Icons.comment,
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
