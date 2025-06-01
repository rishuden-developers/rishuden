import 'package:flutter/material.dart'; // ★★★ Flutterの基本的なウィジェットを使うために必須 ★★★
import 'credit_explore_page.dart'; // 遷移先のページ
import 'common_bottom_navigation.dart'; // ★ 共通フッターウィジェット (パスを確認してください)
import 'park_page.dart'; // 以下、フッターから遷移する可能性のあるページ
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';

class CreditReviewPage extends StatelessWidget {
  const CreditReviewPage({super.key});

  // ボタンの共通ウィジェット
  // このウィジェット内で context を使うので、引数として渡すか、
  // build メソッドの context を利用する形にします。
  // CreditReviewPageがStatelessWidgetなので、このメソッドもcontextを引数に取る形でOKです。
  Widget _buildNavigateButton(
    BuildContext context, // contextを引数で受け取る
    String text,
    IconData? icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
      child: ElevatedButton.icon(
        icon:
            icon != null
                ? Icon(icon, size: 24, color: Colors.white)
                : SizedBox.shrink(), // アイコンの色も指定
        label: Text(text, style: TextStyle(color: Colors.white)), // ボタンのテキスト色
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[700]?.withOpacity(0.9),
          foregroundColor: Colors.white, // Rippleエフェクトなどの色
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orangeAccent[100]!, width: 1.5),
          ),
          elevation: 6,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansJP', // フォントファミリー指定例
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
      extendBody: true, // ★ bodyをbottomNavigationBarの背後にも拡張

      appBar: AppBar(
        title: const Text('単位レビュー'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // 戻るボタンの色を白に
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansJP',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBar: CommonBottomNavigation(
        currentPage: AppPage.creditReview,
        // ★ 各ボタンの画像アセットパスを実際のパスに置き換えてください ★
        parkIconAsset: 'assets/button_park_icon.png', // 例
        timetableIconAsset: 'assets/button_timetable.png',
        creditReviewIconAsset: 'assets/button_unit_review.png', // アクティブ用画像があれば
        rankingIconAsset: 'assets/button_ranking.png',
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
        onRankingTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const RankingPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              // ParkPageが引数を期待している場合は settings を設定
              // settings: RouteSettings(arguments: { ... }),
            ),
          );
        },
        onCreditReviewTap: () {
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
                padding: EdgeInsets.only(
                  bottom: bottomNavBarHeight, // フッターの高さ分のパディング
                  top:
                      AppBar().preferredSize.height +
                      20, // AppBarの下の余白 (extendBodyBehindAppBarのため)
                  left: 16,
                  right: 16, // 左右の基本的なパディング
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SizedBox(height: AppBar().preferredSize.height + 20), // Paddingで調整したので不要かも
                    const Text(
                      '単位レビュー探索',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
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
                    const SizedBox(height: 50),
                    _buildNavigateButton(
                      // contextを渡す
                      context,
                      '講義を検索する',
                      Icons.search,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreditExplorePage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
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
