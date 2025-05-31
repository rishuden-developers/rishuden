import 'package:flutter/material.dart';
import 'menu_page.dart';
import 'credit_review_page.dart';
import 'item_page.dart';
import 'ranking_page.dart';
import 'time_schedule_page.dart';
import 'news_page.dart';

class ParkPage extends StatefulWidget {
  // ★StatefulWidgetに変更★
  const ParkPage({super.key});

  @override
  State<ParkPage> createState() => _ParkPageState();
}

class _ParkPageState extends State<ParkPage> {
  // ★StatefulWidgetのStateクラス★
  String _currentParkCharacterImage =
      'assets/character_swordman.png'; // デフォルト画像
  String _currentParkCharacterName = '勇者'; // デフォルト名

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面が描画される前にRouteSettingsからargumentsを受け取る
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        _currentParkCharacterImage = args['characterImage'] as String;
        _currentParkCharacterName = args['characterName'] as String;
      });
    }
  }

  // === ヘルパー関数: お知らせダイアログを表示する (変更なし) ===
  void _showNoticeDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (
        BuildContext buildContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        // ダイアログのコンテンツ
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            type: MaterialType.transparency,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 20, left: 20),
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueAccent, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 15.0),
                              child: Text(
                                'お知らせ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '【重要】履修伝説Ver.1.1.0アップデートのお知らせ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'いつもご利用ありがとうございます。\nVer.1.1.0にアップデートしました。\n\n'
                                '新機能：\n'
                                '・新キャラクター「神」の追加\n'
                                '・「楽単ランキング」の強化\n\n'
                                '不具合修正：\n'
                                '・一部UIの表示崩れを修正\n\n'
                                '引き続き「履修伝説」をお楽しみください！',
                              ),
                              SizedBox(height: 20),
                              Text(
                                'イベント「GPAチャレンジ」開催！',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '期間：2025年5月10日〜5月31日\n\n'
                                '期間中に指定された課題をクリアし、高GPAを目指しましょう！\n'
                                '豪華報酬をゲットするチャンス！',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 画面のサイズを取得してレスポンシブ対応の基準にする
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // UI要素のサイズや位置を画面サイズに対して調整するための変数
    final double topBarHeight = screenHeight * 0.1; // 上部UIバーの高さ
    final double bannerTopOffset =
        topBarHeight + 10; // バナーのtop位置（上部UIバーの下に少しマージン）
    final double bannerWidth = screenWidth * 0.30; // バナーの幅
    final double bottomButtonsHeight = screenHeight * 0.15; // 下部ボタン群の高さ
    final double bottomButtonsBottomOffset =
        screenHeight * 0.02; // 下部ボタン群のbottom位置

    return Scaffold(
      body: Stack(
        children: [
          // === 1. 背景画像 ===
          Positioned.fill(
            child: Image.asset(
              'assets/background_plaza.png', // ★広場全体の背景画像パス★
              fit: BoxFit.cover,
            ),
          ),

          // === 2. 上部のゲームUIバー ===
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topBarHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/ui_top_bar.png'), // ★上部UIバーの背景画像パス★
                  fit: BoxFit.fill,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // 要素間のスペースを均等に
                  children: [
                    // --- レベルとHP情報ボックス ---
                    Container(
                      width: screenWidth * 0.25, // 幅を画面幅の25%に
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/ui_level_hp_bg.png',
                          ), // ★レベル/HP背景画像パス★
                          fit: BoxFit.fill,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '16', // レベル
                            style: TextStyle(
                              color: Colors.black, // または適切な色
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            '52/52', // HP
                            style: TextStyle(
                              color: Colors.black54, // または適切な色
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- たこ焼き表示とプラスボタンのグループ ---
                    Row(
                      children: [
                        Container(
                          width: screenWidth * 0.35, // たこ焼き表示の幅を広げる
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/ui_takoyaki_bg.png',
                              ), // ★たこ焼き表示の背景画像パス★
                              fit: BoxFit.fill,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icon_takoyaki.png', // ★たこ焼きアイコンパス★
                                width: 25,
                                height: 25,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                '13,800', // たこ焼きの数
                                style: TextStyle(
                                  color: Colors.black, // または適切な色
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // プラスボタン（たこ焼きの横）
                        GestureDetector(
                          onTap: () {
                            print('たこ焼きプラスボタンが押されました');
                          },
                          child: Image.asset(
                            'assets/icon_plus.png', // ★プラスアイコン画像パス★
                            width: screenWidth * 0.08, // 幅を調整
                            height: screenWidth * 0.08, // 高さを調整
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === 3. NEWSバナー (右上に配置) ===
          Positioned(
            top: bannerTopOffset, // 上部UIバーの下に配置
            right: screenWidth * 0.05, // 右から5%の余白
            child: GestureDetector(
              onTap: () {
                // NEWSページへ遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsPage()),
                );
              },
              child: Image.asset(
                'assets/banner_news.png', // ★NEWSバナーの画像パス★
                width: bannerWidth, // 画面幅の30%
                fit: BoxFit.fitWidth,
              ),
            ),
          ),

          // === 4. 中央のキャラクター ===
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              // キャラクター画像は_currentParkCharacterImage変数で動的に設定
              child: Image.asset(
                _currentParkCharacterImage, // ★ここを修正★
                width: screenWidth * 0.5, // キャラクターの幅を画面幅の50%に調整 (適宜変更)
                fit: BoxFit.contain, // 画像が収まるように調整
              ),
            ),
          ),

          // === 5. 下部の主要機能ボタン群 ===
          Positioned(
            bottom: bottomButtonsBottomOffset, // 画面下部から2%の余白
            left: 0,
            right: 0,
            height: bottomButtonsHeight, // ボタン群に画面高さの15%を割り当てる
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // 均等に配置
              children: [
                // --- 単位レビューボタン ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreditReviewPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: screenWidth * 0.22, // 画面幅の約22%
                    height: screenHeight * 0.13, // 画面高さの約13%
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/button_unit_review.png',
                        ), // ★ボタン背景画像パス★
                        fit: BoxFit.fill,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '単位レビュー',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- ランキングボタン ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RankingPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: screenWidth * 0.22,
                    height: screenHeight * 0.13,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/button_ranking.png',
                        ), // ★ボタン背景画像パス★
                        fit: BoxFit.fill,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'ランキング',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- 着せ替えボタン ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ItemPage()),
                    );
                  },
                  child: Container(
                    width: screenWidth * 0.22,
                    height: screenHeight * 0.13,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/button_dressup.png',
                        ), // ★ボタン背景画像パス★
                        fit: BoxFit.fill,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '着せ替え',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- 時間割ボタン ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TimeSchedulePage(),
                      ),
                    );
                  },
                  child: Container(
                    width: screenWidth * 0.22,
                    height: screenHeight * 0.13,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/button_timetable.png',
                        ), // ★ボタン背景画像パス★
                        fit: BoxFit.fill,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '時間割',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === 6. お知らせバナー (左上に配置) ===
          Positioned(
            top: bannerTopOffset, // 上部UIバーの下に配置 (NEWSバナーと同じ高さ)
            left: screenWidth * 0.05, // 左からの余白
            child: GestureDetector(
              onTap: () {
                _showNoticeDialog(context); // 左上から現れるお知らせダイアログを表示
              },
              child: Image.asset(
                'assets/banner_notice.png', // ★お知らせバナーの画像パス★
                width: bannerWidth, // 画面幅の30% (NEWSバナーと同じ幅)
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
