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
  // フォームのキーと選択された講義・教師名
  final _formKey = GlobalKey<FormState>();
  String _selectedLectureName = '';
  String _selectedTeacherName = '';

  // レビュー入力フィールドのState
  double _overallSatisfaction = 3.0;
  double _easiness = 3.0;
  LectureFormat? _selectedFormat;
  AttendanceStrictness? _selectedAttendance;
  ExamType? _selectedExamType;
  final TextEditingController _teacherFeatureController =
      TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _tagsController =
      TextEditingController(); // タグ入力用

  // 動的な講義リスト（時間割から取得）
  List<Map<String, String>> _dynamicLectures = [];

  // ダミーの講義リスト（検索・選択機能がない場合は、外部から渡すか固定値）
  List<Map<String, String>> _dummyLectures = [
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
      try {
        // グローバルレビューマッピングからreviewIdを取得
        final reviewId = ref
            .read(globalReviewMappingProvider.notifier)
            .getOrCreateReviewId(_selectedLectureName, _selectedTeacherName);

        print(
          'DEBUG: レビュー投稿 - 授業: $_selectedLectureName, 教員: $_selectedTeacherName, reviewId: $reviewId',
        );

        // 現在のユーザーを取得
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('ユーザーが認証されていません');
        }

        // レビューデータを収集
        final reviewData = {
          'lectureName': _selectedLectureName,
          'teacherName': _selectedTeacherName,
          'reviewId': reviewId,
          'overallSatisfaction': _overallSatisfaction,
          'easiness': _easiness,
          'lectureFormat': _selectedFormat?.toString().split('.').last,
          'attendanceStrictness':
              _selectedAttendance?.toString().split('.').last,
          'examType': _selectedExamType?.toString().split('.').last,
          'teacherFeature': _teacherFeatureController.text,
          'comment': _commentController.text,
          'tags':
              _tagsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Firestoreにレビューを保存
        await FirebaseFirestore.instance.collection('reviews').add(reviewData);

        print('DEBUG: レビューが正常に保存されました');

        // レビュー投稿後、前のページに戻る
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'レビューが投稿されました！',
              style: TextStyle(fontFamily: 'misaki', color: Colors.white),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 2.5),
            ),
          ),
        );
      } catch (e) {
        print('Error submitting review: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'レビューの投稿に失敗しました: $e',
              style: TextStyle(fontFamily: 'misaki', color: Colors.white),
            ),
            backgroundColor: Colors.red.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 2.5),
            ),
          ),
        );
      }
    }
  }

  String _formatEnum(dynamic enumValue) {
    if (enumValue == null) return '選択してください';
    return enumValue.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'レビューを投稿',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansJP',
          ),
        ),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - 32, // Adjust for padding
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 講義選択セクション (CreditReviewPageから来た場合は表示しない)
                            if (widget.lectureName == null ||
                                widget.teacherName == null)
                              _buildLectureSelection(),
                            const SizedBox(height: 20),

                            // レビュー対象の講義表示
                            _buildCurrentLectureDisplay(),
                            const SizedBox(height: 20),

                            _buildSectionTitle('評価項目', Icons.star_half),
                            const SizedBox(height: 10),
                            _buildRatingSection('総合満足度', _overallSatisfaction, (
                              rating,
                            ) {
                              setState(() {
                                _overallSatisfaction = rating;
                              });
                            }),
                            const SizedBox(height: 15),
                            _buildRatingSection(
                              '楽単度',
                              _easiness,
                              (rating) {
                                setState(() {
                                  _easiness = rating;
                                });
                              },
                              icon: Icons.sentiment_satisfied_alt,
                              activeColor: Colors.lightGreen,
                            ),
                            const SizedBox(height: 30),

                            _buildSectionTitle('詳細情報', Icons.info),
                            const SizedBox(height: 10),
                            _buildDropdownField<LectureFormat>(
                              '講義形式',
                              _selectedFormat,
                              LectureFormat.values,
                              (value) {
                                setState(() {
                                  _selectedFormat = value;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null ? '講義形式を選択してください' : null,
                            ),
                            const SizedBox(height: 15),
                            _buildDropdownField<AttendanceStrictness>(
                              '出席厳しさ',
                              _selectedAttendance,
                              AttendanceStrictness.values,
                              (value) {
                                setState(() {
                                  _selectedAttendance = value;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null ? '出席厳しさを選択してください' : null,
                            ),
                            const SizedBox(height: 15),
                            _buildDropdownField<ExamType>(
                              '試験形式',
                              _selectedExamType,
                              ExamType.values,
                              (value) {
                                setState(() {
                                  _selectedExamType = value;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null ? '試験形式を選択してください' : null,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _teacherFeatureController,
                              labelText: '教員特徴 (例: 丁寧、面白い、厳しい)',
                              hintText: '例: 丁寧、質問しやすい',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _commentController,
                              labelText: 'コメント (詳細なレビュー)',
                              hintText: '講義内容、課題量、テスト難易度など、自由に記入してください。',
                              maxLines: 5,
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'コメントは必須です'
                                          : null,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _tagsController,
                              labelText: 'タグ (カンマ区切り)',
                              hintText: '例: 楽単, レポート多め, オンライン完結',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 30),

                            // 投稿ボタン
                            ElevatedButton.icon(
                              onPressed: _submitReview,
                              icon: const Icon(Icons.send, color: Colors.white),
                              label: const Text(
                                'レビューを投稿する',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'NotoSansJP',
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.blueAccent[100]!,
                                    width: 1.5,
                                  ),
                                ),
                                elevation: 4,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // レビューランキングへのボタン (変更なし)
                            _buildNavigateButton(
                              context,
                              'レビューランキングを見る',
                              Icons.emoji_events,
                              const CreditResultPage(
                                rankingType: 'satisfaction',
                              ), // ここも調整
                              buttonColor: Colors.purple[700],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'NotoSansJP',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLectureSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('レビュー対象講義の選択', Icons.class_),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent[100]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedLectureName.isEmpty ? null : _selectedLectureName,
              hint: const Text(
                '講義を選択してください',
                style: TextStyle(color: Colors.grey),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
              iconSize: 24,
              elevation: 16,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLectureName = newValue!;
                  // 選択された講義に対応する教員名も自動設定（仮のロジック）
                  _selectedTeacherName =
                      _dynamicLectures.firstWhere(
                        (lec) => lec['name'] == newValue,
                      )['teacher'] ??
                      '';
                });
              },
              items:
                  _dynamicLectures.map<DropdownMenuItem<String>>((
                    Map<String, String> lecture,
                  ) {
                    return DropdownMenuItem<String>(
                      value: lecture['name'],
                      child: Text('${lecture['name']} (${lecture['teacher']})'),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLectureDisplay() {
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
              'レビュー対象講義:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
                fontFamily: 'NotoSansJP',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedLectureName.isNotEmpty ? _selectedLectureName : '未選択',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
                fontFamily: 'NotoSansJP',
              ),
            ),
            Text(
              _selectedTeacherName.isNotEmpty ? _selectedTeacherName : '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontFamily: 'NotoSansJP',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(
    String label,
    double rating,
    ValueChanged<double> onRatingUpdate, {
    IconData icon = Icons.star,
    Color activeColor = Colors.amber,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'NotoSansJP',
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: RatingBar.builder(
            initialRating: rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(icon, color: activeColor),
            onRatingUpdate: onRatingUpdate,
          ),
        ),
        Center(
          child: Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>(
    String labelText,
    T? value,
    List<T> items,
    ValueChanged<T?> onChanged, {
    String? Function(T?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey[700]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
        iconSize: 24,
        elevation: 16,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        onChanged: onChanged,
        validator: validator,
        items:
            items.map<DropdownMenuItem<T>>((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(_formatEnum(item)),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(
            0,
          ), // Set to transparent as container provides color
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        validator: validator,
      ),
    );
  }

  // 共通のナビゲーションボタン（CreditInputPage内で使用する分のみ残す）
  Widget _buildNavigateButton(
    BuildContext context,
    String label,
    IconData icon,
    Widget destination, {
    Color? buttonColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'NotoSansJP',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: (buttonColor ?? Colors.blueAccent).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
