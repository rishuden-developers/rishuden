import 'package:flutter/material.dart';
import 'item_change_page.dart'; // 着せ替えページ
import 'item_shop_page.dart'; // アイテム交換所ページ

// ★★★ 共通フッターと遷移先ページをインポート ★★★
import 'common_bottom_navigation.dart'; // common_bottom_navigation.dart のパスを正しく指定してください
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'credit_review_page.dart';
import 'ranking_page.dart';
// ItemPage自身は不要

class ItemPage extends StatelessWidget {
  const ItemPage({super.key});

  // ボタンの共通スタイルを適用するためのヘルパーメソッド
  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon, // アイコンを追加
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 26, color: Colors.white),
        label: Text(text, style: TextStyle(color: Colors.white)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[600]?.withOpacity(0.9), // 少し色味を調整
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.amber[200]!, width: 1.5),
          ),
          elevation: 6,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'misaki',
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
        title: const Text('アイテム・着せ替え'), // ★ タイトル変更
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'misaki',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ★★★ 共通フッターナビゲーションを追加 ★★★
      bottomNavigationBar: CommonBottomNavigation(
        currentPage: AppPage.item, // 現在のページを指定
        // ★ 各ボタンの画像アセットパス (実際のパスに置き換えてください) ★
        parkIconAsset: 'assets/button_park_icon.png',
        timetableIconAsset: 'assets/button_timetable.png',
        creditReviewIconAsset: 'assets/button_unit_review.png',
        rankingIconAsset: 'assets/button_ranking.png',
        itemIconAsset: 'assets/button_dressup.png', // アクティブ用画像があれば

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
        onItemTap: () {
          print("Already on Ranking Page");
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
      ),

      // ★★★ ここまで共通フッター ★★★
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            // ★ 背景画像を他のページと合わせるか、専用のものにするか (例: ParkPageの背景) ★
            image: AssetImage('assets/ranking_guild_background.png'),
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
                  top:
                      AppBar().preferredSize.height +
                      MediaQuery.of(context).padding.top +
                      40, // AppBarとステータスバーの高さ + 余白
                  bottom: bottomNavBarHeight + 40, // ★ フッターの高さ + 余白
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'アイテムと着せ替え', // ★ ページタイトル
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
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
                    const SizedBox(height: 50),
                    _buildMenuButton(
                      // ★ ヘルパーメソッド名変更、アイコン追加
                      context,
                      'キャラクター着せ替え',
                      Icons.accessibility_new, // アイコン例
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemChangePage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                    _buildMenuButton(
                      // ★ ヘルパーメソッド名変更、アイコン追加
                      context,
                      'アイテム交換所',
                      Icons.storefront, // アイコン例
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemShopPage(),
                          ),
                        );
                      },
                    ),
                    // 必要であれば他の要素もここに追加
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
