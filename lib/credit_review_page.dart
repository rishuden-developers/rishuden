import 'package:flutter/material.dart';
import 'credit_explore_page.dart';
// import 'credit_post_page.dart'; // 不要なので削除

// 共通フッターと遷移先ページのインポート
import 'common_bottom_navigation.dart';
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';

class CreditReviewPage extends StatelessWidget {
  const CreditReviewPage({super.key});

  // メニューボタンの共通スタイル
  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 26, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo[800]?.withOpacity(0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.lightBlue[200]!, width: 1.5),
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
    final double bottomNavBarHeight = 95.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text('履修口コミ'),
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
      bottomNavigationBar: null,

      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/ranking_guild_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

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
                        20,
                    bottom: bottomNavBarHeight + 20,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '履修の知恵を共有しよう！',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'misaki',
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

                      // ★★★ エラーの原因だった「口コミを投稿する」ボタンを削除 ★★★
                      _buildMenuButton(context, '口コミを探索する', Icons.search, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreditExplorePage(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CommonBottomNavigation(
              currentPage: AppPage.creditReview,

              parkIconAsset: 'assets/button_park_icon.png',
              parkIconActiveAsset: 'assets/button_park_icon_active.png',
              timetableIconAsset: 'assets/button_timetable.png',
              timetableIconActiveAsset: 'assets/button_timetable_active.png',
              creditReviewIconAsset: 'assets/button_unit_review.png',
              creditReviewActiveAsset: 'assets/button_unit_review_active.png',
              rankingIconAsset: 'assets/button_ranking.png',
              rankingIconActiveAsset: 'assets/button_ranking_active.png',
              itemIconAsset: 'assets/button_dressup.png',
              itemIconActiveAsset: 'assets/button_dressup_active.png',

              onParkTap:
                  () => Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ParkPage(),
                      transitionDuration: Duration.zero,
                    ),
                  ),
              onTimetableTap:
                  () => Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const TimeSchedulePage(),
                      transitionDuration: Duration.zero,
                    ),
                  ),
              onCreditReviewTap: () => print("Already on Credit Review Page"),
              onRankingTap:
                  () => Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const RankingPage(),
                      transitionDuration: Duration.zero,
                    ),
                  ),
              onItemTap:
                  () => Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ItemPage(),
                      transitionDuration: Duration.zero,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
