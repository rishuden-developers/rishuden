// credit_review_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ★レート表示に利用するパッケージをインポート
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'credit_input_page.dart'; // レビュー投稿画面への遷移用
import 'credit_explore_page.dart'; // ボトムナビゲーション用
import 'providers/global_review_mapping_provider.dart';
import 'character_data.dart'; // キャラクターデータをインポート
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/timetable_provider.dart';
import 'main_page.dart';
import 'providers/current_page_provider.dart';

// ★★★★ 補足: flutter_rating_bar パッケージの追加 ★★★★
// pubspec.yaml ファイルの dependencies: の下に追加してください。
// dependencies:
//   flutter:
//     sdk: flutter
//   flutter_rating_bar: ^5.1.1 # 最新バージョンを確認してください
// ----------------------------------------------------

enum LectureFormat { faceToFace, onDemand, zoom, other }

enum AttendanceStrictness {
  flexible,
  everyTimeRollCall,
  attendancePoints,
  noAttendance,
}

enum ExamType { report, written, attendanceBased, none, other }

// Dummy Review Data Structure (for demonstration of filtering)
class LectureReview {
  final String lectureName;
  final String teacherName;
  final String userId;
  final double overallSatisfaction;
  final double easiness;
  final LectureFormat lectureFormat;
  final AttendanceStrictness attendanceStrictness;
  final ExamType examType;
  final String teacherFeature;
  final String comment;
  final List<String> tags;
  final String reviewId;
  final String reviewDate;

  LectureReview({
    required this.lectureName,
    required this.teacherName,
    required this.userId,
    required this.overallSatisfaction,
    required this.easiness,
    required this.lectureFormat,
    required this.attendanceStrictness,
    required this.examType,
    required this.teacherFeature,
    required this.comment,
    required this.tags,
    required this.reviewId,
    required this.reviewDate,
  });
}

class CreditReviewPage extends ConsumerStatefulWidget {
  final String lectureName;
  final String teacherName;
  final String? courseId; // ★ courseIdに統一
  final String? initialDescription; // 講義の概要
  final double? initialOverallSatisfaction; // 講義全体の平均満足度
  final double? initialEasiness; // 講義全体の平均楽単度

  const CreditReviewPage({
    super.key,
    required this.lectureName,
    required this.teacherName,
    this.courseId, // ★ courseIdに統一
    this.initialDescription,
    this.initialOverallSatisfaction,
    this.initialEasiness,
  });

  @override
  ConsumerState<CreditReviewPage> createState() => _CreditReviewPageState();
}

class _CreditReviewPageState extends ConsumerState<CreditReviewPage> {
  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _filteredReviews = [];
  bool _isLoading = true;
  StreamSubscription? _reviewsSubscription;

  // フィルター用
  String? _selectedFormatFilter;
  String? _selectedAttendanceFilter;
  String? _selectedExamFilter;

