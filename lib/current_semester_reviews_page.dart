import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'credit_input_page.dart';

class CurrentSemesterReviewsPage extends StatefulWidget {
  const CurrentSemesterReviewsPage({super.key});

  @override
  State<CurrentSemesterReviewsPage> createState() =>
      _CurrentSemesterReviewsPageState();
}

class _CurrentSemesterReviewsPageState
    extends State<CurrentSemesterReviewsPage> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchCurrentSemesterReviews();
  }

  Future<List<Map<String, dynamic>>> _fetchCurrentSemesterReviews() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in');
        return [];
      }

      print('Fetching reviews for user: ${user.uid}');

      // ユーザーの時間割からcourseIdを取得
      final userCourses = <String>{};
      try {
        final timetableDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('timetable')
                .doc('entries')
                .get();

        print('Timetable doc exists: ${timetableDoc.exists}');

        if (timetableDoc.exists) {
          final data = timetableDoc.data()!;
          print('Timetable data keys: ${data.keys}');
          final entries = data['entries'] as List<dynamic>? ?? [];
          print('Found ${entries.length} timetable entries');

          for (int i = 0; i < entries.length; i++) {
            final entry = entries[i];
            print('Entry $i: $entry');
            final courseId = entry['courseId'] as String?;
            if (courseId != null && courseId.isNotEmpty) {
              userCourses.add(courseId);
              print('Added courseId: $courseId');
            } else {
              print('Entry $i has no courseId or empty courseId');
            }
          }
        } else {
          print('Timetable document does not exist');
        }
      } catch (e) {
        print('Error fetching user timetable: $e');
      }

      print('User courses from timetable: $userCourses');

      // courses/{courseId}/reviewsからレビューを取得
      final List<Map<String, dynamic>> reviews = [];

      for (final courseId in userCourses) {
        try {
          final reviewsSnapshot =
              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseId)
                  .collection('reviews')
                  .get();

          print(
            'Found ${reviewsSnapshot.docs.length} reviews for courseId: $courseId',
          );

          for (final doc in reviewsSnapshot.docs) {
            final data = doc.data();
            print('Review (${doc.id}) for courseId $courseId: $data');

            reviews.add({
              'reviewId': doc.id,
              'courseId': courseId,
              'lectureName': data['lectureName'] ?? '',
              'teacherName': data['teacherName'] ?? '',
              'semester': data['semester'] ?? '',
              'category': data['category'] ?? '',
              'overallSatisfaction': data['satisfaction'] ?? 0.0,
              'easiness': data['ease'] ?? 0.0,
              'lectureFormat': data['classFormat'] ?? '',
              'attendanceStrictness': data['attendance'] ?? '',
              'examType': data['examType'] ?? '',
              'teacherFeature':
                  data['teacherTraits'] != null &&
                          (data['teacherTraits'] as List).isNotEmpty
                      ? (data['teacherTraits'] as List).join(', ')
                      : '',
              'comment': data['comment'] ?? '',
              'tags': data['tags'] ?? [],
              'createdAt': data['createdAt'],
              'userId': data['userId'] ?? '',
              'userCharacter': data['userCharacter'] ?? 'adventurer',
              'takoyakiCount': data['takoyakiCount'] ?? 0,
              'likedBy': data['likedBy'] ?? [],
            });
          }
        } catch (e) {
          print('Error fetching reviews for courseId $courseId: $e');
        }
      }

      print('Processed ${reviews.length} reviews for user courses');
      return reviews;
    } catch (e) {
      print('Error fetching current semester reviews: $e');
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
        child: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    '今学期のレビューがありません',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }
              final reviews = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return _ReviewCard(review: reviews[index]);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isLiked = false;
  int _takoyakiCount = 0;
  String _lectureName = '';
  String _teacherName = '';

  @override
  void initState() {
    super.initState();
    _takoyakiCount = widget.review['takoyakiCount'] ?? 0;
    _checkIfLiked();
    _loadLectureInfo();
  }

  Future<void> _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final likedBy = List<String>.from(widget.review['likedBy'] ?? []);
      setState(() {
        _isLiked = likedBy.contains(user.uid);
      });
    }
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final reviewRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.review['reviewId']);

      if (_isLiked) {
        // いいねを削除
        await reviewRef.update({
          'takoyakiCount': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid]),
        });
        setState(() {
          _takoyakiCount--;
          _isLiked = false;
        });
      } else {
        // いいねを追加
        await reviewRef.update({
          'takoyakiCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid]),
        });
        setState(() {
          _takoyakiCount++;
          _isLiked = true;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _loadLectureInfo() async {
    try {
      // まず保存されたデータを確認
      final savedLectureName = widget.review['lectureName'] as String?;
      if (savedLectureName != null && savedLectureName.isNotEmpty) {
        setState(() {
          _lectureName = savedLectureName;
        });
      }
      // グローバル教員名を取得
      final courseId = widget.review['courseId'];
      if (courseId != null && courseId.isNotEmpty) {
        final teacherName = await _getGlobalTeacherName(courseId);
        setState(() {
          _teacherName = teacherName;
        });
      }
    } catch (e) {
      print('Error loading lecture info: $e');
    }
  }

  Future<String> _getGlobalTeacherName(String courseId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .collection('meta')
            .doc('info')
            .get();
    return doc.data()?['teacherName'] ?? '';
  }

  String _getCharacterImagePath(String character) {
    switch (character) {
      case 'swordman':
        return 'assets/character_swordman.png';
      case 'wizard':
        return 'assets/character_wizard.png';
      case 'gorilla':
        return 'assets/character_gorilla.png';
      case 'merchant':
        return 'assets/character_merchant.png';
      case 'god':
        return 'assets/character_god.png';
      case 'takuji':
        return 'assets/character_takuji.png';
      case 'adventurer':
      default:
        return 'assets/character_adventurer.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 8.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.indigo[200]!, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー部分（キャラクター画像 + 授業情報）
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左上のキャラクター画像
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.indigo[300]!, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      _getCharacterImagePath(widget.review['userCharacter']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 授業情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lectureName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _teacherName,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.review['category']} (${widget.review['semester']})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 評価部分
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRatingItem(
                  '満足度',
                  widget.review['overallSatisfaction'].toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                ),
                _buildRatingItem(
                  '楽単度',
                  widget.review['easiness'].toStringAsFixed(1),
                  Icons.sentiment_satisfied,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 詳細情報
            _buildDetailItem('形式', widget.review['lectureFormat']),
            _buildDetailItem('出席', widget.review['attendanceStrictness']),
            _buildDetailItem('試験', widget.review['examType']),
            _buildDetailItem(
              '教員特徴',
              widget.review['teacherTraits'] != null &&
                      (widget.review['teacherTraits'] as List).isNotEmpty
                  ? (widget.review['teacherTraits'] as List).join(', ')
                  : widget.review['teacherFeature'] ?? '',
            ),

            if (widget.review['comment'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'コメント: ${widget.review['comment']}',
                style: const TextStyle(fontSize: 14),
              ),
            ],

            // タグ
            if (widget.review['tags'] != null &&
                (widget.review['tags'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children:
                    (widget.review['tags'] as List)
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.indigo[100],
                          ),
                        )
                        .toList(),
              ),
            ],

            const SizedBox(height: 12),

            // フッター部分（日付 + たこ焼きボタン）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 投稿日時
                Text(
                  widget.review['createdAt'] != null &&
                          widget.review['createdAt'] is Timestamp
                      ? (widget.review['createdAt'] as Timestamp)
                          .toDate()
                          .toString()
                          .split(' ')[0]
                      : '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                // たこ焼きボタン
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              _isLiked ? Colors.orange[100] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              _isLiked
                                  ? 'assets/takoyaki.png'
                                  : 'assets/takoyaki_off.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_takoyakiCount',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    _isLiked
                                        ? Colors.orange[700]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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

  Widget _buildDetailItem(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value', style: const TextStyle(fontSize: 13)),
    );
  }
}
