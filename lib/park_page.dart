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
import 'level_gauge.dart';
// park_page.dart の一番上に追加
import 'dart:ui';

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
  String _taskSubject = "力学詳論";
  String _taskName = "課題レポート";
  String _taskDetails = "A4 5枚以上";
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

  void _showPurchaseDialog(BuildContext context) {
    // 画面上にオーバーレイ表示するための関数
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // ダイアログの外側をタップして閉じられるようにする
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.6), // 背景の黒いオーバーレイの色
      transitionDuration: const Duration(
        milliseconds: 300,
      ), // 表示されるときのアニメーション速度
      pageBuilder: (ctx, anim1, anim2) {
        // ここでダイアログの見た目を作る
        return Center(
          // 画面中央に配置
          child: Material(
            // ダイアログ内のテキスト等のスタイルを正しく表示するために必要
            type: MaterialType.transparency,
            child: ScaleTransition(
              // ふわっと拡大するアニメーション
              scale: anim1,
              child: FadeTransition(
                // フェードインするアニメーション
                opacity: anim1,
                child: ClipRRect(
                  // 角を丸くするために必要
                  borderRadius: BorderRadius.circular(15.0),
                  child: BackdropFilter(
                    // ★★★ これが「すりガラス」効果の本体 ★★★
                    filter: ImageFilter.blur(
                      sigmaX: 10.0,
                      sigmaY: 10.0,
                    ), // ぼかしの強さ
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width * 0.85, // ダイアログの幅
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15), // すりガラスの白っぽい色
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 中身の高さに合わせる
                        children: [
                          Text(
                            'たこ焼きを増やすには？',
                            style: TextStyle(
                              fontFamily: 'misaki',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '「たこ焼き」は課題をクリアしたり、ログインボーナスで獲得できます。\n\nすぐに増やしたい場合は、ショップで購入することも可能です。（未実装）',
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
                            onPressed:
                                () => Navigator.of(ctx).pop(), // ダイアログを閉じる
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ★★★ この2つの関数を _ParkPageState クラスの中に追加 ★★★

  // 1. 学生団体ロゴ用のダイアログ
  void _showOztechDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ScaleTransition(
              scale: anim1,
              child: FadeTransition(
                opacity: anim1,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '学生団体 OZTECH', // ★ タイトルを変更
                            style: TextStyle(
                              fontFamily: 'misaki',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '★★★ ここに学生団体の紹介文を入れてください ★★★\n\n例：OZTECHは、学生の技術力向上と交流を目的とした団体です。アプリ開発や勉強会を定期的に開催しています。',
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
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. 開発サークルロゴ用のダイアログ
  void _showPotiPotiDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ScaleTransition(
              scale: anim1,
              child: FadeTransition(
                opacity: anim1,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '開発サークル ぽちぽち', // ★ タイトルを変更
                            style: TextStyle(
                              fontFamily: 'misaki',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '★★★ ここに開発サークルの紹介文を入れてください ★★★\n\n例：このアプリ「履修伝説」を開発している、ゲーム好きが集まるサークルです。いつでもメンバー募集中！',
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
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                    ),
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
  void initState() {
    super.initState();
    _calculateWeekDateRange();
    _startCountdownTimer();
  }

  final GlobalKey<LiquidLevelGaugeState> _gaugeKey =
      GlobalKey<LiquidLevelGaugeState>();

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
      newText = "limit: ${daysStr}日 ${hoursStr}:${minutesStr}:${secondsStr}";
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
                      top: screenHeight * 0.165,
                      left: screenWidth * 0.10, // 左右の余白を少し広げる
                      right: screenWidth * 0.10,
                      height: screenHeight * 0.28, // 表示エリアの高さを確保
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ), // パディング調整
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _countdownText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'digitalism',
                                  fontSize: screenHeight * 0.05,
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
                              const SizedBox(height: 4), // 少し間隔を詰める
                              Text(
                                _taskSubject,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenHeight * 0.030,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightBlue[100]!.withOpacity(
                                    0.95,
                                  ),
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
                                      "課題: $_taskName\n詳細: $_taskDetails\n期限: ${DateFormat('MM/dd HH:mm', 'ja').format(_taskDeadline)}",
                                      style: TextStyle(
                                        fontSize: screenHeight * 0.020,
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
                    Positioned(
                      // ★★★ 1. ボタンを右下に配置 ★★★
                      bottom: 130, // 下からの距離
                      right: 15, // 右からの距離
                      child: ElevatedButton(
                        // ★★★ 2. ボタンを目立たないスタイルに変更 ★★★
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(
                            0.4,
                          ), // 半透明の黒に
                          foregroundColor: Colors.white.withOpacity(
                            0.8,
                          ), // 文字も少し透明に
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12), // 文字を小さく
                        ),
                        onPressed: () {
                          _gaugeKey.currentState?.addExperience(20);
                        },
                        child: const Text('EXP+20'), // テキストを短く
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
                              LiquidLevelGauge(
                                // ★★★ 4. ゲージにキーをセット ★★★
                                key: _gaugeKey,
                                width: screenWidth * 0.28,
                                height: topBarHeight * 0.70,
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
                              // ★★★ このStackウィジェット全体を置き換えてください ★★★
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // --- レイヤー1: 新しい背景画像と数字 ---
                                  Container(
                                    width: screenWidth * 0.25,
                                    height: topBarHeight * 0.5,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        // ★ 1. 新しい「アイコン一体型」の画像パスを指定 ★
                                        image: AssetImage(
                                          'assets/ui_takoyaki_bar.png',
                                        ), // ← あなたが作成した新しいファイル名にしてください
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    // ★ 2. 新しい背景に合わせて数字の表示位置を調整 ★
                                    // 左側のアイコン部分のスペースを空けるために、左の余白を多めに取ります
                                    padding: const EdgeInsets.only(
                                      left: 30.0,
                                      right: 20.0,
                                    ),
                                    alignment: Alignment.center,
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

                                  // --- はみ出すアイコン用のPositionedウィジェットは削除しました ---

                                  // --- プラスボタン (変更なし) ---
                                  Positioned(
                                    right: -3,
                                    child: GestureDetector(
                                      onTap: () {
                                        _showPurchaseDialog(context);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(1.0),
                                        child: Image.asset(
                                          'assets/icon_plus.png',
                                          width: topBarHeight * 0.5,
                                          height: topBarHeight * 0.5,
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
                      bottom: 60,
                      child: GestureDetector(
                        onTap: () {
                          _showOztechDialog(context); // ★ 新しい関数を呼び出す
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
                      bottom: 60,
                      child: GestureDetector(
                        onTap: () {
                          _showPotiPotiDialog(context); // ★ 新しい関数を呼び出す
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
          Positioned(
            bottom: 30, // 画面の下からの距離
            left: 40, // 画面の左からの距離
            right: 40, // 画面の右からの距離
            child: CommonBottomNavigation(
              currentPage: AppPage.park,

              // --- 通常アイコンのパス ---
              parkIconAsset: 'assets/button_park.png',
              timetableIconAsset: 'assets/button_timetable.png',
              creditReviewIconAsset: 'assets/button_unit_review.png',
              rankingIconAsset: 'assets/button_ranking.png',
              itemIconAsset: 'assets/button_dressup.png',

              // --- アクティブアイコンのパス（すべて指定） ---
              parkIconActiveAsset: 'assets/button_park_icon_active.png',
              timetableIconActiveAsset: 'assets/button_timetable_active.png',
              creditReviewActiveAsset: 'assets/button_unit_review_active.png',
              rankingIconActiveAsset: 'assets/button_ranking_active.png',
              itemIconActiveAsset: 'assets/button_dressup_active.png',

              // --- タップ時の処理（省略せずにすべて記述） ---
              onParkTap: () {
                print("Already on Park Page");
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
                    pageBuilder: (_, __, ___) => const CreditReviewPage(),
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
              onItemTap: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const ItemPage(),
                    transitionDuration: Duration.zero,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
