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
  final String lectureName;
  final String teacherName;
  final String courseId;

  const CreditInputPage({
    super.key,
    required this.lectureName,
    required this.teacherName,
    required this.courseId,
  });

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
  List<String> _selectedTags = []; // 授業のタグ用
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

  bool _isLoading = false;
  List<Map<String, String>> _dynamicLectures = [];

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

      print('DEBUG: 時間割から取得した講義一覧: $lecturesWithTeachers');

      // courseIdと紐付けされた授業のみをフィルタリング
      final courseMapping = ref.read(globalCourseMappingProvider);
      print('DEBUG: courseMappingの内容: $courseMapping');
      print('DEBUG: courseMappingのキー一覧: ${courseMapping.keys.toList()}');

      final filteredLectures = <Map<String, String>>[];

      for (final lecture in lecturesWithTeachers) {
        final lectureName = lecture['name'] ?? '';
        print('DEBUG: チェック中の講義名: "$lectureName"');
        print(
          'DEBUG: courseMappingに存在するか: ${courseMapping.containsKey(lectureName)}',
        );
        if (courseMapping.containsKey(lectureName)) {
          filteredLectures.add(lecture);
          print('DEBUG: 追加された講義: $lecture');
        }
      }

      setState(() {
        _dynamicLectures = filteredLectures;
      });

      print('DEBUG: courseIdと紐付けされた講義を読み込みました: ${_dynamicLectures.length}件');
      print('DEBUG: 教員名付き講義一覧: $_dynamicLectures');
    } catch (e) {
      print('Error loading lectures from timetable: $e');
      setState(() {
        _dynamicLectures = [];
      });
    }
  }

  // グローバル教員名取得
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

  // グローバル教員名保存
  Future<void> _setGlobalTeacherName(
    String courseId,
    String teacherName,
  ) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('meta')
        .doc('info')
        .set({'teacherName': teacherName}, SetOptions(merge: true));
  }

  Future<void> _saveReview() async {
    print('saveReview呼び出し時のcourseId: \\${widget.courseId}');
    if (!mounted) return;

    // 既にローディング中の場合は処理をスキップ（二重クリック防止）
    if (_isLoading) {
      print('既にローディング中のため、処理をスキップします');
      return;
    }

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

    final courseId = widget.courseId;
    if (courseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('courseIdが取得できません。授業カードから遷移してください。')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. lectureNameからcourseIdを取得（ただし保存にはwidget.courseIdを必ず使う）
      final courseMapping = ref.read(globalCourseMappingProvider);
      final mappedCourseId = courseMapping[lectureName];
      if (mappedCourseId != null && mappedCourseId.isNotEmpty) {
        await _setGlobalTeacherName(mappedCourseId, editedTeacherName);
      }

      // 2. 保存するレビューデータを作成（必ずwidget.courseIdを使う）
      final reviewData = {
        'lectureName': lectureName,
        'teacherName': editedTeacherName,
        'courseId': widget.courseId, // 必ずwidget.courseIdを直接入れる
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
      print('Firestoreに保存するreviewData: $reviewData');

      // reviewsコレクションに直接addで保存
      await FirebaseFirestore.instance.collection('reviews').add(reviewData);

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
    } catch (e, st) {
      print('レビュー投稿エラー: $e');
      print(st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('レビュー投稿に失敗: $e')));
        setState(() => _isLoading = false);
      }
      return;
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
    print('CreditInputPageでのcourseId: \\${widget.courseId}');
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
                  title: const Text('レビューを投稿'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              ),
              // SingleChildScrollView（AppBarの下から画面の一番下まで）
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
                child: const CommonBottomNavigation(),
              ),
            ],
          ),
        ),
      ],
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

  // 講義選択時にグローバル教員名をセット
  void _showLectureSelectionDialog() async {
    final Map<String, String> allCourses = ref.read(
      globalCourseMappingProvider,
    );

    // Create a list of lecture names for the dialog
    final lectures = allCourses.keys.toList();

    final String? selected = await showDialog(
      context: context,
      builder: (context) {
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
      });
      final courseId = allCourses[selected];
      if (courseId != null) {
        final teacherName = await _getGlobalTeacherName(courseId);
        _teacherNameController.text = teacherName;
      }
    }
  }
}
