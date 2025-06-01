import 'package:flutter/material.dart';
import 'ranking_trending_page.dart'; // 急上昇ランキングページ
import 'ranking_explore_page.dart'; // 検索ランキングページ
import 'ranking_vote_page.dart'; // 投票ランキングページ

// ★★★ 共通フッターと遷移先ページをインポート ★★★
import 'common_bottom_navigation.dart'; // common_bottom_navigation.dart のパスを正しく指定してください
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'credit_review_page.dart';
// import 'ranking_page.dart'; // 自分自身は不要
import 'item_page.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  // ランキングボタンの共通ウィジェット (変更なし)
  Widget _buildRankingButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 40.0,
        vertical: 8.0,
      ), // ボタン間の縦のスペースも少し調整
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[700]?.withOpacity(0.9), // 少し透明度を追加
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // 角丸を少し調整
            side: BorderSide(
              color: Colors.orangeAccent[100]!,
              width: 1.5,
            ), // 枠線の色を調整
          ),
          elevation: 6, // 影を少し調整
          textStyle: const TextStyle(
            fontSize: 18, // テキストサイズ調整
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansJP', // フォント指定例
          ),
        ),
        child: Text(text),
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
      extendBody: true, // ★ bodyをbottomNavigationBarの背後にも拡張

      appBar: AppBar(
        title: const Text('ランキング'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          // AppBarのテキストスタイル
          fontFamily: 'NotoSansJP',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ★★★ 共通フッターナビゲーションを追加 ★★★
      bottomNavigationBar: CommonBottomNavigation(
        currentPage: AppPage.ranking, // 現在のページを指定
        parkIconAsset: 'assets/button_park_icon.png',
        timetableIconAsset: 'assets/button_timetable.png',
        creditReviewIconAsset: 'assets/button_unit_review.png',
        rankingIconAsset: 'assets/button_ranking.png', // アクティブ用画像があれば
        itemIconAsset: 'assets/button_dressup.png',

        onParkTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => const ParkPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              // ParkPageが引数を期待している場合は settings を設定
              // settings: RouteSettings(arguments: { ... }),
            ),
          );
        },
        onTimetableTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const TimeSchedulePage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              // ParkPageが引数を期待している場合は settings を設定
              // settings: RouteSettings(arguments: { ... }),
            ),
          );
        },
        onCreditReviewTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const CreditReviewPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              // ParkPageが引数を期待している場合は settings を設定
              // settings: RouteSettings(arguments: { ... }),
            ),
          );
        },
        onRankingTap: () {
          print("Already on Ranking Page");
        },
        onItemTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => const ItemPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              // ParkPageが引数を期待している場合は settings を設定
              // settings: RouteSettings(arguments: { ... }),
            ),
          );
        },
      ),

      // ★★★ ここまで共通フッター ★★★
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
          // ステータスバーやノッチを避ける
          bottom: false, // bottomNavigationBarがあるので下はSafeAreaしない
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                // コンテンツがはみ出る場合にスクロール可能に
                padding: EdgeInsets.only(
                  // AppBarとステータスバーの高さ + 少し余白
                  top:
                      AppBar().preferredSize.height +
                      MediaQuery.of(context).padding.top +
                      20,
                  bottom: bottomNavBarHeight + 20, // ★ フッターの高さ + 少し余白
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SizedBox(height: AppBar().preferredSize.height + 20), // Paddingで調整
                    const Text(
                      'ランキングへようこそ！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansJP',
                        shadows: [
                          Shadow(
                            blurRadius: 5.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildRankingButton(context, '急上昇ランキング', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RankingTrendingPage(),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    _buildRankingButton(context, '検索', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RankingExplorePage(),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    _buildRankingButton(context, '投票', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RankingVotePage(),
                        ),
                      );
                    }),
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
