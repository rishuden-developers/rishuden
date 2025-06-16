import 'package:flutter/material.dart';
import 'item_change_page.dart'; // 着せ替えページ
import 'item_shop_page.dart'; // アイテム交換所ページ
import 'dart:ui'; // すりガラス効果(ImageFilter)のために必要

// ★★★ 共通フッターと遷移先ページをインポート ★★★
import 'common_bottom_navigation.dart'; // common_bottom_navigation.dart のパスを正しく指定してください
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'credit_review_page.dart';
import 'ranking_page.dart';
import 'mail_page.dart';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ranking_guild_background.png'),
            fit: BoxFit.cover,
          ),
        ),
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

            // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
            // ★★★ レイヤー2: 後ろを暗くするオーバーレイ（この部分を追加） ★★★
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // この数値(0.0~1.0)で暗さを調整
              ),
            ),
            // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

            // --- レイヤー3: 常に表示するすりガラスのコンテンツ ---
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // コンテンツの高さに合わせる
                        children: [
                          const Text(
                            'Ver.2.0で実装予定！',
                            style: TextStyle(
                              fontFamily: 'misaki',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '現在、アプリのバージョン2.0を開発中です。\nみんなが欲しい機能や改善点など、ぜひご意見をお聞かせください！',
                            style: TextStyle(
                              fontFamily: 'misaki',
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontFamily: 'misaki',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              // MailPageに画面遷移する
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MailPage(),
                                ),
                              );
                            },
                            child: const Text('ご意見を送る'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- レイヤー4: フローティングナビゲーションバー (最前面に配置) ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CommonBottomNavigation(context: context),
            ),
          ],
        ),
      ),
    );
  }
}
