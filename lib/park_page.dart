import 'package:flutter/material.dart';
// import 'menu_page.dart'; // 現在使われていない場合はコメントアウトまたは削除
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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

  // お知らせダイアログ表示関数 (NEWSバナーからNewsPageに遷移するため、現状このダイアログの直接の呼び出し箇所はありません)
  // もしお知らせ機能も残したい場合は、NEWSバナーのタップ時の動作を調整するか、別途UIを設ける必要があります。
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
          alignment: Alignment.topLeft, // ダイアログを左上に表示
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
                                  fontFamily: 'NotoSansJP',
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
                                'いつもご利用ありがとうございます。\nVer.1.1.0にアップデートしました。\n\n新機能：\n・新キャラクター「神」の追加\n・「楽単ランキング」の強化\n\n不具合修正：\n・一部UIの表示崩れを修正\n\n引き続き「履修伝説」をお楽しみください！',
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
                                '期間：2025年5月10日〜5月31日\n\n期間中に指定された課題をクリアし、高GPAを目指しましょう！\n豪華報酬をゲットするチャンス！',
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
    final double topBarHeight = screenHeight * 0.05; // 上部UIバーの高さ
    // ★ 中央バナーのY位置: ステータスバーの高さを考慮し、画面の物理的な最上部から少し下げる
    final double singleBannerTopOffset =
        MediaQuery.of(context).padding.top +
        (topBarHeight * 0.1); // 上部バー内の上端からのマージン(バー高さの10%)
    final double singleBannerHeight = topBarHeight * 0.8; // バナーの高さを上部バーの高さの80%に
    final double singleBannerWidth = screenWidth * 0.35; // 中央バナーの幅 (適宜調整)
    final double bottomNavBarHeight = 75.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: CommonBottomNavigation(
        currentPage: AppPage.park,
        parkIconAsset: 'assets/button_park_icon.png',
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
              pageBuilder: (_, __, ___) => const TimeSchedulePage(),
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
              pageBuilder: (_, __, ___) => const CreditReviewPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        onRankingTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const RankingPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        onItemTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const ItemPage(),
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
              'assets/background_plaza.png',
              fit: BoxFit.cover,
            ),
          ),

          // === メインコンテンツエリア ===
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomNavBarHeight),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // === 電子掲示板 (キャラクターの背後) ===
                    Positioned(
                      top: -(screenHeight * 0.2),
                      left: screenWidth * 0.02,
                      right: screenWidth * 0.02,
                      height: screenHeight * 1.20,
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          'assets/countdown.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),

                    // === 中央のキャラクター (掲示板の手前) ===
                    Positioned(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.30),
                          child: Image.asset(
                            _currentParkCharacterImage,
                            width: screenWidth * 0.50,
                            height: screenHeight * 0.40,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // === 上部UI要素 (キャラクターや掲示板より手前) ===
                    // --- 上部UIバーの背景 ---
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: topBarHeight,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/ui_top_bar.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        // このContainerのchildとして、レベル表示、中央バナー、たこ焼き表示をRowで配置
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween, // 要素を均等に配置
                            crossAxisAlignment: CrossAxisAlignment.center,
                            child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // --- 1. レベルとHP情報ボックス (左側) ---
                              Container(
                                width: screenWidth * 0.28, // 幅を画面の28%に
                                height: topBarHeight * 0.75, // バーの高さの75%
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage('assets/ui_level_hp_bg.png'),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('16', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'NotoSansJP')),
                                    Text('52/52', style: TextStyle(color: Colors.black54, fontSize: 13, fontFamily: 'NotoSansJP')),
                                  ],
                                ),
                              ),

                              const Spacer(), // 左の要素と中央バナーの間のスペースを確保

                              // --- 2. 中央バナー (NEWS/お知らせ) ---
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const NewsPage()),
                                  );
                                },
                                child: Container(
                                  width: singleBannerWidth, // singleBannerWidthは事前に定義
                                  height: topBarHeight * 0.75, // バナーの高さを他の要素と合わせる例
                                  child: Image.asset(
                                    'assets/banner_news.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              const Spacer(), // 中央バナーと右の要素の間のスペースを確保

                              // ★★★ 3. たこ焼き表示とプラスボタンのグループ (Stackで重ねる) ★★★
                              Stack(
                                alignment: Alignment.centerRight, // プラスボタンを右端に寄せる基準
                                children: [
                                  // --- たこ焼き表示 (奥側) ---
                                  Container(
                                    width: screenWidth * 0.26, // ★ 背景の幅を調整 (プラスボタンが重なる分も考慮)
                                    height: topBarHeight * 0.75, // 高さを他の要素と合わせる
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage('assets/ui_takoyaki_bg.png'),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    padding: const EdgeInsets.only(left: 6.0, right: 24.0), // ★ 右パディングでプラスボタン用スペース確保
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center, // アイコンとテキストを中央に
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icon_takoyaki.png',
                                          width: topBarHeight * 0.30, // アイコンサイズ
                                          height: topBarHeight * 0.30,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: const Text(
                                            '13,800',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13, // フォントサイズ
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'NotoSansJP',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // --- プラスボタン (手前側) ---
                                  Positioned(
                                    right: -2, // Stackの右端から少しはみ出す感じで調整
                                    // top: 0, bottom: 0, // これで垂直方向中央
                                    child: GestureDetector(
                                      onTap: () {
                                        print('たこ焼きプラスボタンが押されました');
                                      },
                                      child: Container( // タップ範囲を少し広げるため
                                        padding: const EdgeInsets.all(4.0),
                                        // color: Colors.blue.withOpacity(0.3), // デバッグ用
                                        child: Image.asset(
                                          'assets/icon_plus.png',
                                          width: topBarHeight * 0.45, // プラスボタンのサイズ
                                          height: topBarHeight * 0.45,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
        ],
      ),
    );
  }
}
