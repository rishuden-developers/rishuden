import 'package:flutter/material.dart';
import 'ranking_trending_page.dart'; // 急上昇ランキングページ
import 'ranking_explore_page.dart'; // 検索ランキングページ
import 'ranking_vote_page.dart'; // 投票ランキングページ
import 'dart:ui'; // BackdropFilter のために必要

// ★★★ 共通フッターと遷移先ページをインポート ★★★
import 'common_bottom_navigation.dart';
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
            borderRadius: BorderRadius.circular(12), // ここを修正 (欠落していた部分)
          ),
          elevation: 5,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: Text(text),
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
          'ランキング',
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
            image: AssetImage('assets/ranking_bg.png'), // あなたの背景画像パス
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
                        _buildRankingButton(context, '急上昇ランキング', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RankingTrendingPage(),
                            ),
                          );
                        }),
                        _buildRankingButton(context, '検索ランキング', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RankingExplorePage(),
                            ),
                          );
                        }),
                        _buildRankingButton(context, '投票ランキング', () {
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
                Align(
                  alignment: Alignment.bottomCenter,
                  child: CommonBottomNavigation(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