  @override
  void initState() {
    super.initState();
    // initStateではrefが使えないため、WidgetsBinding.instance.addPostFrameCallbackを使用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToReviews();
    });
  }

  @override
  void dispose() {
    _reviewsSubscription?.cancel(); // ★ ページが破棄されるときにStreamの監視をキャンセル
    super.dispose();
  }

  // Firebaseのレビュー変更を監視
  void _subscribeToReviews() async {
    setState(() => _isLoading = true);
    try {
      Query query = FirebaseFirestore.instance.collection('reviews');

      // courseIdでフィルタリング（その講義のレビューのみを取得）
      if (widget.courseId != null && widget.courseId!.isNotEmpty) {
        query = query.where('courseId', isEqualTo: widget.courseId);
      } else {
        // courseIdがない場合は、lectureNameとteacherNameでフィルタリング
        query = query.where('lectureName', isEqualTo: widget.lectureName);
        if (widget.teacherName.isNotEmpty) {
          query = query.where('teacherName', isEqualTo: widget.teacherName);
        }
      }

      final querySnapshot = await query.get();

      final reviews =
          querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'reviewId': doc.id,
              'lectureName': data['lectureName'] ?? '',
              'teacherName': data['teacherName'] ?? '',
              'userId': data['userId'] ?? '',
              'overallSatisfaction': _parseToDouble(
                data['overallSatisfaction'] ?? data['satisfaction'],
              ),
              'easiness': _parseToDouble(data['easiness'] ?? data['ease']),
              'lectureFormat':
                  data['lectureFormat'] ?? data['classFormat'] ?? '',
              'attendanceStrictness':
                  data['attendanceStrictness'] ?? data['attendance'] ?? '',
              'examType': data['examType'] ?? '',
              'teacherFeature': data['teacherFeature'] ?? '',
              'comment': data['comment'] ?? '',
              'tags': List<String>.from(
                data['tags'] ?? data['teacherTraits'] ?? [],
              ),
              'createdAt': data['createdAt'],
              'character': data['character'] ?? 'adventurer',
              'takoyakiCount': data['takoyakiCount'] ?? 0,
              'likedBy': data['likedBy'] ?? [],
              'courseId': data['courseId'] ?? '',
            };
          }).toList();

      setState(() {
        _allReviews = reviews;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      print('Error loading reviews: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredReviews =
        _allReviews.where((review) {
          bool matches = true;
          if (_selectedFormatFilter != null) {
            matches =
                matches && review['lectureFormat'] == _selectedFormatFilter;
          }
          if (_selectedAttendanceFilter != null) {
            matches =
                matches &&
                review['attendanceStrictness'] == _selectedAttendanceFilter;
          }
          if (_selectedExamFilter != null) {
            matches = matches && review['examType'] == _selectedExamFilter;
          }
          return matches;
        }).toList();
  }

  double get _averageOverallSatisfaction {
    if (_allReviews.isEmpty) return 0.0;
    return _allReviews
            .map((r) => r['overallSatisfaction'])
            .reduce((a, b) => a + b) /
        _allReviews.length;
  }

  double get _averageEasiness {
    if (_allReviews.isEmpty) return 0.0;
    return _allReviews.map((r) => r['easiness']).reduce((a, b) => a + b) /
        _allReviews.length;
  }

  String _formatEnum(dynamic enumValue) {
    if (enumValue == null) return '未指定';
    return enumValue.toString().split('.').last;
  }

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final myReview =
        user == null
            ? null
            : (_allReviews.firstWhereOrNull((r) => r['userId'] == user.uid));
    final otherReviews =
        user == null
            ? _allReviews
            : _allReviews.where((r) => r['userId'] != user.uid).toList();

    // courseIdがwidget.courseIdと一致するレビューだけを抽出
    final filteredReviews =
        _allReviews
            .where(
              (r) =>
                  (r['courseId'] ?? '').toString().trim() ==
                  (widget.courseId ?? '').toString().trim(),
            )
            .toList();

    // デバッグ用: Firestoreから取得したレビュー件数を出力
    print('レビュー件数: ${_allReviews.length}');
    print('CreditReviewPageでのwidget.courseId: \\${widget.courseId}');

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
                  title: const Text(
                    '講義レビュー',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansJP',
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              // ListView（AppBarの下から画面の一番下まで）
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                bottom: 0,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildLectureInfoCard(),
                    const SizedBox(height: 20),
                    _buildOverallRatingsCard(),
                    if (filteredReviews.isEmpty) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'この講義のレビューはまだありません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      // すべてのレビューをカードで表示
                      ...filteredReviews
                          .map<Widget>(_buildOtherReviewCard)
                          .toList(),
                    ],
                    const SizedBox(height: 20),
                    _buildPostReviewButton(context),
                    const SizedBox(height: 200), // ボトムナビの高さ分の余白を増加
                  ],
                ),
              ),
              // ボトムナビ
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CommonBottomNavigation(
                  onNavigate: (page) {
                    ref.read(currentPageProvider.notifier).state = page;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLectureInfoCard() {
    return Card(
      margin: EdgeInsets.zero, // Remove margin to allow for specific padding
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lectureName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 4),
            _EditableTeacherName(
              courseId: widget.courseId,
              initialTeacherName: widget.teacherName,
            ),
            if (widget.initialDescription != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.initialDescription!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRatingsCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '全体の評価',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                RatingBarIndicator(
                  rating: _averageOverallSatisfaction,
                  itemBuilder:
                      (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 24.0,
                  direction: Axis.horizontal,
                ),
                const SizedBox(width: 12),
                Text(
                  _averageOverallSatisfaction.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_allReviews.length}件のレビュー)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.sentiment_satisfied,
                  color: Colors.lightGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '楽単度: ${_averageEasiness.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostReviewButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        if (widget.courseId == null || widget.courseId!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('courseIdが取得できません。授業カードから遷移してください。')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CreditInputPage(
                  lectureName: widget.lectureName,
                  teacherName: widget.teacherName,
                  courseId: widget.courseId!,
                ),
          ),
        ).then((result) {
          if (result == true) {
            // 投稿完了時にレビューを再取得
            _subscribeToReviews();
          }
        });
      },
      icon: const Icon(Icons.edit, color: Colors.white),
      label: const Text(
        'この講義のレビューを投稿する',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'NotoSansJP',
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.teal[100]!, width: 1.5),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildMyReviewCard(Map<String, dynamic> review) {
    return Card(
      color: Colors.cyan[50],
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // キャラクター画像
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: _getCharacterImageWidget(review['userId']),
            ),
            const SizedBox(width: 16),
            // レビュー内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'あなたのレビュー',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.cyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RatingBarIndicator(
                        rating: review['overallSatisfaction'],
                        itemBuilder:
                            (context, index) =>
                                const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                      Text(
                        review['createdAt'] != null
                            ? DateFormat('yyyy/MM/dd').format(
                              (review['createdAt'] as Timestamp).toDate(),
                            )
                            : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '形式: ${_formatEnum(review['lectureFormat'])}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    '出席: ${_formatEnum(review['attendanceStrictness'])}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    '試験: ${_formatEnum(review['examType'])}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    '教員特徴: ${review['teacherFeature']}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'コメント: ${review['comment']}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    children:
                        review['tags']
                            .map<Widget>(
                              (tag) => Chip(
                                label: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.cyan[100],
                                  ),
                                ),
                                backgroundColor: Colors.cyan[100],
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
  }

  Widget _buildOtherReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // キャラクター画像
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: _getCharacterImageWidget(review['userId']),
            ),
            const SizedBox(width: 16),
            // レビュー内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RatingBarIndicator(
                        rating: review['overallSatisfaction'],
                        itemBuilder:
                            (context, index) =>
                                const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                      Text(
                        review['createdAt'] != null
                            ? DateFormat('yyyy/MM/dd').format(
                              (review['createdAt'] as Timestamp).toDate(),
                            )
                            : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '形式: ${_formatEnum(review['lectureFormat'])}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    '出席: ${_formatEnum(review['attendanceStrictness'])}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    '試験: ${_formatEnum(review['examType'])}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    '教員特徴: ${review['teacherFeature']}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'コメント: ${review['comment']}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    children:
                        review['tags']
                            .map<Widget>(
                              (tag) => Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.brown,
                                  ),
                                ),
                                backgroundColor: Colors.orangeAccent[50],
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 12),
                  _TakoyakiButton(
                    userId: review['userId'],
                    reviewId: review['reviewId'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCharacterImageWidget(String? userId) {
    if (userId == null) {
      return Image.asset('assets/character_gorilla.png', fit: BoxFit.cover);
    } else {
      return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          String? characterName;
          if (userSnapshot.hasData && userSnapshot.data != null) {
            final data = userSnapshot.data!.data() as Map<String, dynamic>?;
            characterName = data?['character'] as String?;
          }

          // character_data.dartから画像パスを取得
          String? characterImage;
          if (characterName != null && characterName.isNotEmpty) {
            characterImage =
                characterFullDataGlobal[characterName]?['image'] as String?;
          } else {
            characterImage = null;
          }

          return characterImage != null
              ? Image.asset(characterImage, fit: BoxFit.cover)
              : Image.asset('assets/character_gorilla.png', fit: BoxFit.cover);
        },
      );
    }
  }
}

