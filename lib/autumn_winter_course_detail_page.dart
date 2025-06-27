import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'credit_input_page.dart';

class AutumnWinterCourseDetailPage extends StatefulWidget {
  final String lectureName;
  final String teacherName;
  final String courseId;
  final String category;
  final String semester;

  const AutumnWinterCourseDetailPage({
    super.key,
    required this.lectureName,
    required this.teacherName,
    required this.courseId,
    required this.category,
    required this.semester,
  });

  @override
  State<AutumnWinterCourseDetailPage> createState() =>
      _AutumnWinterCourseDetailPageState();
}

class _AutumnWinterCourseDetailPageState
    extends State<AutumnWinterCourseDetailPage> {
  double avgSatisfaction = 0.0;
  double avgEasiness = 0.0;
  int reviewCount = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _allReviews = [];

  // ページネーション用
  static const int pageSize = 10;
  List<DocumentSnapshot> _currentPageDocs = [];
  DocumentSnapshot? _lastDoc;
  DocumentSnapshot? _firstDoc;
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _hasPrevPage = false;

  @override
  void initState() {
    super.initState();
    _fetchStatsAndReviews();
    _fetchPage();
  }

  // サマリー用（全件取得）
  Future<void> _fetchStatsAndReviews() async {
    setState(() => _loading = true);
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('lectureName', isEqualTo: widget.lectureName)
              .where('teacherName', isEqualTo: widget.teacherName)
              .get();
      final reviews =
          query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      double sumSatisfaction = 0.0;
      double sumEasiness = 0.0;
      for (final review in reviews) {
        sumSatisfaction += (review['overallSatisfaction'] ?? 0.0) * 1.0;
        sumEasiness += (review['easiness'] ?? 0.0) * 1.0;
      }
      setState(() {
        _allReviews = reviews;
        avgSatisfaction =
            reviews.isNotEmpty ? sumSatisfaction / reviews.length : 0.0;
        avgEasiness = reviews.isNotEmpty ? sumEasiness / reviews.length : 0.0;
        reviewCount = reviews.length;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching reviews: $e');
      setState(() => _loading = false);
    }
  }

  // ページごとのレビュー取得
  Future<void> _fetchPage({bool next = false, bool prev = false}) async {
    setState(() => _loading = true);
    try {
      Query query = FirebaseFirestore.instance
          .collection('reviews')
          .where('lectureName', isEqualTo: widget.lectureName)
          .where('teacherName', isEqualTo: widget.teacherName)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      if (next && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      } else if (prev && _firstDoc != null) {
        query = query.endBeforeDocument(_firstDoc!);
      }
      final snapshot = await query.get();
      setState(() {
        _currentPageDocs = snapshot.docs;
        _firstDoc = snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasNextPage = snapshot.docs.length == pageSize;
        _hasPrevPage = _currentPage > 1;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching page: $e');
      setState(() => _loading = false);
    }
  }

  void _nextPage() {
    if (_hasNextPage) {
      setState(() => _currentPage++);
      _fetchPage(next: true);
    }
  }

  void _prevPage() {
    if (_hasPrevPage && _currentPage > 1) {
      setState(() => _currentPage--);
      _fetchPage(prev: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lectureName} - レビュー一覧'),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lectureName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.teacherName,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.category} (${widget.semester})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  avgSatisfaction.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '満足度',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.sentiment_satisfied,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  avgEasiness.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '楽単度',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.rate_review,
                                  color: Colors.blueGrey,
                                  size: 22,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$reviewCount件',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
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
                          _fetchStatsAndReviews(); // 投稿後に再取得
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          'レビューを書く',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_currentPageDocs.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'みんなのレビュー',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._currentPageDocs.map((doc) {
                            final review = doc.data() as Map<String, dynamic>;
                            return FutureBuilder<DocumentSnapshot>(
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
                                  characterImage =
                                      data?['characterImage'] as String?;
                                }
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  color: Colors.cyan[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
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
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                          color:
                                                              Colors.deepOrange,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    review['createdAt'] !=
                                                                null &&
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
                                                '形式: \\${review['lectureFormat'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                '出席: \\${review['attendanceStrictness'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                '試験: \\${review['examType'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                '教員特徴: \\${review['teacherFeature'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'コメント: \\${review['comment'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
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
                                                                      fontSize:
                                                                          11,
                                                                    ),
                                                              ),
                                                              backgroundColor:
                                                                  Colors
                                                                      .cyan[100],
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
                            );
                          }),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _hasPrevPage ? _prevPage : null,
                                child: const Text('前へ'),
                              ),
                              const SizedBox(width: 16),
                              Text('$_currentPageページ'),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _hasNextPage ? _nextPage : null,
                                child: const Text('次へ'),
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
}
