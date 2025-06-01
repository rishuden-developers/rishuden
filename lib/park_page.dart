import 'package:flutter/material.dart';
// import 'menu_page.dart'; // menu_page.dart は現在使われていないようです
import 'credit_review_page.dart';
import 'item_page.dart';
import 'ranking_page.dart';
import 'time_schedule_page.dart';
import 'news_page.dart';
import 'common_bottom_navigation.dart'; // 共通フッターをインポート

class ParkPage extends StatefulWidget {
  const ParkPage({super.key});

  @override
  State<ParkPage> createState() => _ParkPageState();
}

class _ParkPageState extends State<ParkPage> {
  String _currentParkCharacterImage =
      'assets/character_swordman.png'; // デフォルト画像
  String _currentParkCharacterName = '勇者'; // デフォルト名

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      // ビルド後にsetStateを呼ぶため、安全に実行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // ウィジェットがまだツリーに存在するか確認
          setState(() {
            _currentParkCharacterImage =
                args['characterImage'] as String? ??
                'assets/character_unknown.png';
            _currentParkCharacterName =
                args['characterName'] as String? ?? 'キャラクター';
          });
        }
      });
    }
  }

  // === ヘルパー関数: お知らせダイアログを表示する ===
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
                                  fontFamily: 'NotoSansJP', // フォント指定例
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
                                  fontFamily: 'NotoSansJP',
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
                                style: TextStyle(fontFamily: 'NotoSansJP'),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'イベント「GPAチャレンジ」開催！',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansJP',
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '期間：2025年5月10日〜5月31日\n\n'
                                '期間中に指定された課題をクリアし、高GPAを目指しましょう！\n'
                                '豪華報酬をゲットするチャンス！',
                                style: TextStyle(fontFamily: 'NotoSansJP'),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double topBarHeight = screenHeight * 0.1;
    final double bannerTopOffset = topBarHeight + 10;
    final double bannerWidth = screenWidth * 0.30;
    final double bottomNavBarHeight = 75.0; // CommonBottomNavigationの高さ

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: CommonBottomNavigation(
        currentPage: AppPage.park,
        parkIconAsset: 'assets/button_park_icon.png', // 通常アイコン
        timetableIconAsset: 'assets/button_timetable.png',
        creditReviewIconAsset: 'assets/button_unit_review.png',
        rankingIconAsset: 'assets/button_ranking.png',
        itemIconAsset: 'assets/button_dressup.png',
        onParkTap: () {
          print("Already on Park Page");
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
              settings: RouteSettings(
                arguments: {
                  'characterName': _currentParkCharacterName,
                  'characterImage': _currentParkCharacterImage,
                },
              ),
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
            ),
          );
        },
        onItemTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => const ItemPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
      ),
      body: Stack(
        children: [
          // === 1. 背景画像 (一番奥) ===
          Positioned.fill(
            child: Image.asset(
              'assets/background_plaza.png', // ★広場全体の背景画像パス★
              fit: BoxFit.cover,
            ),
          ),

          // === メインコンテンツエリア ===
          // SafeAreaで囲み、フッター分のPaddingはメインのStack内コンテンツに適用
          Positioned.fill(
            child: SafeArea(
              bottom: false, // 下はbottomNavigationBarがあるのでfalse
              child: Padding(
                // このPaddingがメインコンテンツエリア全体をフッターから保護
                padding: EdgeInsets.only(bottom: bottomNavBarHeight),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // === 2. 電子掲示板 (キャラクターの背後、かなり上) ===
                    Positioned(
                      top:
                          -(screenHeight *
                              0.15), // ★掲示板の上部が画面外に出るように調整 (例: 高さの約1/3程度)
                      // screenHeight * 1.20 (掲示板の高さ) に対して
                      left: screenWidth * 0.02, // 画面幅の2%の位置から
                      right: screenWidth * 0.02, // 画面幅の2%の位置まで (これで横幅96%)
                      height: screenHeight * 1.20, // 掲示板の高さは維持 (画面高さの120%)
                      child: Opacity(
                        // ★★★ Opacityウィジェットで囲む ★★★
                        opacity: 0.5, // ★★★ 50%の透明度を指定 ★★★
                        child: Image.asset(
                          'assets/countdown.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),

                    // === 3. 中央のキャラクター (掲示板の手前、少し下) ===
                    Positioned(
                      // Stack全体の中央を基準に、PaddingでY軸を調整
                      // top, bottom, left, right を指定しないことで、子のサイズに依存しつつalignment: Alignment.centerで中央に
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top:
                                screenHeight *
                                0.30, // ★キャラクターのY位置調整 (例: 上から30%)
                          ), // ★掲示板とのバランスを見てY位置調整 (例: 上から25%)
                          child: Image.asset(
                            _currentParkCharacterImage,
                            width: screenWidth * 0.50, // キャラクターの幅
                            height: screenHeight * 0.40, // キャラクターの高さ
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // === 上部UIバー (キャラクターや掲示板より手前) ===
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: topBarHeight,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/ui_top_bar.png',
                            ), // ★上部UIバーの背景画像パス★
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // --- レベルとHP情報ボックス ---
                              Container(
                                width: screenWidth * 0.25,
                                height: double.infinity, // 親の高さに合わせる
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                      'assets/ui_level_hp_bg.png',
                                    ), // ★レベル/HP背景画像パス★
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '16',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NotoSansJP',
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '52/52',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                        fontFamily: 'NotoSansJP',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // --- たこ焼き表示とプラスボタンのグループ ---
                              Row(
                                children: [
                                  Container(
                                    width: screenWidth * 0.35,
                                    height: double.infinity, // 親の高さに合わせる
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/ui_takoyaki_bg.png',
                                        ), // ★たこ焼き表示の背景画像パス★
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icon_takoyaki.png',
                                          width: 25,
                                          height: 25,
                                        ), // ★たこ焼きアイコンパス★
                                        const SizedBox(width: 5),
                                        const Text(
                                          '13,800',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'NotoSansJP',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      print('たこ焼きプラスボタンが押されました');
                                    },
                                    child: Image.asset(
                                      'assets/icon_plus.png',
                                      width: screenWidth * 0.16,
                                      height: screenWidth * 0.16,
                                    ), // ★プラスアイコン画像パス★
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