// --- たこ焼きボタンWidget ---
class _TakoyakiButton extends StatefulWidget {
  final String? userId;
  final String reviewId;
  const _TakoyakiButton({this.userId, required this.reviewId});

  @override
  State<_TakoyakiButton> createState() => _TakoyakiButtonState();
}

class _TakoyakiButtonState extends State<_TakoyakiButton> {
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _checkIfSent();
  }

  Future<void> _checkIfSent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sent =
          prefs.getBool('takoyaki_sent_${widget.reviewId}_${user.uid}') ??
          false;
    });
  }

  Future<void> _sendTakoyaki() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.userId == null) return;
    // Firestoreで投稿者にたこ焼きを1つ加算
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'takoyakiCount': FieldValue.increment(1)});
    // ローカルで送信済みフラグを保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('takoyaki_sent_${widget.reviewId}_${user.uid}', true);
    setState(() {
      _sent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'たこ焼きを送りました！',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _sent ? null : _sendTakoyaki,
          icon: Image.asset('assets/takoyaki.png', width: 24, height: 24),
          label: Text(
            _sent ? '送信済み' : '有益！たこ焼き',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _sent ? Colors.grey : Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// 教員名編集用Widget
class _EditableTeacherName extends StatefulWidget {
  final String? courseId;
  final String initialTeacherName;
  const _EditableTeacherName({this.courseId, required this.initialTeacherName});

  @override
  State<_EditableTeacherName> createState() => _EditableTeacherNameState();
}

class _EditableTeacherNameState extends State<_EditableTeacherName> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTeacherName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherName = _controller.text;
    return _isEditing
        ? Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(fontSize: 18, fontFamily: 'NotoSansJP'),
                decoration: const InputDecoration(
                  hintText: '教員名を入力してください',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (value) => _save(value),
                onEditingComplete: () => _save(_controller.text),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, size: 20),
              onPressed: () => _save(_controller.text),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        )
        : GestureDetector(
          onTap: () {
            setState(() {
              _isEditing = true;
            });
          },
          child: Text(
            teacherName.isNotEmpty ? teacherName : '未設定',
            style: TextStyle(
              fontSize: 18,
              color:
                  teacherName.isNotEmpty ? Colors.grey[700] : Colors.grey[500],
              fontStyle:
                  teacherName.isEmpty ? FontStyle.italic : FontStyle.normal,
              fontFamily: 'NotoSansJP',
            ),
          ),
        );
  }

  void _save(String value) async {
    setState(() {
      _isEditing = false;
    });
    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      // timetableProviderに保存
      final container = ProviderScope.containerOf(context, listen: false);
      container
          .read(timetableProvider.notifier)
          .setTeacherName(widget.courseId!, value);
    }
  }
}
