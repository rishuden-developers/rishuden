// credit_result_page.dart
import 'package:flutter/material.dart';
import 'credit_review_page.dart'; // レビュー詳細ページへの遷移用
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'credit_explore_page.dart'; // ボトムナビゲーション用
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ★レート表示に利用するパッケージをインポート

class LectureResult {
  final String name;
  final String teacher;
  final double overallSatisfaction;
  final double easiness;
  final int reviewCount;
  final String faculty;
  final String description; // 講義概要など

  LectureResult({
    required this.name,
    required this.teacher,
    required this.overallSatisfaction,
    required this.easiness,
    required this.reviewCount,
    required this.faculty,
    this.description = '講義の概要がここに表示されます。',
  });
}

class CreditResultPage extends StatefulWidget {
  final String? searchQuery; // 検索クエリがあれば受け取る
  final String? filterFaculty; // 学部フィルター
  final String? filterTag; // タグフィルター
  final String? filterCategory; // 種類フィルター (必修/選択)
  final String? filterDayOfWeek; // 曜日フィルター
  final String? rankingType; // ランキングの種類 ('easiness', 'satisfaction', 'faculty_specific')

  const CreditResultPage({
    super.key,
    this.searchQuery,
    this.filterFaculty,
    this.filterTag,
    this.filterCategory,
    this.filterDayOfWeek,
    this.rankingType,
  });

  @override
  State<CreditResultPage> createState() => _CreditResultPageState();
}

class _CreditResultPageState extends State<CreditResultPage> {
  List<LectureResult> _allLectures = [];
  List<LectureResult> _filteredLectures = [];

  @override
  void initState() {
    super.initState();
    _allLectures = _generateDummyLectures();
    _applyFiltersAndRankings();
  }

  // ダミーの講義データ生成
  List<LectureResult> _generateDummyLectures() {
    return [
      LectureResult(
        name: '線形代数学Ⅰ',
        teacher: '山田 太郎',
        overallSatisfaction: 4.5,
        easiness: 4.0,
        reviewCount: 35,
        faculty: '情報科学部',
        description: '線形代数の基礎を学ぶ講義です。行列、ベクトル、線形変換について学習します。',
      ),
      LectureResult(
        name: 'データ構造とアルゴリズム',
        teacher: '佐藤 花子',
        overallSatisfaction: 4.2,
        easiness: 3.8,
        reviewCount: 42,
        faculty: '情報科学部',
        description: 'プログラミングの効率を上げるためのデータ構造とアルゴリズムを学びます。',
      ),
      LectureResult(
        name: '経済学原論',
        teacher: '田中 健太',
        overallSatisfaction: 3.9,
        easiness: 3.5,
        reviewCount: 28,
        faculty: '経済学部',
        description: '経済学の基本的な概念と理論を学びます。マクロ経済とミクロ経済の両方を扱います。',
      ),
      LectureResult(
        name: '日本文学史',
        teacher: '鈴木 文子',
        overallSatisfaction: 4.8,
        easiness: 4.2,
        reviewCount: 15,
        faculty: '文学部',
        description: '上代から近現代までの日本文学の歴史を概観します。',
      ),
      LectureResult(
        name: '物理学実験',
        teacher: '渡辺 剛',
        overallSatisfaction: 3.7,
        easiness: 3.0,
        reviewCount: 20,
        faculty: '理学部',
        description: '基本的な物理現象を実験を通して学びます。レポート提出が多いです。',
      ),
      LectureResult(
        name: '情報倫理',
        teacher: '山田 太郎', // 同じ教員名でテスト
        overallSatisfaction: 4.0,
        easiness: 4.5,
        reviewCount: 18,
        faculty: '情報科学部',
        description: '情報化社会における倫理的な問題を考察します。',
      ),
      LectureResult(
        name: '現代社会論',
        teacher: '高橋 涼子',
        overallSatisfaction: 4.1,
        easiness: 3.9,
        reviewCount: 25,
        faculty: '総合科学部',
        description: '現代社会が抱える様々な問題について多角的に分析します。',
      ),
      LectureResult(
        name: '国際法入門',
        teacher: '伊藤 大輔',
        overallSatisfaction: 4.3,
        easiness: 3.7,
        reviewCount: 10,
        faculty: '法学部',
        description: '国際社会における法の役割と基本原則を学びます。',
      ),
    ];
  }

