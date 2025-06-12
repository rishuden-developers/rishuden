// credit_result_page.dart
import 'package:flutter/material.dart';
import 'credit_review_page.dart'; // レビュー詳細ページへの遷移用
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット (パスを確認してください)
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';

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
  final String? rankingType; // ランキングの種類 ('easiness', 'satisfaction', 'faculty', 'nume')

  const CreditResultPage({
    super.key,
    this.searchQuery,
    this.filterFaculty,
    this.filterTag,
    this.rankingType,
  });

  @override
  State<CreditResultPage> createState() => _CreditResultPageState();
}

class _CreditResultPageState extends State<CreditResultPage> {
  String _pageTitle = '講義結果';
  List<LectureResult> _lectureResults = [];

  // ★ ダミーデータ ★
  final List<LectureResult> _allLectures = [
    LectureResult(name: 'データ構造とアルゴリズム', teacher: '山田 太郎', overallSatisfaction: 4.5, easiness: 4.0, reviewCount: 85, faculty: '情報科学部'),
    LectureResult(name: '基礎プログラミング演習', teacher: '佐藤 花子', overallSatisfaction: 4.2, easiness: 4.8, reviewCount: 120, faculty: '情報科学部'),
    LectureResult(name: '経済学原論', teacher: '田中 健一', overallSatisfaction: 3.8, easiness: 3.0, reviewCount: 50, faculty: '経済学部'),
    LectureResult(name: '線形代数学Ⅰ', teacher: '高橋 順子', overallSatisfaction: 3.5, easiness: 2.5, reviewCount: 70, faculty: '理学部'),
    LectureResult(name: '社会学入門', teacher: '伊藤 裕', overallSatisfaction: 4.0, easiness: 4.2, reviewCount: 60, faculty: '文学部'),
    LectureResult(name: '情報倫理', teacher: '中村 明', overallSatisfaction: 4.7, easiness: 4.9, reviewCount: 95, faculty: '情報科学部'),
    LectureResult(name: '応用物理学', teacher: '小林 大輔', overallSatisfaction: 3.0, easiness: 2.0, reviewCount: 40, faculty: '工学部'),
    LectureResult(name: '現代文明論', teacher: '加藤 恵', overallSatisfaction: 4.3, easiness: 3.5, reviewCount: 75, faculty: '総合科学部'),
    LectureResult(name: '離散数学基礎', teacher: '佐々木 徹', overallSatisfaction: 4.1, easiness: 2.8, reviewCount: 65, faculty: '情報科学部'),
    LectureResult(name: '国際関係論', teacher: '吉田 亜美', overallSatisfaction: 3.9, easiness: 3.2, reviewCount: 55, faculty: '法学部'),
  ];

  @override
  void initState() {
    super.initState();
    _filterAndSortLectures();
  }

  @override
  void didUpdateWidget(covariant CreditResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.filterFaculty != oldWidget.filterFaculty ||
        widget.filterTag != oldWidget.filterTag ||
        widget.rankingType != oldWidget.rankingType) {
      _filterAndSortLectures();
    }
  }

  void _filterAndSortLectures() {
    List<LectureResult> filteredList = List.from(_allLectures);

    // 検索クエリによるフィルタリング
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      filteredList = filteredList.where((lecture) =>
          lecture.name.toLowerCase().contains(widget.searchQuery!.toLowerCase()) ||
          lecture.teacher.toLowerCase().contains(widget.searchQuery!.toLowerCase())
      ).toList();
    }

    // 学部によるフィルタリング
    if (widget.filterFaculty != null && widget.filterFaculty!.isNotEmpty) {
      filteredList = filteredList.where((lecture) =>
          lecture.faculty == widget.filterFaculty
      ).toList();
    }

    // タグによるフィルタリング (現状のダミーデータでは実装が難しいのでスキップ)
    // if (widget.filterTag != null && widget.filterTag!.isNotEmpty) {
    //   filteredList = filteredList.where((lecture) =>
    //       lecture.tags.contains(widget.filterTag) // lectureResultにtagsプロパティが必要
    //   ).toList();
    // }

    // ランキングによるソートとタイトル設定
    switch (widget.rankingType) {
      case 'easiness':
        _pageTitle = '楽単ランキング';
        filteredList.sort((a, b) => b.easiness.compareTo(a.easiness));
        break;
      case 'satisfaction':
        _pageTitle = '人気講義TOP10';
        filteredList.sort((a, b) => b.overallSatisfaction.compareTo(a.overallSatisfaction));
        // TOP10に絞る
        if (filteredList.length > 10) {
          filteredList = filteredList.sublist(0, 10);
        }
        break;
      case 'faculty_specific': // 学部別の注目授業
        _pageTitle = '${widget.filterFaculty ?? '学部別'}注目授業';
        // フィルタリング済みなので、ここではソート順だけ考慮（例：レビュー数順）
        filteredList.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case 'nume': // 沼単ランキング
        _pageTitle = '沼単ランキング';
        filteredList.sort((a, b) => a.easiness.compareTo(b.easiness)); // 楽単度が低い順
        break;
      default:
        _pageTitle = (widget.searchQuery != null && widget.searchQuery!.isNotEmpty)
            ? '${widget.searchQuery}の検索結果'
            : '講義一覧';
        // デフォルトはレビュー数が多い順
        filteredList.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }
    setState(() {
      _lectureResults = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxContentWidth = 600.0;
    final double bottomNavBarHeight = 75.0; // CommonBottomNavigationの高さに合わせて調整

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(_pageTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          fontFamily: 'NotoSansJP',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBar: CommonBottomNavigation(
        currentPage: AppPage.ranking, // ResultページはRankingアイコンに紐付け
        parkIconAsset: 'assets/button_park_icon.png',
        timetableIconAsset: 'assets/button_timetable.png',
        creditReviewIconAsset: 'assets/button_unit_review.png',
        rankingIconAsset: 'assets/button_ranking.png',
        itemIconAsset: 'assets/button_dressup.png',
        onParkTap: () {
          Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const ParkPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero,));
        },
        onTimetableTap: () {
          Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const TimeSchedulePage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero,));
        },
        onRankingTap: () {
          // 現在のページなので何もしない
        },
        onCreditReviewTap: () {
          Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const CreditReviewPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero,));
        },
        onItemTap: () {
          Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const ItemPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero,));
        },
      ),
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
              child: _lectureResults.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.white70),
                        const SizedBox(height: 20),
                        Text(
                          widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                              ? '「${widget.searchQuery}」\nに一致する講義は見つかりませんでした。'
                              : '講義が見つかりませんでした。',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        top: AppBar().preferredSize.height + 20, // AppBarの下の余白
                        bottom: bottomNavBarHeight + 20, // フッターと下部のパディング
                        left: 16,
                        right: 16,
                      ),
                      itemCount: _lectureResults.length,
                      itemBuilder: (context, index) {
                        final lecture = _lectureResults[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          color: Colors.white.withOpacity(0.95),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.brown[300]!, width: 1.0),
                          ),
                          child: InkWell(
                            onTap: () {
                              // 講義の詳細レビューページへ遷移（今回はCreditReviewPageを流用して表示）
                              // 実際には詳細表示用の専用ページ (LectureDetailPageなど) が必要
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreditReviewPage(selectedLectureName: lecture.name),
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
                                      color: Colors.brown[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '担当: ${lecture.teacher} (${lecture.faculty})',
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '総合満足度: ${lecture.overallSatisfaction.toStringAsFixed(1)}',
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.sentiment_satisfied, color: Colors.lightGreen, size: 18),
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
      ),
    );
  }
}
