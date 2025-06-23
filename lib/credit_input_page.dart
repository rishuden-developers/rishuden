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
import 'providers/global_course_mapping_provider.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables for the form
  String _selectedLectureName = '';
  late final TextEditingController _teacherNameController;
  final TextEditingController _commentController = TextEditingController();
  double _overallSatisfaction = 3.0;
  double _easiness = 3.0;
  String? _selectedExamType;
  String? _selectedAttendance;

  List<String> _selectedTraits = [];
  String? _classFormat;

  // Options for dropdowns and chips
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
    _teacherNameController = TextEditingController(
      text: widget.teacherName ?? '',
    );
    if (widget.lectureName != null && widget.teacherName != null) {
      _selectedLectureName = widget.lectureName!;
    }
    _loadLecturesFromTimetable();
    _commentController.addListener(() {
      setState(() {}); // To update reward display
    });
  }

  @override
  void dispose() {
    _teacherNameController.dispose();
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

  Future<void> _saveReview() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final lectureName = widget.lectureName;
    if (lectureName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('講義が選択されていません。')));
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

    final editedTeacherName = _teacherNameController.text.trim();
    if (editedTeacherName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('教員名を入力してください。')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. lectureNameからcourseIdを取得
      final courseMapping = ref.read(globalCourseMappingProvider);
      final courseId = courseMapping[lectureName];

      // 2. timetableProviderの既存関数を使って教員名を保存
      if (courseId != null) {
        ref
            .read(timetableProvider.notifier)
            .setTeacherName(courseId, editedTeacherName);
      }

      // 3. reviewIdを取得または生成
      final reviewId = ref
          .read(globalReviewMappingProvider.notifier)
          .getOrCreateReviewId(lectureName, editedTeacherName);

      // 4. 保存するレビューデータを作成
      final reviewData = {
        'lectureName': lectureName,
        'teacherName': editedTeacherName,
        'reviewId': reviewId,
        'userId': user.uid,
        'overallSatisfaction': _overallSatisfaction,
        'easiness': _easiness,
        'examType': _selectedExamType,
        'attendance': _selectedAttendance,
        'teacherTraits': _selectedTraits,
        'classFormat': _classFormat,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 5. 既存のレビューがあれば更新、なければ新規作成 (Upsert)
      final reviewQuery = FirebaseFirestore.instance
          .collection('reviews')
          .where('reviewId', isEqualTo: reviewId)
          .where('userId', isEqualTo: user.uid)
          .limit(1);

      final existingReviews = await reviewQuery.get();

      if (existingReviews.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('reviews').add(reviewData);
      } else {
        await existingReviews.docs.first.reference.update(reviewData);
      }

      // 6. 報酬の計算と付与
      int reward = 5;
      if (_commentController.text.trim().isNotEmpty) {
        reward += 5;
      }
      await _giveTakoyakiReward(reward);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('レビューを保存しました！たこ焼き$reward個GET！')));
        Navigator.pop(context, true); // 正常に保存されたことを示す
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    } finally {
      if (mounted) {
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
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lectureName ?? '講義を選択',
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

  void _showLectureSelectionDialog() async {
    final Map<String, String> allCourses = ref.read(
      globalCourseMappingProvider,
    );
    final Map<String, String> teacherNames =
        ref.read(timetableProvider)['teacherNames'] as Map<String, String>? ??
        {};

    // Create a list of lecture names for the dialog
    final lectures = allCourses.keys.toList();

    final String? selected = await showDialog(
      context: context,
      builder: (context) {
        // ... (Dialog implementation)
        return SimpleDialog(
          title: const Text('講義を選択'),
          children:
              lectures.map((lecture) {
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, lecture),
                  child: Text(lecture),
                );
              }).toList(),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedLectureName = selected;
        final courseId = allCourses[selected];
        _teacherNameController.text = teacherNames[courseId] ?? '';
      });
    }
  }
}
