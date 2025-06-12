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

  // ★★★ ItemPageのbuildメソッド全体をこちらに置き換えてください ★★★
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxContentWidth = 600.0;
    // CommonBottomNavigationの高さに合わせて調整
    final double bottomNavBarHeight = 95.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,

      appBar: AppBar(
        title: const Text('アイテム・着せ替え'),
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

      // ★★★ 1. ここにあった bottomNavigationBar プロパティは削除します ★★★
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ranking_guild_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        // ★★★ 2. Containerの子をStackにして、コンテンツとナビゲーションバーを重ねます ★★★
        child: Stack(
          children: [
            // --- レイヤー1: 元々のページコンテンツ ---
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top:
                          AppBar().preferredSize.height +
                          MediaQuery.of(context).padding.top +
                          40,
                      bottom: bottomNavBarHeight + 40,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'アイテムと着せ替え',
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
                          context,
                          'キャラクター着せ替え',
                          Icons.accessibility_new,
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
                          context,
                          'アイテム交換所',
                          Icons.storefront,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemShopPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ★★★ 3. レイヤー2: フローティングナビゲーションバー ★★★
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CommonBottomNavigation(
                currentPage: AppPage.item, // このページの種別を指定
                // --- アイコンのパスを指定 ---
                parkIconAsset: 'assets/button_park.png',
                parkIconActiveAsset: 'assets/button_park_icon_active.png',
                timetableIconAsset: 'assets/button_timetable.png',
                timetableIconActiveAsset: 'assets/button_timetable_active.png',
                creditReviewIconAsset: 'assets/button_unit_review.png',
                creditReviewActiveAsset: 'assets/button_unit_review_active.png',
                rankingIconAsset: 'assets/button_ranking.png',
                rankingIconActiveAsset: 'assets/button_ranking_active.png',
                itemIconAsset: 'assets/button_dressup.png',
                itemIconActiveAsset: 'assets/button_dressup_active.png',

                // --- タップ時の処理 ---
                onParkTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ParkPage(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                onTimetableTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const TimeSchedulePage(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                onCreditReviewTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const CreditReviewPage(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                onRankingTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const RankingPage(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                // onItemTapは現在のページなので、何もしないか、リフレッシュ処理などを記述
                onItemTap: () {
                  print("Already on Item Page");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
