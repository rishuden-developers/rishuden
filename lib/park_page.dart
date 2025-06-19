import 'package:flutter/material.dart';
import 'dart:async'; // Timer.periodic のために必要
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'task_progress_gauge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'character_data.dart' show characterFullDataGlobal;
import 'common_bottom_navigation.dart';
import 'credit_review_page.dart';
import 'item_page.dart';
import 'ranking_page.dart';
import 'time_schedule_page.dart';
import 'news_page.dart';
import 'mail_page.dart';
import 'level_gauge.dart';
import 'quest_create.dart'; // QuestCreationWidgetのインポート
import 'dart:ui';
import 'setting_page.dart';

class ParkPage extends StatefulWidget {
  final String diagnosedCharacterName;
  final List<int> answers;
  final String userName;
  final String? grade;
  final String? department;

  const ParkPage({
    super.key,
    required this.diagnosedCharacterName,
    required this.answers,
    required this.userName,
    this.grade,
    this.department,
  });

  @override
  State<ParkPage> createState() => _ParkPageState();
}

class _ParkPageState extends State<ParkPage> {
  String _currentParkCharacterImage = ''; // 空の初期値に変更
  String _currentParkCharacterName = ''; // 空の初期値に変更
  String _userName = '';

  List<String> _dialogueMessages = [];
  // 現在表示しているメッセージのインデックス
  int _currentMessageIndex = 0;

  // 課題情報とカウントダウンのためのState変数
  // ★★★ 課題情報をリストで管理するように変更 ★★★
  final List<Map<String, dynamic>> _tasks = [
    {
      'subject': "力学詳論Ⅰ",
      'name': "課題レポート",
      'details': "A4 5枚以上",
      'deadline': DateTime.now().add(
        const Duration(days: 5, hours: 18, minutes: 00),
      ),
      'isSubmitted': false,
    },
    {
      'subject': "総合英語",
      'name': "最終課題",
      'details': "プレゼン作成",
      'deadline': DateTime.now().add(const Duration(days: 12, hours: 00)),
      'isSubmitted': false,
    },
    // 他にも課題があればここに追加
  ];

  // ★★★ PageViewを管理するための変数を追加 ★★★
  final PageController _pageController = PageController(
    viewportFraction: 1.0, // 掲示板自体は画面いっぱいに表示
  ); // 掲示板画像の範囲でスクロール
  int _currentPage = 0;
  String _daysStr = "0";
  String _hoursStr = "00";
  String _minutesStr = "00";
  String _secondsStr = "00";
  Timer? _timer;

  String _weekDateRange = ""; // AppBarの週表示用 (main.dartでのintl初期化が必要)
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Drawer用

  int _currentLevel = 16; // 仮の初期レベル
  int _currentExp = 1250; // 仮の現在の経験値
  int _maxExp = 2000;

  int? _fadingOutTaskIndex;

