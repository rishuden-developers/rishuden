// current_semester_reviews_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'credit_review_page.dart';
import 'common_bottom_navigation.dart';

class CurrentSemesterReviewsPage extends ConsumerStatefulWidget {
  const CurrentSemesterReviewsPage({super.key});

  @override
  ConsumerState<CurrentSemesterReviewsPage> createState() =>
      _CurrentSemesterReviewsPageState();
}

class _CurrentSemesterReviewsPageState
    extends ConsumerState<CurrentSemesterReviewsPage> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _fetchCurrentSemesterCourses();
  }

  Future<void> _reload() async {
    setState(() {
      _coursesFuture = _fetchCurrentSemesterCourses();
    });
    await _coursesFuture;
  }

  Future<List<Map<String, dynamic>>> _fetchCurrentSemesterCourses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // ユーザーの時間割から courseId を取得
      final userCourses = <String>{};
      try {
        final notes =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('timetable')
                .doc('notes')
                .get();
        final courseIds =
            (notes.data()?['courseIds'] as Map<String, dynamic>?) ?? {};
        for (final e in courseIds.entries) {
          final id = e.value as String?;
          if (id != null && id.isNotEmpty) userCourses.add(id);
        }
      } catch (_) {}

      // 各授業のレビュー統計
      final List<Map<String, dynamic>> courses = [];
      for (final courseId in userCourses) {
        try {
          final lectureName = courseId.split('|').first;
          final reviewsSnap =
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .where('courseId', isEqualTo: courseId)
                  .get();

          final all = <Map<String, dynamic>>[];
          final added = <String>{};
          for (final d in reviewsSnap.docs) {
            final data = d.data();
            data['reviewId'] = d.id;
            all.add(data);
            added.add(d.id);
          }

          // フォールバック：ユーザー自身の lectureName 一致
          final userSnap =
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .where('userId', isEqualTo: user.uid)
                  .where('lectureName', isEqualTo: lectureName)
                  .get();
          for (final d in userSnap.docs) {
            if (!added.contains(d.id)) {
              final data = d.data();
              data['reviewId'] = d.id;
              all.add(data);
              added.add(d.id);
            }
          }

          double sat = 0, ease = 0;
          var my = false;
          for (final r in all) {
            sat +=
                (r['overallSatisfaction'] ?? r['satisfaction'] ?? 0).toDouble();
            ease += (r['easiness'] ?? r['ease'] ?? 0).toDouble();
            if (r['userId'] == user.uid) my = true;
          }

          courses.add({
            'courseId': courseId,
            'lectureName': lectureName,
            'teacherName': '', // 必要なら Course コレクションから取得に拡張
            'avgSatisfaction': all.isEmpty ? 0.0 : sat / all.length,
            'avgEasiness': all.isEmpty ? 0.0 : ease / all.length,
            'reviewCount': all.length,
            'hasMyReview': my,
          });
        } catch (_) {}
      }
      return courses;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // カラーパレット（ホーム画像と同系）
    const mainBlue = Color(0xFF2E6DB6);
    final bg = Colors.grey[100];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('今学期の履修授業'),
        centerTitle: true,
        backgroundColor: mainBlue,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final courses = snapshot.data ?? [];
            if (courses.isEmpty) {
              return const _EmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: courses.length,
              itemBuilder: (_, i) => _CourseTileSimple(course: courses[i]),
            );
          },
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigation(),
    );
  }
}

/// ====== シンプルUIのカード ======
class _CourseTileSimple extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseTileSimple({required this.course});

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF2E6DB6);
    final chipColor =
        course['hasMyReview'] == true
            ? Colors.green.shade100
            : Colors.transparent;
    final chipTextColor =
        course['hasMyReview'] == true ? Colors.green : Colors.grey;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => CreditReviewPage(
                  lectureName: course['lectureName'],
                  teacherName: course['teacherName'] ?? '',
                  courseId: course['courseId'],
                ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上段：タイトル＋チップ
            Row(
              children: [
                Expanded(
                  child: Text(
                    course['lectureName'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (course['hasMyReview'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '投稿済み',
                      style: TextStyle(
                        color: chipTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              course['teacherName']?.toString().isNotEmpty == true
                  ? course['teacherName']
                  : '担当未設定',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // 指標（満足度/楽単度/レビュー数）
            Row(
              children: [
                _Metric(
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  value: (course['avgSatisfaction'] as double).toStringAsFixed(
                    1,
                  ),
                  label: '満足度',
                ),
                const SizedBox(width: 14),
                _Metric(
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  color: Colors.teal,
                  value: (course['avgEasiness'] as double).toStringAsFixed(1),
                  label: '楽単度',
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.comment_rounded,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${course['reviewCount']}件',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 右下に矢印
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.chevron_right_rounded, color: blue),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _Metric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2E6DB6);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              '今学期の履修授業がありません',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('戻る', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
