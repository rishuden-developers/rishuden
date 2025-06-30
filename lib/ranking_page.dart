import 'package:flutter/material.dart';
import 'ranking_trending_page.dart'; // 急上昇ランキングページ
import 'ranking_explore_page.dart'; // 検索ランキングページ
import 'ranking_vote_page.dart'; // 投票ランキングページ
import 'dart:ui'; // すりガラス効果(ImageFilter)のために必要

// ★★★ 共通フッターと遷移先ページをインポート ★★★
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'credit_review_page.dart';
import 'item_page.dart';
import 'mail_page.dart'; // MailPageをインポート

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  // ランキングボタンの共通ウィジェット
  Widget _buildRankingButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[700]?.withOpacity(0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orangeAccent[100]!, width: 1.5),
          ),
          elevation: 6,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansJP',
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
    final double bottomNavBarHeight = 95.0;

    return Container(
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
            bottom: true,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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

          // ★★★ レイヤー2: 後ろを暗くするオーバーレイ ★★★
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          // ★★★ レイヤー3: 常に表示するすりガラスのコンテンツ ★★★
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
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ver.2.0で実装予定！',
                          style: TextStyle(
                            fontFamily: 'NotoSansJP',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '現在、アプリのバージョン2.0を開発中です。\nみんなが欲しい機能や改善点など、ぜひご意見をお聞かせください！',
                          style: TextStyle(
                            fontFamily: 'NotoSansJP',
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
                              fontFamily: 'NotoSansJP',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
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
        ],
      ),
    );
  }
}