  bool _isCharacterInfoInitialized = false;
  bool isQuestCreationVisible = false;
  int _takoyakiCount = 13800; // たこ焼きの初期値
  final Set<int> _crackingTasks = {};
  double _pageOffset = 0.0;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // エラー処理をここに追加できます (例: SnackBarの表示)
      debugPrint('Could not launch $url');
    }
  }

  // _ParkPageState クラス内

  // ★★★ この変数を追加 ★★★
  bool _isTakoyakiClaimed = false;

  // ★★★ この2つのメソッドを丸ごと追加 ★★★

  // 起動時に、今日すでにたこ焼きを受け取ったかチェックするメソッド
  void _loadTakoyakiStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // キーに今日の日付を含めることで、毎日リセットされるようにする
    final String todayKey =
        'takoyakiClaimed_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    setState(() {
      _isTakoyakiClaimed = prefs.getBool(todayKey) ?? false;
    });
  }

  // たこ焼きボタンが押された時の処理
  void _claimDailyTakoyaki() async {
    if (_isTakoyakiClaimed) {
      // すでに受け取り済みの場合のメッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '今日のたこ焼きはもう受け取ったで！また明日な！',
            style: TextStyle(fontFamily: 'misaki'),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // 報酬を付与し、受け取り済みにする
    setState(() {
      _takoyakiCount += 10; // デイリーボーナスは10個
      _isTakoyakiClaimed = true;
    });

    // 「今日受け取った」という記録を端末に保存
    final prefs = await SharedPreferences.getInstance();
    final String todayKey =
        'takoyakiClaimed_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    await prefs.setBool(todayKey, true);

    // 受け取り完了メッセージ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('たこ焼きを10個ゲットした！', style: TextStyle(fontFamily: 'misaki')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDialogue(List<String> messages) {
    setState(() {
      _dialogueMessages = messages;
      _currentMessageIndex = 0;
    });
  }

  Timer? _rpgMessageTimer; // RPGメッセージ表示用のタイマー

  // ★★★ 掲示板が割れた時にRPGメッセージを時間差で表示するメソッド ★★★
  void _showRpgMessageAfterCrack(Map<String, dynamic> taskData) {
    // 既存のタイマーがあればキャンセル
    _rpgMessageTimer?.cancel();

    // 1.5秒後にRPGメッセージを表示
    _rpgMessageTimer = Timer(const Duration(milliseconds: 1500), () {
      setState(() {
        _dialogueMessages = [
          "掲示板が割れた！",
          "課題「${taskData['name']}」を討伐完了！",
          "たこ焼き${taskData['reward'] ?? 10}個を獲得した！",
          "よくやったな、冒険者よ...",
        ];
        _currentMessageIndex = 0;
      });
    });
  }

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

  void _onTaskTap(int taskIndex) {
    final taskData = _tasks[taskIndex];

    // 割れるエフェクトを開始
    setState(() {
      _crackingTasks.add(taskIndex);
    });

    // RPGメッセージを時間差で表示
    _showRpgMessageAfterCrack(taskData);

    // さらに時間をおいてフェードアウト開始
    Timer(const Duration(milliseconds: 3000), () {
      setState(() {
        _fadingOutTaskIndex = taskIndex;
      });

      // フェードアウト完了後にタスクを削除
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _tasks.removeAt(taskIndex);
          _crackingTasks.remove(taskIndex);
          _fadingOutTaskIndex = -1;
        });
      });
    });
  }

  // ★★★ RPGメッセージボックスの改良版 ★★★
  Widget _buildRpgMessageBox() {
    if (_dialogueMessages.isEmpty) return const SizedBox.shrink();

    void _nextMessage() {
      if (_currentMessageIndex < _dialogueMessages.length - 1) {
        setState(() {
          _currentMessageIndex++;
        });
      } else {
        // 全てのメッセージを読み終わったらボックスを消す
        setState(() {
          _dialogueMessages = [];
          _currentMessageIndex = 0;
        });
      }
    }

    return Positioned(
      bottom: 100, // フッターナビゲーションの上に配置
      left: 10,
      right: 10,
      child: AnimatedOpacity(
        opacity: _dialogueMessages.isNotEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: _nextMessage,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              border: Border.all(color: Colors.yellow.shade600, width: 3.0),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Text(
                  _dialogueMessages[_currentMessageIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'misaki',
                    fontSize: 18,
                    height: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                // 最後のメッセージでなければ「次へ」の矢印を表示
                if (_currentMessageIndex < _dialogueMessages.length - 1)
                  Positioned(
                    bottom: -8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletinBoardPage(Map<String, dynamic> taskData) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // この課題が現在表示されているページのインデックス番号を取得
    final int taskIndex = _tasks.indexOf(taskData);
    if (taskIndex == -1) return const SizedBox(); // 既に削除されたタスクの場合は何も表示しない

    final bool isCracking = _crackingTasks.contains(taskIndex);
    // フェードアウト中のタスクかどうかを判定
    final bool isFadingOut = _fadingOutTaskIndex == taskIndex;

    // --- 討伐完了後に表示するシンプルなウィジェット ---

    // --- ここからがウィジェットの本体 ---
    return AnimatedOpacity(
      // フェードアウト中でない場合は透明度1.0(表示)、フェードアウト中なら0.0(非表示)
      opacity: isFadingOut ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 0), // フェードアウトの速さ
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
        ), // 左右に10%ずつの余白を追加
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- 背景の掲示板画像 ---
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset('assets/countdown.png', fit: BoxFit.contain),
              ),
            ),

            // --- 課題の詳細情報 ---
            Positioned(
              top: screenHeight * 0.155,
              left: 0,
              right: 0,
              height: screenHeight * 0.28,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 8.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: screenHeight * 0.035,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(
                            255,
                            42,
                            255,
                            255,
                          ).withOpacity(0.9),
                          letterSpacing: 1.0,
                          fontFamily: 'display_free_tfb',
                          shadows: [
                            BoxShadow(
                              color: const Color.fromARGB(
                                255,
                                6,
                                255,
                                255,
                              ).withOpacity(0.5),
                              blurRadius: 2,
                              spreadRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: const Color.fromARGB(
                                255,
                                11,
                                123,
                                215,
                              ).withOpacity(0.7),
                              blurRadius: 20,
                              spreadRadius: 20,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        children: <InlineSpan>[
                          TextSpan(text: _daysStr),
                          TextSpan(
                            text: 'd',
                            style: TextStyle(
                              fontFamily: 'misaki',
                              fontSize: screenHeight * 0.02,
                              color: Colors.white,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 8)),
                          TextSpan(text: _hoursStr),
                          TextSpan(
                            text: 'h',
                            style: TextStyle(
                              fontFamily: 'misaki',
                              fontSize: screenHeight * 0.02,
                              color: Colors.white,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 8)),
                          TextSpan(text: _minutesStr),
                          TextSpan(
                            text: 'm',
                            style: TextStyle(
                              fontFamily: 'misaki',
                              fontSize: screenHeight * 0.02,
                              color: Colors.white,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 8)),
                          TextSpan(text: _secondsStr),
                          TextSpan(
                            text: 's',
                            style: TextStyle(
                              fontFamily: 'misaki',
                              fontSize: screenHeight * 0.02,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      taskData['subject'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue[100]!.withOpacity(0.95),
                        fontFamily: 'misaki',
                        shadows: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        width: screenWidth * 0.45,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          "課題: ${taskData['name']}\n詳細: ${taskData['details']}\n期限: ${DateFormat('MM/dd HH:mm', 'ja').format(taskData['deadline'])}",
                          style: TextStyle(
                            fontSize: screenHeight * 0.020,
                            color: Colors.grey[100]!.withOpacity(0.95),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- 討伐人数ゲージ ---
            Positioned(
              top: screenHeight * 0.363,
              left: screenWidth * 0.08,
              width: screenWidth * 0.22,
              height: screenHeight * 0.035,
              child: TaskProgressGauge(
                defeatedCount:
                    isCracking
                        ? (taskData['defeatedCount'] ?? 0) + 1
                        : (taskData['defeatedCount'] ?? 0),
                totalParticipants: taskData['totalParticipants'] ?? 5,
              ),
            ),

            // --- 討伐ボタン ---
            Positioned(
              top: screenHeight * 0.208,
              right: screenWidth * 0.13,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  minimumSize: Size(screenWidth * 0.06, screenHeight * 0.035),
                  elevation: 8,
                  shadowColor: Colors.cyanAccent.withOpacity(0.6),
                ),
                onPressed: () => _submitTask(_currentPage),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: screenHeight * 0.021,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '討伐',
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'misaki',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- たこ焼きボタン ---
            Positioned(
              top: screenHeight * 0.33,
              right: screenWidth * 0.13,
              child: GestureDetector(
                onTap: _claimDailyTakoyaki,
                child: Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        _isTakoyakiClaimed
                            ? 'assets/takoyaki.png'
                            : 'assets/takoyaki_off.png',
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // --- 作成者アイコン ---
            Positioned(
              top: screenHeight * 0.2,
              left: screenWidth * 0.09,
              child: Container(
                width: screenWidth * 0.14,
                height: screenWidth * 0.14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.2,
                  ),
                  image: DecorationImage(
                    image: AssetImage(
                      _getCharacterImagePath(taskData['createdBy'] ?? 'ゴリラ'),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // ★★★ パリン！と割れるエフェクト用のオーバーレイ (修正箇所) ★★★
            if (isCracking)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Opacity(
                    opacity: 0.7,
                    child: Image.asset(
                      'assets/crack_overlay.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ★★★ このメソッドを、以下の完成版に丸ごと置き換えてください ★★★

  // ★★★ このメソッドを、以下の完成版に丸ごと置き換えてください ★★★

  void _submitTask(int taskIndex) async {
    // ★ asyncキーワードを追加
    // インデックスが有効か、または処理中でないかを確認
    if (taskIndex >= _tasks.length || _crackingTasks.contains(taskIndex)) {
      return;
    }

    // --- Step 1: 瞬時に「ひび割れ」を表示 ---
    setState(() {
      _crackingTasks.add(taskIndex);
    });

    // --- Step 2: ひび割れ画像を少しの間表示するために待機 (例: 500ミリ秒) ---
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return; // 待っている間にページが破棄された場合は処理を中断

    // --- Step 3: 報酬の獲得、タスクの削除、ひび割れの非表示をまとめて行う ---
    // 獲得する報酬の値を定義
    const int rewardExp = 5;
    const int rewardTakoyaki = 2;

    setState(() {
      // 報酬を加算
      _takoyakiCount += rewardTakoyaki;
      _gaugeKey.currentState?.addExperience(rewardExp);

      // タスクリストから削除
      _tasks.removeAt(taskIndex);

      // ひび割れ表示をリセット
      _crackingTasks.remove(taskIndex);

      // ページビューのインデックスを調整
      if (_tasks.isNotEmpty && _pageController.hasClients) {
        final newPageIndex = taskIndex.clamp(0, _tasks.length - 1);
        _pageController.jumpToPage(newPageIndex);
      }
    });

    // ★★★ SnackBarで討伐完了と報酬獲得の通知をすぐに表示 ★★★
  }

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

  // ★★★ initStateメソッドを、以下のコードに置き換えてください ★★★
  @override
  void initState() {
    super.initState();
    _loadTakoyakiStatus();
    _loadCharacterInfoFromFirebase();
    _startCountdownTimer();
    _calculateWeekDateRange();

    // 初回アクセス時にKOANのスケジュールURL入力ダイアログを表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowKoanUrlDialog();
    });
  }

  // KOANのスケジュールURL入力ダイアログを表示するメソッド
  Future<void> _checkAndShowKoanUrlDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownKoanDialog = prefs.getBool('hasShownKoanDialog') ?? false;

    if (!hasShownKoanDialog) {
      if (mounted) {
        _showKoanUrlDialog();
      }
    }
  }

  void _showKoanUrlDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'KOANのスケジュール設定',
            style: TextStyle(fontFamily: 'misaki', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'あなたのKOANのスケジュールを表示するために、以下の手順でURLを取得してください：',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '1. 大阪大学KOANにログイン\n'
                '2. スケジュール画面を開く\n'
                '3. 「カレンダー」タブをクリック\n'
                '4. 「iCal」ボタンをクリック\n'
                '5. 表示されたURLをコピー',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'KOANのスケジュールURL',
                  hintText:
                      'https://g-calendar.koan.osaka-u.ac.jp/calendar/...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 8),
              Text(
                '※後で設定画面から変更できます',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // スキップボタン
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasShownKoanDialog', true);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('スキップ'),
            ),
            ElevatedButton(
              onPressed: () async {
                final url = urlController.text.trim();
                if (url.isNotEmpty && url.contains('koan.osaka-u.ac.jp')) {
                  // URLを保存
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('koanScheduleUrl', url);
                  await prefs.setBool('hasShownKoanDialog', true);

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('スケジュールURLを保存しました！'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  // エラーメッセージを表示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('正しいKOANのURLを入力してください'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // Firebaseからキャラクター情報を取得するメソッドを追加
  Future<void> _loadCharacterInfoFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _currentParkCharacterName =
                data['character'] ?? widget.diagnosedCharacterName;
            _userName = data['name'] ?? widget.userName;
            if (data['characterImage'] != null) {
              _currentParkCharacterImage = data['characterImage'];
            } else if (characterFullDataGlobal.containsKey(
              _currentParkCharacterName,
            )) {
              _currentParkCharacterImage =
                  characterFullDataGlobal[_currentParkCharacterName]!['image'];
            }
            _isCharacterInfoInitialized = true;
          });
        } else {
          // Firebaseにデータがない場合は、コンストラクタから渡された情報を使用
          setState(() {
            _currentParkCharacterName = widget.diagnosedCharacterName;
            _userName = widget.userName;
            if (characterFullDataGlobal.containsKey(
              widget.diagnosedCharacterName,
            )) {
              _currentParkCharacterImage =
                  characterFullDataGlobal[widget
                      .diagnosedCharacterName]!['image'];
            }
            _isCharacterInfoInitialized = true;
          });
        }
      } else {
        // ユーザーがログインしていない場合
        setState(() {
          _currentParkCharacterName = widget.diagnosedCharacterName;
          _userName = widget.userName;
          if (characterFullDataGlobal.containsKey(
            widget.diagnosedCharacterName,
          )) {
            _currentParkCharacterImage =
                characterFullDataGlobal[widget
                    .diagnosedCharacterName]!['image'];
          }
          _isCharacterInfoInitialized = true;
        });
      }
    } catch (e) {
      print('Error loading character info from Firebase: $e');
      // エラーが発生した場合は、コンストラクタから渡された情報を使用
      setState(() {
        _currentParkCharacterName = widget.diagnosedCharacterName;
        _userName = widget.userName;
        if (characterFullDataGlobal.containsKey(
          widget.diagnosedCharacterName,
        )) {
          _currentParkCharacterImage =
              characterFullDataGlobal[widget.diagnosedCharacterName]!['image'];
        }
        _isCharacterInfoInitialized = true;
      });
    }
  }

  final GlobalKey<LiquidLevelGaugeState> _gaugeKey =
      GlobalKey<LiquidLevelGaugeState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // ★★★ disposeメソッドを、以下のコードに置き換えてください ★★★
  @override
  void dispose() {
    // initStateで追加したリスナーをここで必ず解除します
    _pageController.dispose(); // PageController自体のdisposeも忘れずに
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

  // ★★★ このメソッドを丸ごと置き換え ★★★
  // ★★★ このメソッドを丸ごと置き換え ★★★
  void _updateCountdownText() {
    if (_tasks.isEmpty || _currentPage >= _tasks.length) return;
    final currentTask = _tasks[_currentPage];
    final DateTime taskDeadline = currentTask['deadline'];

    final now = DateTime.now();
    final difference = taskDeadline.difference(now);

    if (difference.isNegative) {
      if (mounted) {
        setState(() {
          _daysStr = "0";
          _hoursStr = "00";
          _minutesStr = "00";
          _secondsStr = "00";
        });
      }
      _timer?.cancel();
    } else {
      final days = difference.inDays;
      final hours = difference.inHours.remainder(24);
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);

      // 新しいState変数に値をセット
      if (mounted) {
        setState(() {
          _daysStr = days.toString();
          _hoursStr = hours.toString().padLeft(2, '0');
          _minutesStr = minutes.toString().padLeft(2, '0');
          _secondsStr = seconds.toString().padLeft(2, '0');
        });
      }
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

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber[200]),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'misaki',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.amber.withOpacity(0.1),
    );
  }

  // ★★★ buildメソッドを、以下の完成版に丸ごと置き換えてください ★★★

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double topBarHeight = screenHeight * 0.08;
    final double singleBannerWidth = screenWidth * 0.30;
    final double bottomNavBarHeight = 75.0;

    final double logoSize = screenWidth * 0.13;

    // --- ボタンをページと連動させるためのアニメーション値の計算 ---
    final double distance = (_pageOffset - _currentPage).abs();
    final double scale = (1 - (distance * 0.5)).clamp(0.5, 1.0);
    final double opacity = (1 - distance).clamp(0.0, 1.0);

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      endDrawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/ranking_guild_background.png'), // 木目調など
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.amber[300]!, width: 2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.menu_book, color: Colors.white, size: 36),
                    SizedBox(height: 10),
                    Text(
                      '冒険のメニュー',
                      style: TextStyle(
                        fontFamily: 'misaki',
                        color: Colors.white,
                        fontSize: 22,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerTile(Icons.school_outlined, 'KOAN', () {
                _launchURL(
                  'https://koan.osaka-u.ac.jp/campusweb/campusportal.do?page=main',
                );
              }),
              _buildDrawerTile(Icons.book_outlined, 'CLE', () {
                _launchURL('https://www.cle.osaka-u.ac.jp/ultra/course');
              }),
              _buildDrawerTile(Icons.person_outline, 'マイハンダイ', () {
                _launchURL('https://my.osaka-u.ac.jp/');
              }),
              _buildDrawerTile(Icons.mail_outline, 'OU-Mail', () {
                _launchURL('https://outlook.office.com/mail/');
              }),
              Divider(color: Colors.amber[200]),
              _buildDrawerTile(Icons.mail, 'お問い合わせ', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MailPage()),
                );
              }),
              _buildDrawerTile(Icons.info_outline, 'お知らせを見る', () {
                Navigator.pop(context);
                _showNoticeDialog(context);
              }),
              Divider(color: Colors.amber[200]),
              _buildDrawerTile(Icons.settings, '設定', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingPage()),
                );
              }),
              _buildDrawerTile(Icons.help_outline, 'ヘルプ', () {
                Navigator.pop(context);
              }),
              _buildDrawerTile(Icons.report_problem_outlined, 'ユーザー通報', () {
                Navigator.pop(context);
              }),
              const SizedBox(height: 20), // 下の余白を確保
            ],
          ),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/night_view.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomNavBarHeight),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 160, // 上端の位置を少し上に
                      bottom: 0,
                      left: 0, // 左右の余白を削除（paddingで制御するため）
                      right: 0,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (int page) {
                          setState(() {
                            _currentPage = page;
                            _updateCountdownText();
                          });
                        },
                        children:
                            _tasks
                                .map(
                                  (taskData) =>
                                      _buildBulletinBoardPage(taskData),
                                )
                                .toList(),
                      ),
                    ),
                    Positioned(
                      // top: 画面の上端からの距離 (画面の高さに対する割合で指定)
                      // この値を調整して、キャラクターの垂直位置を微調整してください。
                      top: screenHeight * 0.04,

                      // left: 画面の左端からの距離
                      // 画像を水平方向の中央に配置するための計算式です。
                      // (画面全体の幅 - 画像の幅) / 2
                      left: (screenWidth - (screenWidth * 0.65)) / 8,

                      child: Image.asset(
                        "assets/floating.png", // ご指定の画像パス
                        width: screenWidth * 0.55, // ご指定の幅
                        height: screenHeight * 0.45, // ご指定の高さ
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      // top: 画面の上端からの距離 (画面の高さに対する割合で指定)
                      // この値を調整して、キャラクターの垂直位置を微調整してください。
                      top: screenHeight * 0.05,

                      // left: 画面の左端からの距離
                      // 画像を水平方向の中央に配置するための計算式です。
                      // (画面全体の幅 - 画像の幅) / 2
                      left: (screenWidth - (screenWidth * 0.65)) / 2.8,

                      child: Image.asset(
                        _currentParkCharacterImage, // ご指定の画像パス
                        width: screenWidth * 0.38, // ご指定の幅
                        height: screenHeight * 0.28, // ご指定の高さ
                        fit: BoxFit.contain,
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      child: Column(
                        children: [
                          if (_userName.isNotEmpty)
                            Text(
                              _userName,
                              style: TextStyle(
                                fontFamily: 'misaki',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 2),
                                ],
                              ),
                            ),

                          LiquidLevelGauge(
                            key: _gaugeKey,
                            width: screenWidth * 0.28,
                            height: topBarHeight * 0.70,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 3,
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: const Color.fromARGB(255, 26, 186, 222),
                          size: topBarHeight * 0.50,
                        ),
                        onPressed:
                            () => _scaffoldKey.currentState?.openEndDrawer(),
                        padding: const EdgeInsets.only(left: 4.0),
                        constraints: BoxConstraints(
                          minWidth: topBarHeight * 0.5,
                        ),
                      ),
                    ),
                    //Positioned(
                    //top: 20,
                    //left: MediaQuery.of(context).size.width * 0.3,
                    //child: Image.asset(
                    //'assets/banner_news.png',
                    //width: singleBannerWidth,
                    //height: topBarHeight * 0.75,
                    //fit: BoxFit.contain,
                    //),
                    //),
                    Positioned(
                      top: 75,
                      left: -1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: screenWidth * 0.28,
                            height: topBarHeight * 0.50,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/ui_takoyaki_bar.png'),
                                fit: BoxFit.fill,
                              ),
                            ),
                            padding: const EdgeInsets.only(
                              left: 30.0,
                              right: 20.0,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$_takoyakiCount',
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
                          Positioned(
                            right: -2,
                            child: GestureDetector(
                              onTap: () => _showPurchaseDialog(context),
                              child: Container(
                                padding: const EdgeInsets.all(1.0),
                                child: Image.asset(
                                  'assets/icon_plus.png',
                                  width: topBarHeight * 0.4,
                                  height: topBarHeight * 0.4,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      child: GestureDetector(
                        onTap:
                            () => setState(() {
                              isQuestCreationVisible = true;
                            }),
                        child: Image.asset(
                          'assets/make_quest.png',
                          width: 360,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (_dialogueMessages
                        .isNotEmpty) // ★ メッセージがある場合はメッセージボックスを表示
                      _buildRpgMessageBox()
                    else // ★ メッセージがない場合はクエスト作成ボタンを表示
                      Positioned(
                        bottom: 40,
                        child: GestureDetector(
                          onTap: () {
                            // ★ このボタンを押した時に会話を開始するテスト例
                            // _showDialogue([
                            //   "やあ、何か新しいクエストを作成するのかい？",
                            //   "締切には気をつけるんだぞ！",
                            // ]);
                            setState(() {
                              isQuestCreationVisible = true;
                            });
                          },
                          child: Image.asset(
                            'assets/make_quest.png',
                            width: 360,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CommonBottomNavigation(),
          ),
          if (isQuestCreationVisible)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: QuestCreationWidget(
                  onCancel:
                      () => setState(() {
                        isQuestCreationVisible = false;
                      }),
                  onCreate: (selectedClass, taskType, deadline, description) {
                    print(
                      '授業: $selectedClass, タスク: $taskType, 締切: $deadline, 詳細: $description',
                    );

                    // 新しいクエストを_tasksリストに追加
                    final newTask = {
                      'subject': selectedClass,
                      'name': taskType,
                      'details': description,
                      'deadline': deadline,
                      'isSubmitted': false,
                      'defeatedCount': 0,
                      'totalParticipants': 1,
                      'reward': 10, // デフォルト報酬
                      'createdBy': widget.userName,
                      'createdAt': DateTime.now(),
                    };

                    setState(() {
                      _tasks.add(newTask);
                      isQuestCreationVisible = false;
                    });

                    // 成功メッセージを表示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'クエスト「$selectedClass - $taskType」を作成しました！',
                          style: const TextStyle(fontFamily: 'misaki'),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned(
            right: 115,
            top: 60,
            child: GestureDetector(
              onTap: () => _showOztechDialog(context),
              child: Opacity(
                opacity: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.asset(
                    'assets/oztech.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 60,
            child: GestureDetector(
              onTap: () => _showPotiPotiDialog(context),
              child: Opacity(
                opacity: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.asset(
                    'assets/potipoti.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // キャラクター名から画像パスを取得する関数
  String _getCharacterImagePath(String characterName) {
    final characterData = characterFullDataGlobal[characterName];
    if (characterData != null && characterData['image'] != null) {
      return characterData['image'];
    }
    // デフォルトはゴリラ画像
    return 'assets/character_gorilla.png';
  }
}
