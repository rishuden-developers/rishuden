// credit_input_page.dart
import 'package:flutter/material.dart';
import 'credit_explore_page.dart';
import 'credit_result_page.dart';
import 'credit_review_page.dart';
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット (パスを確認してください)
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';

class CreditInputPage extends StatefulWidget {
  const CreditInputPage({super.key});

  @override
  State<CreditInputPage> createState() => _CreditInputPageState();
}

class _CreditInputPageState extends State<CreditInputPage> {
  // ★ ダミーの履修講義リスト ★
  // 実際にはユーザーデータやデータベースから取得します
  List<String> _enrolledLectures = [
    '離散数学基礎',
    'データ構造とアルゴリズム',
    '線形代数学Ⅰ',
    '情報倫理',
    '英語リーディング',
  ];

  // 共通のナビゲーションボタン
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
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? Colors.brown[700]?.withOpacity(0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.orangeAccent[100]!, width: 1.5),
          ),
          elevation: 6,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansJP',
          ),
        ),
      ),
    );
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
        title: const Text('履修講義管理'),
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
        currentPage: AppPage.creditReview, // CreditInputPageはcreditReviewアイコンに紐付け
                parkIconActiveAsset: 'assets/button_park_icon_active.png',
        parkIconAsset: 'assets/button_park_icon.png',
        timetableIconActiveAsset: 'assets/button_timetable_active.png',
        timetableIconAsset: 'assets/button_timetable.png',
        creditReviewActiveAsset: 'assets/button_unit_review_active.png',
        creditReviewIconAsset: 'assets/button_unit_review.png',
        rankingIconActiveAsset: 'assets/button_ranking_active.png',
        rankingIconAsset: 'assets/button_ranking.png',
        itemIconActiveAsset: 'assets/button_dressup_active.png',
        itemIconAsset: 'assets/button_dressup.png',
        onParkTap: () {
          Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const ParkPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero,));
        },
        onTimetableTap: () {
          Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const TimeSchedulePage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero,));
        },
        onRankingTap: () {
          Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const RankingPage(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero,));
        },
        onCreditReviewTap: () {
          // 現在のページなので何もしない
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
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: bottomNavBarHeight + 20,
                  top: AppBar().preferredSize.height + 20,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'あなたの履修講義',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansJP',
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
                    // 講義リスト
                    if (_enrolledLectures.isNotEmpty)
                      Column(
                        children: _enrolledLectures.map((lectureName) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            color: Colors.white.withOpacity(0.95),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.brown[300]!, width: 1.0),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.class_, color: Colors.brown[700]),
                              title: Text(
                                lectureName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[800],
                                ),
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () {
                                  // レビュー投稿ページへ遷移し、講義名を渡す
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreditReviewPage(selectedLectureName: lectureName),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.edit, size: 18, color: Colors.white),
                                label: const Text('レビュー投稿', style: TextStyle(fontSize: 12, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  minimumSize: Size.zero, // Add this to remove default minimum size
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'まだ履修講義が登録されていません。\n下のボタンから講義を検索して追加しましょう！',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 40),
                    // レビュー投稿機能（講義を選択して投稿する）
                    // ここでは、ユーザーが講義を検索して選択し、その講義のレビューを投稿する流れを想定
                    _buildNavigateButton(
                      context,
                      '新しい講義のレビューを投稿する',
                      Icons.library_add,
                      const CreditExplorePage(), // 講義検索ページに遷移
                      buttonColor: Colors.teal[700],
                    ),
                    const SizedBox(height: 20),
                    // レビュー一覧（CreditExplorePage） - 全てのレビューを見る
                    _buildNavigateButton(
                      context,
                      '全てのレビューを見る',
                      Icons.list,
                      const CreditExplorePage(),
                    ),
                    const SizedBox(height: 20),
                    // レビューランキング（CreditResultPage）
                    _buildNavigateButton(
                      context,
                      'レビューランキングを見る',
                      Icons.emoji_events,
                      const CreditResultPage(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}