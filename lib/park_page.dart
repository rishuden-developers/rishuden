import 'package:flutter/material.dart';
import 'dart:async'; // Timer.periodic のために必要
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // ★ Providerをインポート
import 'character_provider.dart';
// DateFormat のために必要

// 共通フッターと遷移先ページのインポート (パスは実際の構成に合わせてください)
import 'common_bottom_navigation.dart';
import 'credit_review_page.dart';
import 'item_page.dart';
import 'ranking_page.dart';
import 'time_schedule_page.dart';
import 'news_page.dart';

class ParkPage extends StatefulWidget {
  const ParkPage({super.key});

  @override
  State<ParkPage> createState() => _ParkPageState();
}

class _ParkPageState extends State<ParkPage> {
  String _currentParkCharacterImage =
      'assets/character_swordman.png'; // デフォルト画像
  String _currentParkCharacterName = '勇者'; // デフォルト名

  // 課題情報とカウントダウンのためのState変数
  String _taskSubject = "情報システム工学";
  String _taskName = "次世代ネットワークに関するレポート";
  String _taskDetails = "A4 5枚以上。参考文献リスト必須。詳細はCLEを参照。";
  DateTime _taskDeadline = DateTime.now().add(
    Duration(days: 5, hours: 18, minutes: 30),
  );
  String _countdownText = "計算中...";
  Timer? _timer;

  String _weekDateRange = ""; // AppBarの週表示用 (main.dartでのintl初期化が必要)
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Drawer用

  int _currentLevel = 16; // 仮の初期レベル
  int _currentExp = 1250; // 仮の現在の経験値
  int _maxExp = 2000;

  bool _isCharacterInfoInitialized = false;

