import 'package:flutter/material.dart';
import 'ranking_trending_page.dart'; // 急上昇ランキングページ
import 'ranking_explore_page.dart'; // 検索ランキングページ
import 'ranking_vote_page.dart'; // 投票ランキングページ

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 画面の幅を取得 (タブレットなど広い画面での調整用)
    final screenWidth = MediaQuery.of(context).size.width;
    // コンテンツの最大幅を定義
    final double maxContentWidth = 600.0; // 600ピクセルを最大幅と設定

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'), // タイトルを「ランキング」に修正
        backgroundColor: Colors.transparent, // 背景画像を活かすために透明に
        elevation: 0, // 影を消す
        iconTheme: const IconThemeData(color: Colors.white), // 戻るボタンの色
      ),
      extendBodyBehindAppBar: true, // AppBarの裏にBodyのコンテンツが広がるようにする

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ranking_guild_background.png'), // 画像のパス
            fit: BoxFit.cover, // 画像が画面全体を覆うようにフィット
          ),
        ),
        child: Center(
          // Column全体を中央に配置
          child: ConstrainedBox(
            // コンテンツの最大幅を制限
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 垂直方向の中央揃え
              crossAxisAlignment: CrossAxisAlignment.stretch, // 子要素を水平方向に引き伸ばす
              children: [
                // 上部にタイトルなどのスペースを作る (App Barの高さ分)
                SizedBox(
                  height: AppBar().preferredSize.height + 20,
                ), // App Barの下に余白

                const Text(
                  'ランキングへようこそ！', // テキストをより適切に
                  textAlign: TextAlign.center, // 中央揃え
                  style: TextStyle(
                    fontSize: 28, // 大きめのフォント
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // 白文字で見やすく
                    shadows: [
                      // 影をつけて背景に埋もれないように
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40), // タイトルとボタンの間のスペース

                _buildRankingButton(
                  context,
                  '急上昇ランキング',
                  () {
                    // ★余分な括弧を削除★
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RankingTrendingPage(),
                      ),
                    );
                  }, // ★ここまで★
                ),
                const SizedBox(height: 20), // ボタン間のスペース

                _buildRankingButton(context, '検索', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RankingExplorePage(),
                    ),
                  );
                }),
                const SizedBox(height: 20), // ボタン間のスペース

                _buildRankingButton(context, '投票', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RankingVotePage(),
                    ),
                  );
                }),
              ], // ★Columnのchildrenリストの閉じ角括弧がここにあります★
            ),
          ),
        ),
      ),
    );
  }

  // ランキングボタンの共通ウィジェット (見やすくするためヘルパー関数化)
  Widget _buildRankingButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0), // 左右にパディングを追加
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[700], // ボタンの背景色
          foregroundColor: Colors.white, // テキストの色
          padding: const EdgeInsets.symmetric(vertical: 18), // ボタンの縦方向パディング
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // 角を丸く
            side: const BorderSide(color: Colors.orange, width: 2), // 枠線
          ),
          elevation: 5, // 影
          textStyle: const TextStyle(
            fontSize: 20, // テキストサイズ
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