  void _applyFiltersAndRankings() {
    _filteredLectures = _allLectures.where((lecture) {
      bool matches = true;

      // 検索クエリフィルター
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        final query = widget.searchQuery!.toLowerCase();
        matches = matches &&
            (lecture.name.toLowerCase().contains(query) ||
                lecture.teacher.toLowerCase().contains(query));
      }

      // 学部フィルター
      if (widget.filterFaculty != null && widget.filterFaculty!.isNotEmpty) {
        matches = matches && lecture.faculty == widget.filterFaculty;
      }

      // TODO: ここにタグ、カテゴリ、曜日のフィルタリングロジックを追加
      // 現在のLectureResultにはこれらのプロパティがないため、ダミーデータと合わせて追加が必要です。
      // 例: if (widget.filterTag != null && lecture.tags.contains(widget.filterTag))

      return matches;
    }).toList();

    // ランキングの適用
    if (widget.rankingType != null) {
      if (widget.rankingType == 'easiness') {
        _filteredLectures.sort((a, b) => b.easiness.compareTo(a.easiness));
      } else if (widget.rankingType == 'satisfaction') {
        _filteredLectures
            .sort((a, b) => b.overallSatisfaction.compareTo(a.overallSatisfaction));
      } else if (widget.rankingType == 'faculty_specific') {
        // 学部フィルターは既に適用されているので、ここではランキングのみ
        // 例えば、満足度順にソート
        _filteredLectures
            .sort((a, b) => b.overallSatisfaction.compareTo(a.overallSatisfaction));
      }
    }
  }

  String _getPageTitle() {
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      return '検索結果: "${widget.searchQuery}"';
    } else if (widget.rankingType == 'easiness') {
      return '楽単ランキング';
    } else if (widget.rankingType == 'satisfaction') {
      return '総合満足度ランキング';
    } else if (widget.rankingType == 'faculty_specific') {
      return '${widget.filterFaculty ?? '全学部'} 注目授業';
    } else if (widget.filterFaculty != null && widget.filterFaculty!.isNotEmpty) {
      return '${widget.filterFaculty} の講義';
    }
    return '講義一覧';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
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
      bottomNavigationBar: CommonBottomNavigation(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo[800]!,
              Colors.indigo[600]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _filteredLectures.isEmpty
                ? Center(
                    child: Text(
                      widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                          ? '「${widget.searchQuery}」に一致する講義は見つかりませんでした。'
                          : '講義が見つかりませんでした。',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredLectures.length,
                    itemBuilder: (context, index) {
                      final lecture = _filteredLectures[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreditReviewPage(
                                  lectureName: lecture.name,
                                  teacherName: lecture.teacher,
                                  initialDescription: lecture.description,
                                  initialOverallSatisfaction: lecture.overallSatisfaction,
                                  initialEasiness: lecture.easiness,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lecture.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo[900],
                                    fontFamily: 'NotoSansJP',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lecture.teacher,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    fontFamily: 'NotoSansJP',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    RatingBarIndicator(
                                      rating: lecture.overallSatisfaction,
                                      itemBuilder: (context, index) => const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      itemCount: 5,
                                      itemSize: 20.0,
                                      direction: Axis.horizontal,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      lecture.overallSatisfaction.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.sentiment_satisfied,
                                        color: Colors.lightGreen, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '楽単度: ${lecture.easiness.toStringAsFixed(1)}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    'レビュー数: ${lecture.reviewCount}件',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
  }
  