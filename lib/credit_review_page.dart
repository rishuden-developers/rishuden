// credit_review_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ★レート表示に利用するパッケージをインポート (pubspec.yamlに追加が必要です)
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット (パスを確認してください)
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';

// ★★★★ 補足: flutter_rating_bar パッケージの追加 ★★★★
// pubspec.yaml ファイルの dependencies: の下に追加してください。
// dependencies:
//   flutter:
//     sdk: flutter
//   flutter_rating_bar: ^4.0.0 # 最新バージョンを確認してください
// ----------------------------------------------------

enum LectureFormat { faceToFace, onDemand, zoom, other }

enum AttendanceStrictness {
  flexible,
  everyTimeRollCall,
  attendancePoints,
  noAttendance,
}

enum ExamType { report, written, attendanceBased, none, other }

class CreditReviewPage extends StatefulWidget {
  final String? selectedLectureName; // どの講義のレビューかを受け取る
  const CreditReviewPage({super.key, this.selectedLectureName});

  @override
  State<CreditReviewPage> createState() => _CreditReviewPageState();
}

class _CreditReviewPageState extends State<CreditReviewPage> {
  final _formKey = GlobalKey<FormState>();
  double _overallSatisfaction = 3.0; // 総合満足度
  double _easiness = 3.0; // 楽単度
  LectureFormat? _selectedLectureFormat; // 講義形式
  AttendanceStrictness? _selectedAttendanceStrictness; // 出席の厳しさ
  ExamType? _selectedExamType; // 試験の形式
  final TextEditingController _teacherFeatureController =
      TextEditingController(); // 教員の特徴
  final TextEditingController _commentController =
      TextEditingController(); // おすすめコメント

