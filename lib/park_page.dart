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
  int _takoyakiCount = 13800;
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
    if (!mounted) return;
    setState(() {
      _takoyakiCount += 10;
      _isTakoyakiClaimed = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String todayKey =
        'takoyakiClaimed_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    await prefs.setBool(todayKey, true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('たこ焼きを10個ゲットした！', style: TextStyle(fontFamily: 'misaki')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRpgMessageAfterCrack(Map<String, dynamic> taskData) {
    _rpgMessageTimer?.cancel();
    _rpgMessageTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
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

  void _submitTask(String questId, Map<String, dynamic> taskData) async {
    if (_crackingTasks.contains(questId)) return;

    if (!mounted) return;
    setState(() {
      _crackingTasks.add(questId);
    });

    _showRpgMessageAfterCrack(taskData);

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;
    setState(() {
      _fadingOutTaskIndex = questId;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    await FirebaseFirestore.instance.collection('quests').doc(questId).delete();

    const int rewardExp = 5;
    const int rewardTakoyaki = 2;

    setState(() {
      _takoyakiCount += rewardTakoyaki;
      _gaugeKey.currentState?.addExperience(rewardExp);
      _crackingTasks.remove(questId);
      if (_fadingOutTaskIndex == questId) {
        _fadingOutTaskIndex = null;
      }
      _quests.removeWhere((quest) => quest['id'] == questId);
    });
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
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('quests')
              .orderBy('createdAt', descending: true)
              .get();

      if (mounted) {
        setState(() {
          _quests =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();
          _isLoadingQuests = false;
        });
      }
    } catch (e) {
      print('Error loading quests: $e');
      if (mounted) {
        setState(() {
          _isLoadingQuests = false;
        });
      }
    }
  }

  // クエスト作成後にデータを再読み込み
  Future<void> _refreshQuests() async {
    await _loadQuestsFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
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
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('クエストを作成するにはログインが必要です。'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  final newQuest = {
                    'subject': selectedClass,
                    'name': taskType,
                    'details': description,
                    'deadline': Timestamp.fromDate(deadline),
                    'isSubmitted': false,
                    'defeatedCount': 0,
                    'totalParticipants': 1,
                    'reward': 10,
                    'createdBy': widget.userName,
                    'creatorId': user.uid,
                    'createdAt': FieldValue.serverTimestamp(),
                  };
                  FirebaseFirestore.instance
                      .collection('quests')
                      .add(newQuest)
                      .then((_) async {
                        setState(() => isQuestCreationVisible = false);
                        await _refreshQuests(); // データを再読み込み
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'クエスト「$selectedClass - $taskType」を作成しました！',
                              style: const TextStyle(fontFamily: 'misaki'),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      })
                      .catchError((error) {
                        setState(() => isQuestCreationVisible = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('エラー: クエストの作成に失敗しました。'),
                            backgroundColor: Colors.red,
                          ),
                        );
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
                  // Countdown Text - 各掲示板で個別に管理
                  _buildCountdownText(taskData),
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
                        "課題: ${taskData['name']}\n詳細: ${taskData['details']}\n期限: ${DateFormat('MM/dd HH:mm', 'ja').format((taskData['deadline'] as Timestamp).toDate())}",
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

  String _formatDeadline(Timestamp deadline) {
    // This is a placeholder. You'll need a proper countdown logic.
    return DateFormat('MM/dd HH:mm').format(deadline.toDate());
  }
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
