// credit_input_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'credit_explore_page.dart';
import 'credit_result_page.dart';
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ★レート表示に利用するパッケージをインポート
import 'providers/global_review_mapping_provider.dart';
import 'providers/timetable_provider.dart';

// credit_review_page.dartからEnumをインポート（同じ定義を持つか、共通ファイルに移動）
import 'credit_review_page.dart'
    show LectureFormat, AttendanceStrictness, ExamType;

class CreditInputPage extends ConsumerStatefulWidget {
  final String? lectureName;
  final String? teacherName;

  const CreditInputPage({super.key, this.lectureName, this.teacherName});

  @override
  ConsumerState<CreditInputPage> createState() => _CreditInputPageState();
}

class _CreditInputPageState extends ConsumerState<CreditInputPage> {
  final _formKey = GlobalKey<FormState>();

  // State variables for the form
  String _selectedLectureName = '';
  String _selectedTeacherName = '';
  double _overallSatisfaction = 3.0;
  double _easiness = 3.0;
  String? _selectedExamType;
  String? _selectedAttendance;
  List<String> _selectedTeacherTraits = [];
  String? _selectedClassFormat;
  final _commentController = TextEditingController();

  // Options for dropdowns and chips
  final List<String> _examOptions = ['レポート', '筆記', '出席点', 'その他'];
  final List<String> _attendanceOptions = ['自由', '毎回点呼', '出席点あり', 'その他'];
  final List<String> _traitsOptions = ['優しい', '厳しい', 'おもしろい', '聞き取りにくい'];
  final List<String> _classFormats = ['対面', 'オンデマンド', 'Zoom', 'その他'];

  bool _isLoading = false;
  List<Map<String, String>> _dynamicLectures = [];

  // ダミーの講義リスト（検索・選択機能がない場合は、外部から渡すか固定値）
  final List<Map<String, String>> _dummyLectures = [
    {'name': '線形代数学Ⅰ', 'teacher': '山田 太郎'},
    {'name': 'データ構造とアルゴM', 'teacher': '佐藤 花子'},
    {'name': '経済学原論', 'teacher': '田中 健太'},
    {'name': '日本文学史', 'teacher': '鈴木 文子'},
    {'name': '物理学実験', 'teacher': '渡辺 剛'},
    {'name': '情報倫理', 'teacher': '山田 太郎'},
    {'name': '現代社会論', 'teacher': '高橋 涼子'},
    {'name': '国際法入門', 'teacher': '伊藤 大輔'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.lectureName != null && widget.teacherName != null) {
      _selectedLectureName = widget.lectureName!;
      _selectedTeacherName = widget.teacherName!;
    }
    _loadLecturesFromTimetable();
    _commentController.addListener(() {
      setState(() {}); // To update reward display
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 依存関係が変更された時に最新の教員一覧を取得
    _loadLecturesFromTimetable();
  }

  // 時間割から講義と教員名を取得
  void _loadLecturesFromTimetable() {
    try {
      // TimetableProviderから教員名付き講義一覧を取得
      final lecturesWithTeachers =
          ref.read(timetableProvider.notifier).getLecturesWithTeachers();

      // ダミー講義リストも含める
      final allLectures = <Map<String, String>>[];
      allLectures.addAll(_dummyLectures);
      allLectures.addAll(lecturesWithTeachers);

      setState(() {
        _dynamicLectures = allLectures;
      });

      print('DEBUG: 時間割から教員名付き講義を読み込みました: ${_dynamicLectures.length}件');
      print('DEBUG: 教員名付き講義一覧: $_dynamicLectures');
    } catch (e) {
      print('Error loading lectures from timetable: $e');
      setState(() {
        _dynamicLectures = _dummyLectures;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final reviewId = ref
            .read(globalReviewMappingProvider.notifier)
            .getOrCreateReviewId(_selectedLectureName, _selectedTeacherName);
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('ユーザーが認証されていません');

        int reward = 5;
        if (_commentController.text.trim().isNotEmpty) {
          reward += 5;
        }

        final reviewData = {
          'lectureName': _selectedLectureName,
          'teacherName': _selectedTeacherName,
          'reviewId': reviewId,
          'overallSatisfaction': _overallSatisfaction,
          'easiness': _easiness,
          'lectureFormat': _selectedClassFormat,
          'attendanceStrictness': _selectedAttendance,
          'examType': _selectedExamType,
          'teacherTraits': _selectedTeacherTraits,
          'comment': _commentController.text,
          'tags': [], // This can be populated if needed in future
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'reward': reward,
        };

        // Save review and give reward
        await FirebaseFirestore.instance.collection('reviews').add(reviewData);
        await _giveTakoyakiReward(reward);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('レビューを投稿しました！たこ焼き${reward}個GET！'),
            backgroundColor: Colors.black.withOpacity(0.85),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('レビューの投稿に失敗しました: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _giveTakoyakiReward(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await userRef.update({'takoyakiCount': FieldValue.increment(amount)});
    } catch (e) {
      if (e is FirebaseException && e.code == 'not-found') {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'takoyakiCount': amount,
        }, SetOptions(merge: true));
      } else {
        print('たこ焼き報酬の付与に失敗: $e');
      }
    }
  }

  String _formatEnum(dynamic enumValue) {
    if (enumValue == null) return '選択してください';
    return enumValue.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    int reward = 5;
    if (_commentController.text.trim().isNotEmpty) {
      reward += 5;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('レビューを投稿'),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('レビュー対象講義', Icons.school),
                  const SizedBox(height: 10),
                  _buildLectureDisplay(),
                  const SizedBox(height: 20),
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
                    _selectedClassFormat,
                    (val) => setState(() => _selectedClassFormat = val),
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
                      onPressed: _isLoading ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('投稿する'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedLectureName,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            _selectedTeacherName,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 8.0,
          children:
              _traitsOptions.map((trait) {
                final isSelected = _selectedTeacherTraits.contains(trait);
                return FilterChip(
                  label: Text(trait),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTeacherTraits.add(trait);
                      } else {
                        _selectedTeacherTraits.remove(trait);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ),
    );
  }
}