  @override
  void initState() {
    super.initState();
    _calculateWeekDateRange();
    _startCountdownTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ★★★ Providerからキャラクター情報を取得してStateを更新 ★★★
    // listen: true を使うことで、Providerの値が変更されたらこのメソッドが再度呼ばれ、
    // UIが最新の状態に追従するようになります。
    final characterProvider = Provider.of<CharacterProvider>(context);
    // Providerの値が現在のStateと異なる場合、または初回読み込み時にStateを更新
    if (!_isCharacterInfoInitialized ||
        _currentParkCharacterName != characterProvider.characterName ||
        _currentParkCharacterImage != characterProvider.characterImage) {
      // didChangeDependencies内で直接setStateを呼ぶのは通常問題ありませんが、
      // より安全に、かつビルド完了後に行いたい場合はaddPostFrameCallbackを使います。
      // 今回は、依存関係の変更を検知して即座にStateを更新する形にします。
      // ただし、これがビルド中に呼ばれると問題なので、初回はフラグで制御
      if (mounted) {
        // mountedチェックは常に良い習慣
        setState(() {
          _currentParkCharacterImage = characterProvider.characterImage;
          _currentParkCharacterName = characterProvider.characterName;
          _isCharacterInfoInitialized = true; // 初回読み込み完了
        });
      }
    }
    // ★ ルート引数からのキャラクター情報取得は削除します ★
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateWeekDateRange() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 4)); // 月～金
    try {
      // main.dart で initializeDateFormatting('ja_JP', null); が実行されていること
      setState(() {
        _weekDateRange =
            "${DateFormat.Md('ja').format(startOfWeek)} 〜 ${DateFormat.Md('ja').format(endOfWeek)}";
      });
    } catch (e) {
      print("日付フォーマットエラー (main.dartでの初期化を確認): $e");
      setState(() {
        _weekDateRange = "日付表示エラー";
      });
    }
  }

  void _startCountdownTimer() {
    _updateCountdownText();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCountdownText();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateCountdownText() {
    final now = DateTime.now();
    final difference = _taskDeadline.difference(now);
    String newText;
    if (difference.isNegative) {
      newText = "limit: 0日 00時00分00秒";
      if (_timer?.isActive ?? false) {
        _timer?.cancel();
      }
    } else {
      final days = difference.inDays;
      final hours = difference.inHours.remainder(24);
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);
      final daysStr = days.toString();
      final hoursStr = hours.toString().padLeft(2, '0');
      final minutesStr = minutes.toString().padLeft(2, '0');
      final secondsStr = seconds.toString().padLeft(2, '0');
      newText = "limit: ${daysStr}日 ${hoursStr}時${minutesStr}分${secondsStr}秒";
    }
    if (mounted && _countdownText != newText) {
      setState(() {
        _countdownText = newText;
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
                                  fontFamily: 'misaki',
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
                                  fontFamily: 'misaki',
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'いつもご利用ありがとうございます。\nVer.1.1.0にアップデートしました。\n\n新機能：\n・新キャラクター「神」の追加\n・「楽単ランキング」の強化\n\n不具合修正：\n・一部UIの表示崩れを修正\n\n引き続き「履修伝説」をお楽しみください！',
                                style: TextStyle(fontFamily: 'misaki'),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'イベント「GPAチャレンジ」開催！',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'misaki',
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '期間：2025年5月10日〜5月31日\n\n期間中に指定された課題をクリアし、高GPAを目指しましょう！\n豪華報酬をゲットするチャンス！',
                                style: TextStyle(fontFamily: 'misaki'),
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
    final double topBarHeight = screenHeight * 0.08;
    final double singleBannerWidth = screenWidth * 0.30;
    final double bottomNavBarHeight = 75.0;
    final double logoSize = screenWidth * 0.13;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.brown[700]),
              child: Text(
                'メニュー',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'misaki',
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('お知らせを見る'),
              onTap: () {
                Navigator.pop(context);
                _showNoticeDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定 (未実装)'),
              onTap: () {
                Navigator.pop(context); /* TODO */
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('ヘルプ (未実装)'),
              onTap: () {
                Navigator.pop(context); /* TODO */
              },
            ),
          ],
        ),
      ),
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
          Positioned.fill(
            child: Image.asset(
              'assets/background_plaza.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomNavBarHeight),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // === 電子掲示板 (背景) ===
                    Positioned(
                      top: -(screenHeight * 0.1),
                      left: screenWidth * 0.02,
                      right: screenWidth * 0.02,
                      height: screenHeight * 1.0,
                      child: Opacity(
                        opacity: 0.6,
                        child: Image.asset(
                          'assets/countdown.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    // === 電子掲示板の情報表示エリア ===
                    Positioned(
                      top: screenHeight * 0.18,
                      left: screenWidth * 0.10, // 左右の余白を少し広げる
                      right: screenWidth * 0.10,
                      height: screenHeight * 0.28, // 表示エリアの高さを確保
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ), // パディング調整
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _countdownText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'digitalism',
                                fontSize: screenHeight * 0.038,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent.withOpacity(0.95),
                                letterSpacing: 2.0,
                                shadows: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8), // 少し間隔を詰める
                            Text(
                              _taskSubject,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenHeight * 0.020,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlue[100]!.withOpacity(0.95),
                                fontFamily: 'misaki',
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis, // 教科名が長い場合
                            ),
                            const SizedBox(height: 6), // 少し間隔を詰める
                            Center(
                              // ★ ContainerをCenterで囲んで中央寄せにする (任意)
                              child: Container(
                                width:
                                    screenWidth *
                                    0.55, // ★ 横幅を画面幅の65%に設定 (掲示板の幅より小さく)
                                // この値を調整してください
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    "課題: $_taskName\n詳細: $_taskDetails\n締切: ${DateFormat('MM/dd HH:mm', 'ja').format(_taskDeadline)}",
                                    style: TextStyle(
                                      fontSize:
                                          screenHeight * 0.014, // フォントサイズも少し調整
                                      color: Colors.grey[100]!.withOpacity(
                                        0.95,
                                      ),
                                      fontFamily: 'misaki',
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // === 中央のキャラクター ===
                    Positioned(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: screenHeight * 0.28,
                          ), // Y位置調整
                          child: Image.asset(
                            _currentParkCharacterImage,
                            width: screenWidth * 0.7,
                            height: screenHeight * 0.6,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // === 上部UI要素群 ===
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
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 8.0,
                            right: 4.0,
                            top: MediaQuery.of(context).padding.top * 0.2 + 2.0,
                            bottom: 2.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // --- 1. レベルゲージ (左側) ---
                              Container(
                                width: screenWidth * 0.28,
                                height: topBarHeight * 0.70,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Image.asset(
                                      'assets/ui_level_hp_bg.png',
                                      fit: BoxFit.fill,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Lv.$_currentLevel',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: topBarHeight * 0.25,
                                              fontFamily: 'misaki',
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 2,
                                                  offset: Offset(1, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    topBarHeight * 0.1,
                                                  ),
                                              child: LinearProgressIndicator(
                                                value:
                                                    0.7, // 仮: _currentExp / _maxExp
                                                backgroundColor: Colors
                                                    .grey
                                                    .shade600
                                                    .withOpacity(0.8),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      const Color.fromARGB(
                                                        255,
                                                        61,
                                                        245,
                                                        255,
                                                      ),
                                                    ),
                                                minHeight: topBarHeight * 0.18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // --- 2. 中央バナー (NEWS) ---
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NewsPage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: singleBannerWidth,
                                  height: topBarHeight * 0.75,
                                  child: Image.asset(
                                    'assets/banner_news.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // --- 3. たこ焼き表示 (右側) ---
                              Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  Container(
                                    width: screenWidth * 0.25,
                                    height: topBarHeight * 0.5,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/ui_takoyaki_bg.png',
                                        ),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    padding: const EdgeInsets.only(
                                      left: 2.0,
                                      right: 18.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icon_takoyaki.png',
                                          width: topBarHeight * 1.0,
                                          height: topBarHeight * 1.0,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            '13800',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: topBarHeight * 0.26,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'misaki',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: -3,
                                    child: GestureDetector(
                                      onTap: () {
                                        print('たこ焼きプラスボタンが押されました');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(1.0),
                                        child: Image.asset(
                                          'assets/icon_plus.png',
                                          width: topBarHeight * 0.6,
                                          height: topBarHeight * 0.6,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // --- 4. メニューアイコン (一番右) ---
                              IconButton(
                                icon: Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                  size: topBarHeight * 0.50,
                                ),
                                onPressed: () {
                                  _scaffoldKey.currentState?.openEndDrawer();
                                },
                                padding: const EdgeInsets.only(left: 4.0),
                                constraints: BoxConstraints(
                                  minWidth: topBarHeight * 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // === ロゴなどの配置 (フッターナビゲーションの上) ===
                    Positioned(
                      left: 15,
                      bottom: 10,
                      child: GestureDetector(
                        onTap: () {
                          print("オーズテックロゴタップ");
                        },
                        child: Opacity(
                          opacity: 1.0, // 透明度は適宜調整してください
                          child: ClipRRect(
                            // ★★★ ClipRRectで囲む ★★★
                            borderRadius: BorderRadius.circular(
                              12.0,
                            ), // ★★★ 角の丸みを指定 (半径12.0の円) ★★★
                            // この値を調整してお好みの丸みにしてください
                            child: Image.asset(
                              'assets/oztech.png', // ★ ロゴの画像パス
                              width: logoSize, // logoSize は build メソッドの最初の方で定義
                              height: logoSize,
                              fit:
                                  BoxFit
                                      .cover, // ★ contain から cover に変更すると、丸いクリップ領域を埋めようとします
                              //   (画像の中心部が拡大され、アスペクト比は保たれます)
                              //   もし contain のままで、丸めた領域の外側が透明になるのが良ければ BoxFit.contain のままにします。
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    width: logoSize,
                                    height: logoSize,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(
                                        12.0,
                                      ), // エラー時も角丸に
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '学生\nロゴ\nError',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 15,
                      bottom: 10,
                      child: GestureDetector(
                        onTap: () {
                          print("開発サークルロゴタップ");
                        },
                        child: Opacity(
                          opacity: 1.0, // 透明度は適宜調整してください
                          child: ClipRRect(
                            // ★★★ ClipRRectで囲む ★★★
                            borderRadius: BorderRadius.circular(
                              12.0,
                            ), // ★★★ 角の丸みを指定 (半径12.0の円) ★★★
                            // この値を調整してお好みの丸みにしてください
                            child: Image.asset(
                              'assets/potipoti.png', // ★ ロゴの画像パス
                              width: logoSize, // logoSize は build メソッドの最初の方で定義
                              height: logoSize,
                              fit:
                                  BoxFit
                                      .cover, // ★ contain から cover に変更すると、丸いクリップ領域を埋めようとします
                              //   (画像の中心部が拡大され、アスペクト比は保たれます)
                              //   もし contain のままで、丸めた領域の外側が透明になるのが良ければ BoxFit.contain のままにします。
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    width: logoSize,
                                    height: logoSize,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(
                                        12.0,
                                      ), // エラー時も角丸に
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '開発\nロゴ\nError',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
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
