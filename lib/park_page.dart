import 'package:flutter/material.dart';
// import 'menu_page.dart'; // menu_page.dart は現在使われていないようです
import 'credit_review_page.dart';
import 'item_page.dart';
import 'ranking_page.dart';
import 'time_schedule_page.dart';
import 'news_page.dart';
import 'common_bottom_navigation.dart'; // ★ 共通フッターをインポート

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
                'assets/character_unknown.png'; // nullチェック強化
            _currentParkCharacterName =
                args['characterName'] as String? ?? 'キャラクター'; // nullチェック強化
          });
        }
      });
    }
  }

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double topBarHeight = screenHeight * 0.1;
    final double bannerTopOffset = topBarHeight + 10;
    final double bannerWidth = screenWidth * 0.30;
    final double bottomNavBarHeight =
        75.0; // ★ CommonBottomNavigationの高さに合わせて調整

    return Scaffold(
      extendBodyBehindAppBar: true, // ★ AppBarの背後にbodyを拡張
      extendBody: true, // ★ bottomNavigationBarの背後にもbodyを拡張
      // ★★★ bottomNavigationBar プロパティに共通フッターを設定 ★★★
      bottomNavigationBar: CommonBottomNavigation(
        currentPage: AppPage.park,
        parkIconAsset:
            'assets/button_park_icon.png', // ★★★ "アクティブ用"ではない、通常のアイコンパスに変更 ★★★
        timetableIconAsset: 'assets/button_timetable.png',
        creditReviewIconAsset: 'assets/button_unit_review.png',
        rankingIconAsset: 'assets/button_ranking.png',
        itemIconAsset: 'assets/button_dressup.png',

        onParkTap: () {
          print("Already on Park Page");
        },
        onTimetableTap: () {
          Navigator.pushReplacement(
            // ★ PageRouteBuilder に変更
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const TimeSchedulePage(),
              transitionDuration: Duration.zero, // ★ アニメーション時間をゼロに
              reverseTransitionDuration: Duration.zero, // ★ 戻る時のアニメーション時間もゼロに
              settings: RouteSettings(
                // 引数は PageRouteBuilder の settings で渡す
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
            // ★ PageRouteBuilder に変更
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
            // ★ PageRouteBuilder に変更
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
            // ★ PageRouteBuilder に変更
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
        // bodyのルートはStackで、背景画像と他のUIを重ねる
        children: [
          // === 1. 背景画像 (Stackの一番下) ===
          Positioned.fill(
            child: Image.asset(
              'assets/background_plaza.png',
              fit: BoxFit.cover,
            ),
          ),

          // === メインコンテンツ (背景画像の上、フッターの下に隠れないようにPadding調整) ===
          // ... (ParkPageのbuildメソッド内) ...
          // === メインコンテンツ (背景画像の上、フッターの下に隠れないようにPadding調整) ===
          Positioned.fill(
            child: SafeArea(
              bottom: false, // 下方向のSafeAreaはbottomNavigationBarが考慮するため不要
              child: Padding(
                // ★★★ padding プロパティを追加 ★★★
                padding: EdgeInsets.only(
                  bottom: bottomNavBarHeight,
                ), // bottomNavBarHeightは事前に定義
                child: Stack(
                  // 既存のUI要素をそのままStackで配置
                  children: [
                    // === 2. 上部のゲームUIバー ===
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: topBarHeight, // topBarHeightは事前に定義
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/ui_top_bar.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ... (レベル表示など)
                              Container(
                                width: screenWidth * 0.25, // screenWidthは事前に定義
                                // ...
                              ),
                              // ... (たこ焼き表示など)
                              Row(
                                children: [
                                  Container(
                                    width: screenWidth * 0.35 /* ... */,
                                  ),
                                  GestureDetector(
                                    child: Image.asset(
                                      'assets/icon_plus.png',
                                      width: screenWidth * 0.08,
                                      height: screenWidth * 0.08,
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
                      top: bannerTopOffset, // bannerTopOffsetは事前に定義
                      right: screenWidth * 0.05,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NewsPage(),
                            ),
                          );
                        },
                        child: Image.asset(
                          'assets/banner_news.png',
                          width: bannerWidth,
                          fit: BoxFit.fitWidth,
                        ), // bannerWidthは事前に定義
                      ),
                    ),
                    // === 4. 中央のキャラクター ===
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: bottomNavBarHeight * 0.5,
                          ), // キャラクターがフッターに少し重ならないように調整
                          child: Image.asset(
                            _currentParkCharacterImage, // State変数
                            width: screenWidth * 0.55,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    // === 6. お知らせバナー (左上に配置) ===
                    Positioned(
                      top: bannerTopOffset,
                      left: screenWidth * 0.05,
                      child: GestureDetector(
                        onTap: () {
                          _showNoticeDialog(context);
                        },
                        child: Image.asset(
                          'assets/banner_notice.png',
                          width: bannerWidth,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ...
        ],
      ),
    );
  }
}
