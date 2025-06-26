import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewPost extends StatelessWidget {
  final String? courseId;

  const ReviewPost({super.key, this.courseId});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.edit),
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => ReviewDialog(courseId: courseId),
        );
      },
    );
  }
}

class ReviewDialog extends StatefulWidget {
  final String? courseId;

  const ReviewDialog({Key? key, this.courseId}) : super(key: key);

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  double satisfaction = 3;
  double ease = 3;
  String examType = 'レポート';
  String attendance = '自由';
  List<String> teacherTraits = [];
  String classFormat = '対面';
  String comment = '';

  // 授業選択用
  List<Map<String, dynamic>> userCourses = [];
  Map<String, dynamic>? selectedCourse;
  bool loadingCourses = true;

  final List<String> examOptions = ['レポート', '筆記', '出席点'];
  final List<String> attendanceOptions = ['自由', '毎回点呼', '出席点あり'];
  final List<String> traitsOptions = ['優しい', '厳しい', 'おもしろい', '聞き取りにくい'];
  final List<String> classFormats = ['対面', 'オンデマンド', 'Zoom'];

  @override
  void initState() {
    super.initState();
    _fetchUserCourses();
  }

  Future<void> _fetchUserCourses() async {
    setState(() {
      loadingCourses = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final timetableDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('timetable')
            .doc('entries')
            .get();
    if (timetableDoc.exists) {
      final data = timetableDoc.data()!;
      final entries = data['entries'] as List<dynamic>? ?? [];
      userCourses =
          entries
              .where((e) => (e['courseId'] ?? '').toString().isNotEmpty)
              .map((e) => e as Map<String, dynamic>)
              .toList();
      if (userCourses.isNotEmpty) selectedCourse = userCourses[0];
    }
    setState(() {
      loadingCourses = false;
    });
  }

  // 報酬計算メソッド
  int _calculateReward() {
    int reward = 5; // 基本報酬（満足度・楽単度・タグ入力）

    // 詳細コメントがある場合は追加報酬
    if (comment.trim().isNotEmpty) {
      reward += 5; // プラス5個
    }

    return reward;
  }

  // たこ焼き報酬を付与するメソッド
  Future<void> _giveTakoyakiReward(int amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Firestoreから現在のたこ焼き数を取得
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      int currentTakoyaki = 0;
      if (userDoc.exists) {
        currentTakoyaki = userDoc.data()?['takoyakiCount'] ?? 0;
      }

      // たこ焼き数を更新
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'takoyakiCount': currentTakoyaki + amount},
      );

      // SharedPreferencesにも保存（アプリ内での表示用）
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('takoyakiCount', currentTakoyaki + amount);
    } catch (e) {
      print('Error giving takoyaki reward: $e');
    }
  }

  // グローバルレビュー保存
  Future<void> _addGlobalReview(
    String courseId,
    Map<String, dynamic> reviewData,
  ) async {
    await FirebaseFirestore.instance.collection('reviews').add(reviewData);
  }

  // ユーザーのキャラクター情報を取得
  Future<String> _getUserCharacter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'adventurer';

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['character'] ?? 'adventurer';
      }
    } catch (e) {
      print('Error getting user character: $e');
    }

    return 'adventurer';
  }

  @override
  Widget build(BuildContext context) {
    final reward = _calculateReward();
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child:
          loadingCourses
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'レビュー投稿',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 授業選択Dropdown
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: selectedCourse,
                        items:
                            userCourses
                                .map(
                                  (course) => DropdownMenuItem(
                                    value: course,
                                    child: Text(
                                      '${course['description'] ?? ''}（${course['teacherName'] ?? ''}）',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (course) => setState(() => selectedCourse = course),
                        decoration: const InputDecoration(labelText: '授業を選択'),
                        validator: (v) => v == null ? '授業を選択してください' : null,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '報酬: たこ焼き${reward}個',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('総合満足度'),
                      Slider(
                        value: satisfaction,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: satisfaction.toString(),
                        onChanged:
                            (value) => setState(() => satisfaction = value),
                      ),
                      const Text('楽単度'),
                      Slider(
                        value: ease,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: ease.toString(),
                        onChanged: (value) => setState(() => ease = value),
                      ),
                      const SizedBox(height: 8),
                      const Text('試験の形式'),
                      DropdownButtonFormField<String>(
                        value: examType,
                        items:
                            examOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => examType = value!),
                      ),
                      const SizedBox(height: 8),
                      const Text('出席の厳しさ'),
                      DropdownButtonFormField<String>(
                        value: attendance,
                        items:
                            attendanceOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(() => attendance = value!),
                      ),
                      const SizedBox(height: 8),
                      const Text('教員の特徴'),
                      Wrap(
                        spacing: 8,
                        children:
                            traitsOptions.map((trait) {
                              return FilterChip(
                                label: Text(trait),
                                selected: teacherTraits.contains(trait),
                                onSelected: (selected) {
                                  setState(() {
                                    selected
                                        ? teacherTraits.add(trait)
                                        : teacherTraits.remove(trait);
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 8),
                      const Text('講義の形式'),
                      DropdownButtonFormField<String>(
                        value: classFormat,
                        items:
                            classFormats
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(() => classFormat = value!),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'おすすめコメント（詳細入力で+5個）',
                          hintText: '詳細なコメントを入力すると追加報酬がもらえます',
                        ),
                        maxLines: 4,
                        onChanged: (value) {
                          setState(() {
                            comment = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'コメントを入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // 投稿ボタン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('キャンセル'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await _giveTakoyakiReward(reward);
                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null && selectedCourse != null) {
                                    final reviewData = {
                                      'userId': user.uid,
                                      'courseId': selectedCourse!['courseId'],
                                      'code': widget.courseId,
                                      'character': await _getUserCharacter(),
                                      'lectureName':
                                          selectedCourse!['description'] ?? '',
                                      'teacherName':
                                          selectedCourse!['teacherName'] ?? '',
                                      'satisfaction': satisfaction,
                                      'ease': ease,
                                      'examType': examType,
                                      'attendance': attendance,
                                      'teacherTraits': teacherTraits,
                                      'classFormat': classFormat,
                                      'comment': comment,
                                      'createdAt': FieldValue.serverTimestamp(),
                                      'reward': reward,
                                    };
                                    await _addGlobalReview(
                                      selectedCourse!['courseId'],
                                      reviewData,
                                    );
                                  }
                                } catch (e) {
                                  print('Error saving review: $e');
                                }
                                Navigator.of(context).pop(true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'レビューを 投稿しました！ たこ焼きを ${reward}個 獲得した！',
                                      style: const TextStyle(
                                        fontFamily: 'misaki',
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.black.withOpacity(
                                      0.85,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('投稿'),
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
