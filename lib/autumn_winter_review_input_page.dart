import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'common_bottom_navigation.dart';
import 'main_page.dart';
import 'providers/current_page_provider.dart';

class AutumnWinterReviewInputPage extends ConsumerStatefulWidget {
  final String lectureName;
  final String teacherName;

  const AutumnWinterReviewInputPage({
    super.key,
    required this.lectureName,
    required this.teacherName,
  });

  @override
  ConsumerState<AutumnWinterReviewInputPage> createState() =>
      _AutumnWinterReviewInputPageState();
}

class _AutumnWinterReviewInputPageState
    extends ConsumerState<AutumnWinterReviewInputPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  double _overallSatisfaction = 3.0;
  double _easiness = 3.0;
  String? _selectedExamType;
  String? _selectedAttendance;
  String? _classFormat;

  List<String> _selectedTraits = [];
  List<String> _selectedTags = [];

  bool _isLoading = false;

  // オプション
  final List<String> _examOptions = ['レポート', '筆記', '出席点', 'その他'];
  final List<String> _attendanceOptions = ['自由', '毎回点呼', '出席点あり', 'その他'];
  final List<String> _traitsOptions = [
    '優しい',
    '厳しい',
    'おもしろい',
    '聞き取りにくい',
    '神',
    '鬼',
    '楽単',
  ];
  final List<String> _tagOptions = [
    '楽単',
    '神講義',
    '鬼講義',
    '単位取りやすい',
    '単位取りにくい',
    '面白い',
    'つまらない',
    '実用的',
    '理論的',
    '実習あり',
    'グループワーク',
    'プレゼンあり',
    '小テストあり',
    'レポートあり',
    '出席あり',
  ];
  final List<String> _classFormats = ['対面', 'オンデマンド', 'Zoom', 'その他'];

  @override
  void initState() {
    super.initState();
    _teacherNameController.text = widget.teacherName;
    _commentController.addListener(() {
      setState(() {}); // 報酬表示の更新
    });
  }

  @override
  void dispose() {
    _teacherNameController.dispose();
    _commentController.dispose();
    super.dispose();
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

  // レビュー保存
  Future<void> _saveReview() async {
    print('秋冬学期レビュー投稿開始');
    if (!mounted) {
      print('コンポーネントがマウントされていません');
      return;
    }
    if (_isLoading) {
      print('既にローディング中です');
      return;
    }

    setState(() => _isLoading = true);

    final lectureName = widget.lectureName;
    if (lectureName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('講義名が取得できません。')));
      setState(() => _isLoading = false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('レビューを投稿するにはログインが必要です。')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('レビューデータ作成開始');
      // レビューデータを作成
      final reviewData = {
        'lectureName': lectureName,
        'teacherName': _teacherNameController.text.trim(),
        'courseId': '', // 秋冬学期は空文字
        'userId': user.uid,
        'character': await _getUserCharacter(),
        'overallSatisfaction': _overallSatisfaction,
        'easiness': _easiness,
        'lectureFormat': _classFormat,
        'attendanceStrictness': _selectedAttendance,
        'examType': _selectedExamType,
        'teacherFeature':
            _selectedTraits.isNotEmpty ? _selectedTraits.join(', ') : '',
        'teacherTraits': _selectedTraits,
        'tags': _selectedTags,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('秋冬学期レビュー投稿: $reviewData');

      // reviewsコレクションに保存
      print('Firestoreへの保存開始');
      await FirebaseFirestore.instance.collection('reviews').add(reviewData);
      print('Firestoreへの保存完了');

      // 報酬の計算と付与
      print('報酬計算開始');
      int reward = 5;
      if (_commentController.text.trim().isNotEmpty) {
        reward += 5;
      }
      print('報酬: $reward個');
      await _giveTakoyakiReward(reward);
      print('報酬付与完了');

      if (mounted) {
        print('レビュー投稿成功 - 画面更新');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('レビューを保存しました！たこ焼き$reward個GET！')));
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
      }
    } catch (e, st) {
      print('秋冬学期レビュー投稿エラー: $e');
      print('スタックトレース: $st');
      if (mounted) {
        print('エラー時の画面更新');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('レビュー投稿に失敗: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // たこ焼き報酬付与
  Future<void> _giveTakoyakiReward(int amount) async {
    print('たこ焼き報酬付与開始: $amount個');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('ユーザーがログインしていません');
      return;
    }

    try {
      print('ユーザードキュメント更新開始');
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await userRef.update({'takoyakiCount': FieldValue.increment(amount)});
      print('たこ焼き報酬付与成功');
    } catch (e) {
      print('たこ焼き報酬付与エラー: $e');
      if (e is FirebaseException && e.code == 'not-found') {
        print('ユーザードキュメントが存在しないため、新規作成');
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'takoyakiCount': amount,
        }, SetOptions(merge: true));
        print('ユーザードキュメント新規作成完了');
      } else {
        print('たこ焼き報酬の付与に失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int reward = 5;
    if (_commentController.text.trim().isNotEmpty) {
      reward += 5;
    }

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
                  title: const Text('秋冬学期レビュー投稿'),
                  backgroundColor: const Color.fromARGB(0, 255, 255, 255),
                  elevation: 0,
                ),
              ),
              // メインコンテンツ
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('講義・教員名', Icons.school),
                        _buildLectureDisplay(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('評価項目', Icons.star),
                        const SizedBox(height: 10),
                        _buildOverallSatisfaction(),
                        const SizedBox(height: 10),
                        _buildEasinessRating(),
                        const SizedBox(height: 20),
                        _buildSectionTitle('詳細情報', Icons.info_outline),
                        const SizedBox(height: 10),
                        _buildDropdown(
                          '講義形式',
                          _classFormats,
                          _classFormat,
                          (val) => setState(() => _classFormat = val),
                        ),
                        const SizedBox(height: 10),
                        _buildDropdown(
                          '出席の厳しさ',
                          _attendanceOptions,
                          _selectedAttendance,
                          (val) => setState(() => _selectedAttendance = val),
                        ),
                        const SizedBox(height: 10),
                        _buildDropdown(
                          '試験の形式',
                          _examOptions,
                          _selectedExamType,
                          (val) => setState(() => _selectedExamType = val),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle('教員の特徴', Icons.person_outline),
                        _buildChipsSection(),
                        const SizedBox(height: 20),
                        _buildSectionTitle('授業のタグ', Icons.label),
                        _buildTagChipsSection(),
                        const SizedBox(height: 20),
                        _buildSectionTitle(
                          'コメント (+${_commentController.text.trim().isEmpty ? '5' : '0'}個)',
                          Icons.comment,
                        ),
                        TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: '授業の感想、TAの様子など...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Center(
                            child: Text(
                              '報酬: たこ焼き ${reward}個 GET!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveReview,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.cyan,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      'レビューを投稿する',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
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

  // ヘルパーメソッド
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLectureDisplay() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lectureName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _teacherNameController,
              decoration: const InputDecoration(
                labelText: '教員名 (編集可)',
                hintText: '教員名を入力',
                border: InputBorder.none,
                icon: Icon(Icons.person),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSatisfaction() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('総合満足度', style: TextStyle(fontSize: 16)),
            RatingBar.builder(
              initialRating: _overallSatisfaction,
              minRating: 1,
              itemCount: 5,
              itemBuilder:
                  (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate:
                  (rating) => setState(() => _overallSatisfaction = rating),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEasinessRating() {
    final List<IconData> smileyIcons = [
      Icons.sentiment_very_dissatisfied,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_satisfied,
      Icons.sentiment_very_satisfied,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('楽単度', style: TextStyle(fontSize: 16)),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    smileyIcons[index],
                    color: _easiness >= index + 1 ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => setState(() => _easiness = index + 1.0),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: DropdownButtonFormField<String>(
          value: currentValue,
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: hint,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildChipsSection() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children:
              _traitsOptions.map((trait) {
                final isSelected = _selectedTraits.contains(trait);
                return FilterChip(
                  label: Text(trait),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTraits.add(trait);
                      } else {
                        _selectedTraits.remove(trait);
                      }
                    });
                  },
                  selectedColor: Colors.cyan[100],
                  checkmarkColor: Colors.black,
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTagChipsSection() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children:
              _tagOptions.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: Colors.cyan[100],
                  checkmarkColor: Colors.black,
                );
              }).toList(),
        ),
      ),
    );
  }
}