  @override
  void dispose() {
    _teacherFeatureController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // ★★★ タグ選択用のダミーデータ ★★★
  final List<String> _availableTags = [
    '#楽単',
    '#テストなし',
    '#出席ゆるい',
    '#課題少なめ',
    '#レポートのみ',
    '#グループワーク',
    '#アクティブラーニング',
    '#過去問必須',
    '#教員が優しい',
    '#教員が厳しい',
    '#教員が面白い',
    '#オンライン完結',
    '#対面推奨',
    '#板書が丁寧',
    '#スライド分かりやすい',
    '#ディスカッション多め',
  ];
  final Set<String> _selectedTags = {};

  Widget _buildRatingSection({
    required String title,
    required double initialRating,
    required ValueChanged<double> onRatingUpdate,
    required String helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        RatingBar.builder(
          initialRating: initialRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 30.0,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder:
              (context, _) => const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: onRatingUpdate,
        ),
        Text(
          helperText,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdownSection<T>({
    required String title,
    required T? value,
    required ValueChanged<T?> onChanged,
    required List<DropdownMenuItem<T>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orangeAccent[100]!, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.brown),
              hint: const Text(
                '選択してください',
                style: TextStyle(color: Colors.grey),
              ),
              onChanged: onChanged,
              items: items,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.orangeAccent[100]!,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.orangeAccent[100]!,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.brown, width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTagSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タグ付け',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.brown[700],
                    ),
                  ),
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
                  backgroundColor: Colors.white.withOpacity(0.9),
                  selectedColor: Colors.brown[700]?.withOpacity(0.9),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Colors.orangeAccent[100]!,
                      width: 1.0,
                    ),
                  ),
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _submitReview() {
    if (_formKey.currentState!.validate()) {
      // フォームのバリデーションが通ったらデータを処理
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('レビューを投稿中...')));

      // ここでFirestoreなどのバックエンドにデータを送信する処理
      // 例:
      // final reviewData = {
      //   'lectureName': widget.selectedLectureName,
      //   'overallSatisfaction': _overallSatisfaction,
      //   'easiness': _easiness,
      //   'lectureFormat': _selectedLectureFormat?.name,
      //   'attendanceStrictness': _selectedAttendanceStrictness?.name,
      //   'examType': _selectedExamType?.name,
      //   'teacherFeature': _teacherFeatureController.text,
      //   'comment': _commentController.text,
      //   'tags': _selectedTags.toList(),
      //   'timestamp': DateTime.now().toIso8601String(),
      //   // ユーザー情報（学部・学年など）も追加
      //   // 'userId': currentUserId,
      //   // 'userFaculty': userFaculty,
      //   // 'userGrade': userGrade,
      // };
      // print(reviewData);

      // 投稿成功後、CreditInputPageなどへ戻る
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxContentWidth = 600.0;
    final double bottomNavBarHeight = 95.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          widget.selectedLectureName != null
              ? '${widget.selectedLectureName}のレビューを投稿'
              : '講義レビュー投稿',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          fontFamily: 'misaki',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBar: CommonBottomNavigation(context: context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ranking_guild_background.png'), // 背景画像
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: bottomNavBarHeight + 20, // フッターと下部のパディング
                  top: AppBar().preferredSize.height + 20, // AppBarの下の余白
                  left: 24,
                  right: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${widget.selectedLectureName ?? '講義'}の\nレビューを投稿しよう！',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'misaki',
                          shadows: [
                            Shadow(
                              blurRadius: 6.0,
                              color: Colors.black54,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildRatingSection(
                        title: '総合満足度',
                        initialRating: _overallSatisfaction,
                        onRatingUpdate: (rating) {
                          setState(() => _overallSatisfaction = rating);
                        },
                        helperText: '（★1: 不満 〜 ★5: 満足）',
                      ),
                      _buildRatingSection(
                        title: '楽単度',
                        initialRating: _easiness,
                        onRatingUpdate: (rating) {
                          setState(() => _easiness = rating);
                        },
                        helperText: '（★1: 地獄 〜 ★5: 天国）',
                      ),
                      _buildDropdownSection<ExamType>(
                        title: '試験の有無・形式',
                        value: _selectedExamType,
                        onChanged: (value) {
                          setState(() => _selectedExamType = value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: ExamType.report,
                            child: Text('レポート'),
                          ),
                          DropdownMenuItem(
                            value: ExamType.written,
                            child: Text('筆記試験'),
                          ),
                          DropdownMenuItem(
                            value: ExamType.attendanceBased,
                            child: Text('出席点のみ'),
                          ),
                          DropdownMenuItem(
                            value: ExamType.none,
                            child: Text('試験なし'),
                          ),
                          DropdownMenuItem(
                            value: ExamType.other,
                            child: Text('その他'),
                          ),
                        ],
                      ),
                      _buildDropdownSection<AttendanceStrictness>(
                        title: '出席の厳しさ',
                        value: _selectedAttendanceStrictness,
                        onChanged: (value) {
                          setState(() => _selectedAttendanceStrictness = value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: AttendanceStrictness.flexible,
                            child: Text('自由'),
                          ),
                          DropdownMenuItem(
                            value: AttendanceStrictness.everyTimeRollCall,
                            child: Text('毎回点呼'),
                          ),
                          DropdownMenuItem(
                            value: AttendanceStrictness.attendancePoints,
                            child: Text('出席点あり'),
                          ),
                          DropdownMenuItem(
                            value: AttendanceStrictness.noAttendance,
                            child: Text('出席なし'),
                          ),
                        ],
                      ),
                      _buildDropdownSection<LectureFormat>(
                        title: '講義の形式',
                        value: _selectedLectureFormat,
                        onChanged: (value) {
                          setState(() => _selectedLectureFormat = value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: LectureFormat.faceToFace,
                            child: Text('対面'),
                          ),
                          DropdownMenuItem(
                            value: LectureFormat.onDemand,
                            child: Text('オンデマンド'),
                          ),
                          DropdownMenuItem(
                            value: LectureFormat.zoom,
                            child: Text('Zoom（オンライン）'),
                          ),
                          DropdownMenuItem(
                            value: LectureFormat.other,
                            child: Text('その他'),
                          ),
                        ],
                      ),
                      _buildTextField(
                        controller: _teacherFeatureController,
                        label: '教員の特徴',
                        hintText: '（例：優しい、厳しい、おもしろい、聞き取りにくい、など）',
                      ),
                      _buildTextField(
                        controller: _commentController,
                        label: 'おすすめコメント',
                        hintText: '（この講義について、自由にコメントしてください）',
                        maxLines: 5,
                      ),
                      _buildTagSelection(),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.amberAccent[100]!,
                              width: 2,
                            ),
                          ),
                          elevation: 6,
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                        child: const Text('レビューを投稿する'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
