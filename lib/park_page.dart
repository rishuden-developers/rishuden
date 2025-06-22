import 'package:flutter/material.dart';
import 'dart:async'; // Timer.periodic のために必要
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/timetable_provider.dart';

class ParkPage extends ConsumerStatefulWidget {
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
  ConsumerState<ParkPage> createState() => _ParkPageState();
}

class _ParkPageState extends ConsumerState<ParkPage> {
  String _currentParkCharacterImage = '';
  String _currentParkCharacterName = '';
  String _userName = '';

  List<String> _dialogueMessages = [];
  int _currentMessageIndex = 0;

  // Firestoreから取得したクエストデータをローカルで管理
  List<Map<String, dynamic>> _quests = [];
  bool _isLoadingQuests = true;

  final PageController _pageController = PageController(
    viewportFraction: 1.0,
    keepPage: true,
  );
  int _currentPage = 0;
  Timer? _timer;

  String? _fadingOutTaskIndex;
  final Set<String> _crackingTasks = {};

  bool _isCharacterInfoInitialized = false;
  bool isQuestCreationVisible = false;
  int _takoyakiCount = 0;
  double _pageOffset = 0.0;

  bool _isTakoyakiClaimed = false;
  Timer? _rpgMessageTimer;

  final GlobalKey<LiquidLevelGaugeState> _gaugeKey =
      GlobalKey<LiquidLevelGaugeState>();

  @override
  void initState() {
    super.initState();
    _loadTakoyakiStatus();
    _loadCharacterInfoFromFirebase();
    _loadQuestsFromFirestore();
    _loadUserDataFromFirebase();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _rpgMessageTimer?.cancel();
    super.dispose();
  }

