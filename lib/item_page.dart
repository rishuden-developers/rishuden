import 'package:flutter/material.dart';
import 'item_change_page.dart'; // 着せ替えページ
import 'item_shop_page.dart'; // アイテム交換所ページ
import 'dart:ui'; // BackdropFilter のために必要

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
            side: BorderSide(color: Colors.brown[200]!, width: 1.5),
          ),
          elevation: 5,
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'アイテム',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/item_bg.png'), // あなたの背景画像パス
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            color: Colors.black.withOpacity(0.2),
            child: Column(
              children: <Widget>[
                const SizedBox(height: kToolbarHeight + 20),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _buildMenuButton(
                          context,
                          '着せ替え',
                          Icons.accessibility_new,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ItemChangePage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildMenuButton(
                          context,
                          'アイテム交換所',
                          Icons.store,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ItemShopPage(),
                              ),
                            );
                          },
                        ),
                        // 他のアイテム関連機能へのボタンもここに追加
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: CommonBottomNavigation(
                    currentPage: AppPage.item,
                    parkIconAsset: 'assets/icons/park_icon.png',
                    parkIconActiveAsset: 'assets/icons/park_icon_active.png',
                    timetableIconAsset: 'assets/icons/timetable_icon.png',
                    timetableIconActiveAsset:
                        'assets/icons/timetable_icon_active.png',
                    creditReviewIconAsset: 'assets/icons/credit_review_icon.png',
                    creditReviewActiveAsset:
                        'assets/icons/credit_review_icon_active.png',
                    rankingIconAsset: 'assets/icons/ranking_icon.png',
                    rankingIconActiveAsset: 'assets/icons/ranking_icon_active.png',
                    itemIconAsset: 'assets/icons/item_icon.png',
                    itemIconActiveAsset: 'assets/icons/item_icon_active.png',
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
                          pageBuilder: (_, __, ___) => const CreditReviewPage(
                            lectureName: 'ダミー講義名',
                            teacherName: 'ダミー教員名', // 追加
                          ),
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
        ),
      ),
    );
  }
} 