  void _loadTakoyakiStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String todayKey =
        'takoyakiClaimed_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    if (!mounted) return;
    setState(() {
      _isTakoyakiClaimed = prefs.getBool(todayKey) ?? false;
    });
  }

  void _claimDailyTakoyaki() async {
    if (_isTakoyakiClaimed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '今日のたこ焼きはもう受け取ったで！また明日な！',
            style: TextStyle(fontFamily: 'misaki', color: Colors.white),
          ),
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 2.5),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _takoyakiCount += 10;
      _isTakoyakiClaimed = true;
    });

    // Firebaseにたこ焼き数を保存
    await _saveTakoyakiCountToFirebase();

    final prefs = await SharedPreferences.getInstance();
    final String todayKey =
        'takoyakiClaimed_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    await prefs.setBool(todayKey, true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'たこ焼きを10個ゲットした！',
          style: TextStyle(fontFamily: 'misaki', color: Colors.white),
        ),
        backgroundColor: Colors.black.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white, width: 2.5),
        ),
      ),
    );
  }

  void _showRpgMessageAfterCrack(Map<String, dynamic> taskData) {
    _rpgMessageTimer?.cancel();
    _rpgMessageTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _dialogueMessages = [
          "課題「${taskData['name']}」を討伐完了！",
          "たこ焼き${taskData['reward'] ?? 10}個を獲得した！",
          "よくやったな、冒険者よ...",
        ];
        _currentMessageIndex = 0;
      });
    });
  }

  void _createQuest(
    Map<String, dynamic> selectedClass,
    String taskType,
    DateTime deadline,
    String description,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('quests').add({
        'name': selectedClass['subjectName'],
        'courseId': selectedClass['courseId'], // courseIdを保存
        'taskType': taskType,
        'deadline': Timestamp.fromDate(deadline),
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'completedUserIds': [], // 初期値
      });

      // クエスト作成後にリストを再読み込み
      await _loadQuestsFromFirestore();
    } catch (e) {
      print('Error creating quest: $e');
      // エラーハンドリング
    }
  }

  void _submitTask(String questId, Map<String, dynamic> taskData) async {
    if (_crackingTasks.contains(questId)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // ユーザーがいない場合は何もしない

    if (!mounted) return;
    setState(() {
      _crackingTasks.add(questId);
    });

    _showRpgMessageAfterCrack(taskData);

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // ★★★ ここからが追加箇所 ★★★
    // Firestoreのクエストドキュメントに討伐したユーザーIDを追加
    await FirebaseFirestore.instance.collection('quests').doc(questId).set({
      'completedUserIds': FieldValue.arrayUnion([user.uid]),
    }, SetOptions(merge: true));
    // ★★★ ここまでが追加箇所 ★★★

    setState(() {
      _fadingOutTaskIndex = questId;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    // 討伐後、クエストをリストから削除するロジックは一旦コメントアウトし、
    // 代わりにUIを更新して討伐済み状態を示すように変更する可能性があります。
    // await FirebaseFirestore.instance.collection('quests').doc(questId).delete();

    const int rewardExp = 5;
    const int rewardTakoyaki = 2;

    setState(() {
      _takoyakiCount += rewardTakoyaki;
      _gaugeKey.currentState?.addExperience(rewardExp);
      _crackingTasks.remove(questId);
      if (_fadingOutTaskIndex == questId) {
        _fadingOutTaskIndex = null;
      }
      // UI上は即座にリストから削除するが、ドキュメントは残す
      _quests.removeWhere((quest) => quest['id'] == questId);
    });

    // Firebaseにたこ焼き数を保存
    await _saveTakoyakiCountToFirebase();
  }

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
          if (!mounted) return;
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
        }
      }
    } catch (e) {
      print('Error loading character info from Firebase: $e');
    }
    if (!_isCharacterInfoInitialized && mounted) {
      setState(() {
        _currentParkCharacterName = widget.diagnosedCharacterName;
        _userName = widget.userName;
        _currentParkCharacterImage =
            characterFullDataGlobal[widget.diagnosedCharacterName]?['image'] ??
            'assets/character_gorilla.png';
        _isCharacterInfoInitialized = true;
      });
    }
  }

  String _getCharacterImagePath(String characterName) {
    return characterFullDataGlobal[characterName]?['image'] ??
        'assets/character_gorilla.png';
  }

  // Firestoreからクエストデータを読み込む
  Future<void> _loadQuestsFromFirestore() async {
    setState(() {
      _isLoadingQuests = true;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('quests')
              .orderBy('deadline', descending: false)
              .get();

      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _quests = [];
          _isLoadingQuests = false;
        });
        return;
      }

      final quests =
          snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();

      // 自分が既に完了したクエストを除外
      final filteredQuests =
          quests.where((quest) {
            final completedBy = quest['completedUserIds'] as List<dynamic>?;
            return completedBy == null || !completedBy.contains(user.uid);
          }).toList();

      setState(() {
        _quests = filteredQuests;
        _isLoadingQuests = false;
      });
    } catch (e) {
      print('Error loading quests: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingQuests = false;
      });
    }
  }

  // クエスト作成後にデータを再読み込み
  Future<void> _refreshQuests() async {
    await _loadQuestsFromFirestore();
  }

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
  Widget build(BuildContext context) {
    // Riverpodから時間割データを取得
    final timetableAsyncValue = ref.watch(timetableProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double topBarHeight = screenHeight * 0.08;
    final double logoSize = screenWidth * 0.13;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/night_view.png', fit: BoxFit.cover),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
        SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ... Top UI Elements ...
              Positioned(
                top: 0,
                left: 0,
                child: Column(
                  children: [
                    if (_userName.isNotEmpty)
                      Text(
                        _userName,
                        style: const TextStyle(
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
                      onExpChanged: _saveExpAndLevelToFirebase,
                    ),
                  ],
                ),
              ),
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
                      padding: const EdgeInsets.only(left: 30.0, right: 20.0),
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
                        onTap: () {}, // _showPurchaseDialog(context),
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
                top: 160,
                bottom: 0,
                left: 0,
                right: 0,
                child:
                    _isLoadingQuests
                        ? const Center(child: CircularProgressIndicator())
                        : _quests.isEmpty
                        ? const Center(
                          child: Text(
                            '現在、討伐対象のクエストはありません。',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'misaki',
                              fontSize: 16,
                            ),
                          ),
                        )
                        : PageView.builder(
                          controller: _pageController,
                          onPageChanged: (int page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          itemCount: _quests.length,
                          physics: const ClampingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final taskData = _quests[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: _buildBulletinBoardPage(taskData),
                            );
                          },
                        ),
              ),
              Positioned(
                top: screenHeight * 0.04,
                left: (screenWidth - (screenWidth * 0.65)) / 8,
                child: IgnorePointer(
                  child: Image.asset(
                    "assets/floating.png",
                    width: screenWidth * 0.55,
                    height: screenHeight * 0.45,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.05,
                left: (screenWidth - (screenWidth * 0.65)) / 2.8,
                child: IgnorePointer(
                  child: Image.asset(
                    _currentParkCharacterImage.isNotEmpty
                        ? _currentParkCharacterImage
                        : 'assets/character_gorilla.png',
                    width: screenWidth * 0.38,
                    height: screenHeight * 0.28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // ... Other UI Elements ...
              if (_dialogueMessages.isEmpty)
                Positioned(
                  bottom: 40,
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => isQuestCreationVisible = true);
                    },
                    child: Image.asset(
                      'assets/make_quest.png',
                      width: 360,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                _buildRpgMessageBox(),
              Positioned(
                right: 115,
                top: 0,
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
                top: 0,
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
        ),

        if (isQuestCreationVisible)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: QuestCreationWidget(
                onCancel: () => setState(() => isQuestCreationVisible = false),
                onCreate: (selectedClass, taskType, deadline, description) {
                  // ★★★ _createQuestを呼び出すように変更 ★★★
                  _createQuest(selectedClass, taskType, deadline, description);
                  setState(() {
                    isQuestCreationVisible = false;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBulletinBoardPage(Map<String, dynamic> taskData) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final questId = taskData['id'] as String;
    final isCracking = _crackingTasks.contains(questId);
    final isFadingOut = _fadingOutTaskIndex == questId;

    final deadline = taskData['deadline'] as Timestamp?;
    final deadlineText =
        deadline != null
            ? DateFormat('MM/dd HH:mm').format(deadline.toDate())
            : '期限なし';
    final questName = taskData['name'] as String? ?? '名称未設定';
    final description = taskData['description'] as String? ?? '';

    return AnimatedOpacity(
      opacity: isFadingOut ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 500),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/countdown.png', fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: screenHeight * 0.135,
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
                  _buildCountdownText(taskData),
                  const SizedBox(height: 4),
                  Text(
                    questName,
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
                        "課題: $questName\n詳細: $description\n期限: $deadlineText",
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
          Positioned(
            top: screenHeight * 0.208,
            right: screenWidth * 0.13,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                minimumSize: Size(screenWidth * 0.06, screenHeight * 0.035),
                elevation: 8,
                shadowColor: Colors.cyanAccent.withOpacity(0.6),
              ),
              onPressed: () => _submitTask(questId, taskData),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/buttons/common_navigation/park_active.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text('討伐'),
                ],
              ),
            ),
          ),
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
          // ★★★ 討伐人数表示を追加 ★★★
          Positioned(
            top: screenHeight * 0.363,
            right: screenWidth * 0.08,
            child: FutureBuilder<Map<String, int>>(
              future: _getSubjugationInfo(questId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (!snapshot.hasData || snapshot.hasError) {
                  return const SizedBox.shrink(); // エラー時は何も表示しない
                }
                final counts = snapshot.data!;
                return Row(
                  children: [
                    Icon(Icons.people, color: Colors.grey[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${counts['completed']} / ${counts['total']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownText(Map<String, dynamic> taskData) {
    return _CountdownWidget(
      deadline: (taskData['deadline'] as Timestamp).toDate(),
    );
  }

  Widget _buildRpgMessageBox() {
    if (_dialogueMessages.isEmpty) return const SizedBox.shrink();
    return Positioned(
      bottom: 100,
      left: 10,
      right: 10,
      child: AnimatedOpacity(
        opacity: _dialogueMessages.isNotEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: () {
            if (_currentMessageIndex < _dialogueMessages.length - 1) {
              setState(() => _currentMessageIndex++);
            } else {
              setState(() {
                _dialogueMessages = [];
                _currentMessageIndex = 0;
              });
            }
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 120,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 3.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
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
                if (_currentMessageIndex < _dialogueMessages.length - 1)
                  Positioned(
                    bottom: -8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
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

  String _formatDeadline(Timestamp deadline) {
    // This is a placeholder. You'll need a proper countdown logic.
    return DateFormat('MM/dd HH:mm').format(deadline.toDate());
  }

  // ★★★ ユーザーデータ（たこ焼き、EXP、レベル）をFirebaseから読み込み ★★★
  Future<void> _loadUserDataFromFirebase() async {
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
          if (!mounted) return;
          setState(() {
            _takoyakiCount = data['takoyakiCount'] ?? 0;
          });
          // EXPとレベルも読み込み
          final currentExp = data['currentExp'] ?? 0;
          final currentLevel = data['currentLevel'] ?? 1;
          final expForNextLevel = data['expForNextLevel'] ?? 100;
          _gaugeKey.currentState?.loadFromFirebase(
            currentExp,
            currentLevel,
            expForNextLevel,
          );

          // デフォルト値が設定されていない場合は保存
          if (data['takoyakiCount'] == null ||
              data['currentExp'] == null ||
              data['currentLevel'] == null) {
            await _saveTakoyakiCountToFirebase();
            await _saveExpAndLevelToFirebase(
              currentExp,
              currentLevel,
              expForNextLevel,
            );
          }
        } else {
          // ユーザードキュメントが存在しない場合はデフォルト値を保存
          await _saveTakoyakiCountToFirebase();
          await _saveExpAndLevelToFirebase(0, 1, 100);
        }
      }
    } catch (e) {
      print('Error loading user data from Firebase: $e');
    }
  }

  // ★★★ たこ焼き数をFirebaseに保存 ★★★
  Future<void> _saveTakoyakiCountToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'takoyakiCount': _takoyakiCount});
      }
    } catch (e) {
      print('Error saving takoyaki count to Firebase: $e');
    }
  }

  // ★★★ EXPとレベルをFirebaseに保存 ★★★
  Future<void> _saveExpAndLevelToFirebase(
    int currentExp,
    int currentLevel,
    int expForNextLevel,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'currentExp': currentExp,
              'currentLevel': currentLevel,
              'expForNextLevel': expForNextLevel,
            });
      }
    } catch (e) {
      print('Error saving EXP and level to Firebase: $e');
    }
  }

  // ★★★ このメソッドを新しく追加 ★★★
  Future<Map<String, int>> _getSubjugationInfo(String? questId) async {
    if (questId == null) {
      return {'completed': 0, 'total': 0};
    }

    try {
      final questDoc =
          await FirebaseFirestore.instance
              .collection('quests')
              .doc(questId)
              .get();
      final questData = questDoc.data();
      final completedUserIds =
          (questData?['completedUserIds'] as List?)?.length ?? 0;
      final courseId = questData?['courseId'] as String?;

      if (courseId == null) {
        return {'completed': completedUserIds, 'total': 0};
      }

      final enrollmentDoc =
          await FirebaseFirestore.instance
              .collection('course_enrollments')
              .doc(courseId)
              .get();
      final totalUserIds =
          (enrollmentDoc.data()?['enrolledUserIds'] as List?)?.length ?? 0;

      return {'completed': completedUserIds, 'total': totalUserIds};
    } catch (e) {
      print('Error getting subjugation info: $e');
      return {'completed': 0, 'total': 0};
    }
  }

  // ★★★ ここまで ★★★
}

class _CountdownWidget extends StatefulWidget {
  final DateTime deadline;

  const _CountdownWidget({required this.deadline});

  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget> {
  Timer? _timer;
  String _daysStr = "0";
  String _hoursStr = "00";
  String _minutesStr = "00";
  String _secondsStr = "00";

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCountdown();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final difference = widget.deadline.difference(now);

    if (difference.isNegative) {
      if (mounted) {
        setState(() {
          _daysStr = "0";
          _hoursStr = "00";
          _minutesStr = "00";
          _secondsStr = "00";
        });
      }
    } else {
      final days = difference.inDays;
      final hours = difference.inHours.remainder(24);
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);

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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: screenHeight * 0.035,
          fontWeight: FontWeight.bold,
          color: const Color.fromRGBO(255, 255, 255, 0.9),
          fontFamily: 'display_free_tfb',
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 8,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        children: <InlineSpan>[
          TextSpan(
            text: _daysStr,
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 255), // 蛍光の水色
              shadows: [
                Shadow(
                  color: const Color.fromARGB(
                    255,
                    0,
                    255,
                    255,
                  ).withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          TextSpan(
            text: 'd',
            style: TextStyle(
              fontFamily: 'misaki',
              fontSize: screenHeight * 0.02,
              color: Colors.white,
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(
            text: _hoursStr,
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 255), // 蛍光の水色
              shadows: [
                Shadow(
                  color: const Color.fromARGB(
                    255,
                    0,
                    255,
                    255,
                  ).withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          TextSpan(
            text: 'h',
            style: TextStyle(
              fontFamily: 'misaki',
              fontSize: screenHeight * 0.02,
              color: Colors.white,
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(
            text: _minutesStr,
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 255), // 蛍光の水色
              shadows: [
                Shadow(
                  color: const Color.fromARGB(
                    255,
                    0,
                    255,
                    255,
                  ).withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          TextSpan(
            text: 'm',
            style: TextStyle(
              fontFamily: 'misaki',
              fontSize: screenHeight * 0.02,
              color: Colors.white,
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(
            text: _secondsStr,
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 255), // 蛍光の水色
              shadows: [
                Shadow(
                  color: const Color.fromARGB(
                    255,
                    0,
                    255,
                    255,
                  ).withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
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
    );
  }
}
