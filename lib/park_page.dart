import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Timer.periodic のために必要
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'task_progress_gauge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'character_data.dart' show characterFullDataGlobal;
import 'level_gauge.dart';
import 'quest_create.dart'; // QuestCreationWidgetのインポート
import 'dart:ui';
import 'dart:convert';
import 'dart:math' as math;
// ignore: unused_import
import 'setting_page/setting_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/timetable_provider.dart';
import 'services/notification_service.dart';
import 'providers/background_image_provider.dart';
import 'constants/ui_flags.dart' as ui_flags;

class ParkPage extends ConsumerStatefulWidget {
  final String diagnosedCharacterName;
  final List<int> answers;
  final String userName;
  final String? grade;
  final String? department;
  final String universityType;

  const ParkPage({
    super.key,
    required this.diagnosedCharacterName,
    required this.answers,
    required this.userName,
    this.grade,
    this.department,
    this.universityType = 'main',
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
  // ignore: unused_field
  int _currentPage = 0;
  Timer? _timer;

  String? _fadingOutTaskIndex;
  final Set<String> _crackingTasks = {};

  bool _isCharacterInfoInitialized = false;
  bool isQuestCreationVisible = false;
  int _takoyakiCount = 0;
  // ignore: unused_field
  double _pageOffset = 0.0;

  bool _isTakoyakiClaimed = false;
  Timer? _rpgMessageTimer;

  final GlobalKey<LiquidLevelGaugeState> _gaugeKey =
      GlobalKey<LiquidLevelGaugeState>();

  // --- Simple ToDo UI enhancement states ---
  // タブは廃止。Myタスクのみを表示。
  static const Color _cWhite = Color(0xFFFFFFFF);
  static const Color _cBlack = Color(0xFF000000);
  static const Color _cBlue = Color(0xFF0B5FFF);
  // UI 切替フラグをグローバル設定から取得
  int _segmentIndex = 0; // 0: 未完了, 1: 完了（iOS風セグメント）
  // 未完了→完了時にチェック円の上でパルスを出すためのIDセット
  final Set<String> _pulsingChecks = <String>{};

  void _playCheckPulse(String questId) {
    setState(() {
      _pulsingChecks.add(questId);
    });
  }

  // 授業に関係ないローカルToDo（DBを触らない）
  List<Map<String, dynamic>> _localTodos = [];
  // Firestore由来の完了一覧（自分がcompletedUserIdsに含まれる）
  List<Map<String, dynamic>> _completedQuests = [];

  @override
  void initState() {
    super.initState();
    _loadTakoyakiStatus();
    _loadCharacterInfoFromFirebase();
    _loadQuestsFromFirestore();
    _loadUserDataFromFirebase();
    _loadLocalTodos();
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

  // ignore: unused_element
  void _claimDailyTakoyaki() async {
    if (_isTakoyakiClaimed) {
      setState(() {
        _dialogueMessages = ["今日のログインボーナスはもう受け取ったで！", "また明日な！"];
        _currentMessageIndex = 0;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _takoyakiCount += 1; // 10個→1個に変更
      _isTakoyakiClaimed = true;
      _dialogueMessages = ["ログインボーナス！", "たこ焼きを 1個 ゲットした！", "今日も一日がんばろう！"];
      _currentMessageIndex = 0;
    });

    // Firebaseにたこ焼き数を保存
    await _saveTakoyakiCountToFirebase();

    final prefs = await SharedPreferences.getInstance();
    final String todayKey =
        'takoyakiClaimed_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    await prefs.setBool(todayKey, true);
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

  void _showExpiredRpgMessage(Map<String, dynamic> taskData) {
    _rpgMessageTimer?.cancel();
    _rpgMessageTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _dialogueMessages = ["課題「${taskData['name']}」は期限切れ..."];
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
    print('DEBUG: _createQuest called with selectedClass: $selectedClass');
    print(
      'DEBUG: taskType: $taskType, deadline: $deadline, description: $description',
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('DEBUG: No user found, returning');
      return;
    }

    try {
      final courseId = selectedClass['courseId'];
      print('DEBUG: courseId: $courseId');

      // ★★★ その授業を取っているユーザーを検索して記録 ★★★
      print('DEBUG: Starting to search for enrolled users...');
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<String> enrolledUserIds = [];
      print('DEBUG: Total users in database: ${usersSnapshot.docs.length}');

      for (var userDoc in usersSnapshot.docs) {
        final timetableDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userDoc.id)
                .collection('timetable')
                .doc('notes')
                .get();

        if (timetableDoc.exists) {
          final data = timetableDoc.data()!;
          final userCourseIds = Map<String, String>.from(
            data['courseIds'] ?? {},
          );

          // そのユーザーがこのcourseIdの授業を取っているかチェック
          if (userCourseIds.values.contains(courseId)) {
            enrolledUserIds.add(userDoc.id);
            print('DEBUG: User ${userDoc.id} is enrolled in course $courseId');
          }
        } else {
          print('DEBUG: User ${userDoc.id} has no timetable data');
        }
      }

      // 同じ授業を取っている人に通知を送信
      await _sendNewQuestNotifications(enrolledUserIds, selectedClass);
      print(
        'DEBUG: Found ${enrolledUserIds.length} enrolled users: $enrolledUserIds',
      );

      print('DEBUG: Creating quest document...');
      await FirebaseFirestore.instance.collection('quests').add({
        'name': selectedClass['subjectName'],
        'courseId': courseId, // courseIdを保存
        'taskType': taskType,
        'deadline': Timestamp.fromDate(deadline),
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'completedUserIds': [], // 初期値
        'enrolledUserIds': enrolledUserIds, // ★★★ その授業を取っているユーザーIDを記録 ★★★
      });
      print('DEBUG: Quest document created successfully');

      // クエスト作成後にリストを再読み込み
      print('DEBUG: Reloading quests...');
      await _loadQuestsFromFirestore();
      print('DEBUG: Quests reloaded');
    } catch (e) {
      print('Error creating quest: $e');
      // エラーハンドリング
    }
  }

  void _submitTask(String questId, Map<String, dynamic> taskData) async {
    if (_crackingTasks.contains(questId)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // ユーザーがいない場合は何もしない

    // 期限切れチェック
    final deadline = taskData['deadline'] as Timestamp?;
    final bool isExpired =
        deadline != null && deadline.toDate().isBefore(DateTime.now());

    if (!mounted) return;
    setState(() {
      _crackingTasks.add(questId);
    });

    // 期限切れの場合は特別なメッセージを表示
    if (isExpired) {
      _showExpiredRpgMessage(taskData);
    } else {
      _showRpgMessageAfterCrack(taskData);
    }

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Firestoreのクエストドキュメントに討伐したユーザーIDを追加
    await FirebaseFirestore.instance.collection('quests').doc(questId).set({
      'completedUserIds': FieldValue.arrayUnion([user.uid]),
    }, SetOptions(merge: true));

    setState(() {
      _fadingOutTaskIndex = questId;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // 期限切れの場合は報酬なし
    if (isExpired) {
      setState(() {
        _crackingTasks.remove(questId);
        if (_fadingOutTaskIndex == questId) {
          _fadingOutTaskIndex = null;
        }
        // UI上は即座にリストから削除するが、ドキュメントは残す
        _quests.removeWhere((quest) => quest['id'] == questId);
      });
      return;
    }

    // 新しい報酬システム: 課題提出でたこ焼き2個 + EXP5
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

    // 達成度に応じた報酬をチェック
    await _checkAndDistributeAchievementRewards(questId, taskData);

    // 通知メッセージを表示
    if (rewardTakoyaki > 0) {
      // 作成者の情報を取得
      final creatorDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(taskData['createdBy'] as String?)
              .get();
      final creatorData = creatorDoc.data();
      final creatorCharacter =
          creatorData?['character'] as String? ?? '不明なキャラクター';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_userName}は ${creatorCharacter}に クエスト作成の お礼の たこ焼きを 一個 渡した',
            style: const TextStyle(
              fontFamily: 'NotoSansJP',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 2.5),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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

  // ignore: unused_element
  String _getCharacterImagePath(String characterName) {
    return characterFullDataGlobal[characterName]?['image'] ??
        'assets/character_gorilla.png';
  }

  // Firestoreからクエストデータを読み込む
  Future<void> _loadQuestsFromFirestore() async {
    print('DEBUG: _loadQuestsFromFirestore called');
    setState(() {
      _isLoadingQuests = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: No user found, setting empty quests');
        setState(() {
          _quests = [];
          _isLoadingQuests = false;
        });
        return;
      }

      // ★★★ ユーザーが取っている授業のcourseIdを取得 ★★★
      print('DEBUG: Getting user timetable data...');
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('timetable')
              .doc('notes')
              .get();

      Map<String, String> userCourseIds = {};
      if (userDoc.exists) {
        final data = userDoc.data()!;
        userCourseIds = Map<String, String>.from(data['courseIds'] ?? {});
        print('DEBUG: User courseIds: $userCourseIds');
      } else {
        print('DEBUG: User timetable document does not exist');
      }

      // ユーザーが取っている授業がない場合は空のリストを表示
      if (userCourseIds.isEmpty) {
        print('DEBUG: No user courseIds found, setting empty quests');
        setState(() {
          _quests = [];
          _isLoadingQuests = false;
        });
        return;
      }

      // ★★★ ユーザーが取っている授業のcourseIdのみでクエストをフィルタリング ★★★
      final userCourseIdValues = userCourseIds.values.toSet();
      print('DEBUG: Filtering quests by courseIds: $userCourseIdValues');
      print('DEBUG: User has ${userCourseIdValues.length} courses');

      final snapshot =
          await FirebaseFirestore.instance
              .collection('quests')
              .where('courseId', whereIn: userCourseIdValues.toList())
              // .orderBy('deadline', descending: false) // 一時的にコメントアウト（インデックス作成後に復活）
              .get();

      print('DEBUG: Found ${snapshot.docs.length} quests in Firestore');

      // 各クエストのcourseIdを確認
      for (var doc in snapshot.docs) {
        final questData = doc.data();
        final questCourseId = questData['courseId'] as String?;
        final questName = questData['name'] as String?;
        print('DEBUG: Quest "${questName}" has courseId: $questCourseId');
      }

      if (!mounted) return;

      final quests =
          snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();

      // ★★★ クライアント側でソート（インデックス作成後に削除予定） ★★★
      quests.sort((a, b) {
        final aDeadline = a['deadline'] as Timestamp?;
        final bDeadline = b['deadline'] as Timestamp?;
        if (aDeadline == null && bDeadline == null) return 0;
        if (aDeadline == null) return 1;
        if (bDeadline == null) return -1;
        return aDeadline.compareTo(bDeadline);
      });

      // 自分が既に完了したクエストを分離
      final List<Map<String, dynamic>> completedQuests = [];
      final filteredQuests = quests.where((quest) {
        final completedBy = quest['completedUserIds'] as List<dynamic>?;
        final bool isCompleted = completedBy != null && completedBy.contains(user.uid);
        if (isCompleted) completedQuests.add(quest);
        return !isCompleted;
      }).toList();

      print(
        'DEBUG: After filtering completed quests: ${filteredQuests.length} quests',
      );

      setState(() {
        _quests = filteredQuests;
        _isLoadingQuests = false;
        _completedQuests = completedQuests;
      });
      print('DEBUG: Quests loaded successfully');
      print('DEBUG: _quests list content: $_quests');
      print('DEBUG: _quests length: ${_quests.length}');
      print('DEBUG: _isLoadingQuests: $_isLoadingQuests');
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
                              fontFamily: 'NotoSansJP',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '履修伝説を作成した学生団体\n大学入学を機にプログラミングを始めた阪大一回生三人と\nデザイン担当の阪大二回生で構成されているらしい。。\n\n',
                            style: TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // SNSリンク
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                onTap:
                                    () => launchUrl(
                                      Uri.parse(
                                        'https://www.instagram.com/yuto_cs.js?igsh=MWhkaGE1eDZydTRmeg%3D%3D&utm_source=qr',
                                      ),
                                    ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.pink.withOpacity(0.8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Instagram',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansJP',
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap:
                                    () => launchUrl(
                                      Uri.parse('https://x.com/oz_techjs?s=21'),
                                    ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                  ),
                                  child: const Text(
                                    '公式X',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansJP',
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap:
                                    () => launchUrl(
                                      Uri.parse(
                                        'https://youtube.com/@oz_tech?si=OaUZ2DanKvZ8DN2z',
                                      ),
                                    ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.8),
                                    ),
                                  ),
                                  child: const Text(
                                    'YouTube',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansJP',
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                              fontFamily: 'NotoSansJP',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'アプリ開発サークル\n"ぽちぽちのつどい"はみんなの生活を豊かにするアプリを日夜開発中！\n\n',
                            style: TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          InkWell(
                            onTap:
                                () => launchUrl(
                                  Uri.parse(
                                    'https://x.com/pochipochitudoi?s=21',
                                  ),
                                ),
                            child: const Text(
                              '公式Xはこちら',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'NotoSansJP',
                                fontSize: 16,
                                color: Colors.lightBlueAccent,
                                decoration: TextDecoration.underline,
                              ),
                            ),
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
    // Riverpodから時間割データを取得（新UIでは未使用だが既存依存を維持）
  // ignore: unused_local_variable
  final timetableAsyncValue = ref.watch(timetableProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double topBarHeight = screenHeight * 0.08;
    final double logoSize = screenWidth * 0.13;

    if (ui_flags.useSimpleUI) {
      return _buildSimpleTodoUI(context, screenWidth);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            ref.watch(backgroundImagePathProvider),
            fit: BoxFit.cover,
          ),
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
                          fontFamily: 'NotoSansJP',
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
                          fontFamily: 'NotoSansJP',
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      child: GestureDetector(
                        onTap: () => _showTakoyakiInfoDialog(context), // ここを修正
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
                              fontFamily: 'NotoSansJP',
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
              // 他大学の場合は赤い点を表示
              if (widget.universityType == 'other')
                Positioned(
                  right: 105,
                  top: -5,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              // 他大学の場合は「開発中」ラベルを表示
              if (widget.universityType == 'other')
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Text(
                      '開発中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansJP',
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
                  print('DEBUG: QuestCreationWidget onCreate called');
                  print('DEBUG: selectedClass: $selectedClass');
                  print('DEBUG: taskType: $taskType');
                  print('DEBUG: deadline: $deadline');
                  print('DEBUG: description: $description');

                  // ★★★ _createQuestを呼び出すように変更 ★★★
                  _createQuest(selectedClass, taskType, deadline, description);

                  // 少し遅延させてからsetStateを呼び出す（ダイアログの閉じる処理と競合を避ける）
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() {
                        isQuestCreationVisible = false;
                      });
                    }
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  // ==========================
  // Simple ToDo UI (white/black/blue)
  // ==========================
  Widget _buildSimpleTodoUI(BuildContext context, double screenWidth) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Myタスクのみ（作成者が自分のもの）を表示
    List<Map<String, dynamic>> filtered = _quests;
    if (currentUserId != null) {
      filtered = _quests.where((q) => q['createdBy'] == currentUserId).toList();
    }
    // 未完了（ローカルはcompleted!=true）
    final List<Map<String, dynamic>> mergedActive = [
      ...filtered,
      ..._localTodos.where((e) => e['completed'] != true),
    ];
    // 完了（Firestoreの完了 + ローカルのcompleted==true）
    final List<Map<String, dynamic>> mergedCompleted = [
      ..._completedQuests,
      ..._localTodos.where((e) => e['completed'] == true),
    ];
    // 期日のあるものを昇順、その後ろに期日なしを配置
    int _deadlineCompare(Map<String, dynamic> a, Map<String, dynamic> b) {
      DateTime? ad;
      final av = a['deadline'];
      if (av is Timestamp) {
        ad = av.toDate();
      } else if (av is String && av.isNotEmpty) {
        ad = DateTime.tryParse(av);
      }
      DateTime? bd;
      final bv = b['deadline'];
      if (bv is Timestamp) {
        bd = bv.toDate();
      } else if (bv is String && bv.isNotEmpty) {
        bd = DateTime.tryParse(bv);
      }
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1; // aが期限なし → 後ろへ
      if (bd == null) return -1; // bが期限なし → aが前
      return ad.compareTo(bd);
    }
    mergedActive.sort(_deadlineCompare);
    mergedCompleted.sort(_deadlineCompare);
  // 2分割表示にするため、ここではリストの選択は行わない

    return Stack(
      children: [
        // 背景は白ベース
        Positioned.fill(child: Container(color: _cWhite)),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // iOS風: 半透明+ブラーのトップバーとヘアライン
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      border: const Border(
                        bottom: BorderSide(color: Color(0x1A000000), width: 0.5), // hairline
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _userName.isNotEmpty ? _userName : widget.userName,
                                style: const TextStyle(
                                  color: _cBlack,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'NotoSansJP',
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'ToDo リスト',
                                style: TextStyle(
                                  color: _cBlack,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'NotoSansJP',
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 左端青 -> 右端透明 の太めグラデーションライン（全幅）
                              SizedBox(
                                width: double.infinity,
                                height: 10,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        _cBlue,
                                        _cBlue.withOpacity(0.6),
                                        _cBlue.withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showOztechDialog(context),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset('assets/oztech.png', width: 26, height: 26, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _showPotiPotiDialog(context),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset('assets/potipoti.png', width: 26, height: 26, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // セグメント（未完了/完了）
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _segmentIndex,
                  backgroundColor: Colors.black.withOpacity(0.06),
                  thumbColor: Colors.white,
                  children: const {
                    0: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('未完了', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('完了', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val == null) return;
                    HapticFeedback.lightImpact();
                    setState(() => _segmentIndex = val);
                  },
                ),
              ),

              // 上半分: 未完了 / 下半分: 完了
              Expanded(
                child: _isLoadingQuests
                    ? const Center(child: CircularProgressIndicator())
                    : (_segmentIndex == 0
                        ? ((mergedActive.isEmpty)
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(CupertinoIcons.tray, color: _cBlue, size: 40),
                                    SizedBox(height: 8),
                                    Text('未完了のタスクはありません', style: TextStyle(color: _cBlack, fontFamily: 'NotoSansJP')),
                                  ],
                                ),
                              )
                            : _buildTodoListView(mergedActive, completedView: false))
                        : ((mergedCompleted.isEmpty)
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(CupertinoIcons.checkmark_seal, color: _cBlue, size: 40),
                                    SizedBox(height: 8),
                                    Text('完了したタスクはありません', style: TextStyle(color: _cBlack, fontFamily: 'NotoSansJP')),
                                  ],
                                ),
                              )
                            : _buildTodoListView(mergedCompleted, completedView: true))),
              ),
              const SizedBox(height: 76), // ボトムナビ分の余白
            ],
          ),
        ),

        // 中央下の＋ボタン（既存の追加処理を呼ぶ）
        Positioned(
          left: 0,
          right: 0,
          // 広告+ボトムナビに被らないように十分上に配置（画面高さで調整）
          bottom: (MediaQuery.of(context).size.height <= 720) ? 160 : 210,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160, maxWidth: 240, minHeight: 48),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAddPicker(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cBlue,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('＋ 追加', style: TextStyle(color: _cWhite, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
              ),
            ),
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
                  _createQuest(selectedClass, taskType, deadline, description);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() => isQuestCreationVisible = false);
                    }
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  // タブは廃止（上下2分割表示）

  void _showAddPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.school, color: _cBlue),
                title: const Text('授業に紐づくクエストを作成'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => isQuestCreationVisible = true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add, color: _cBlue),
                title: const Text('メモ（授業外）を作成'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLocalTodoDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocalTodoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? pickedDeadline;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocalState) {
          return AlertDialog(
            title: const Text('新規メモ（授業外）'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    enableSuggestions: true,
                    autocorrect: true,
                    textCapitalization: TextCapitalization.none,
                    style: const TextStyle(
                      fontFamily: 'NotoSansJP',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'タイトル',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: '説明（任意）',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pickedDeadline == null
                              ? '期限: 指定なし'
                              : '期限: ${DateFormat('MM/dd HH:mm').format(pickedDeadline!)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: now,
                            firstDate: now.subtract(const Duration(days: 365)),
                            lastDate: now.add(const Duration(days: 365 * 5)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setLocalState(() {
                                pickedDeadline = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: const Text('期限を選択'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  _addLocalTodo(
                    title: title,
                    description: descController.text.trim(),
                    deadline: pickedDeadline,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('作成'),
              ),
            ],
          );
        });
      },
    );
  }

  void _addLocalTodo({
    required String title,
    String? description,
    DateTime? deadline,
  }) async {
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final todo = {
      'id': id,
      'name': title,
      'description': description ?? '',
      'deadline': deadline?.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': currentUserId,
      'isLocal': true,
    };
    setState(() {
      _localTodos.add(todo);
    });
    await _saveLocalTodos();
  }

  Future<void> _loadLocalTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('localTodos');
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        setState(() {
          _localTodos = list;
        });
      }
    } catch (e) {
      debugPrint('Failed to load local todos: $e');
    }
  }

  Future<void> _saveLocalTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('localTodos', jsonEncode(_localTodos));
    } catch (e) {
      debugPrint('Failed to save local todos: $e');
    }
  }

  // タブUIは廃止

  Widget _buildTodoListView(List<Map<String, dynamic>> items, {bool completedView = false}) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final taskData = items[index];
        final questId = taskData['id'] as String;
        final questName = taskData['name'] as String? ?? '名称未設定';
        final description = taskData['description'] as String? ?? '';
        // FirestoreはTimestamp、ローカルはISO文字列
        DateTime? deadline;
        final deadlineValue = taskData['deadline'];
        if (deadlineValue is Timestamp) {
          deadline = deadlineValue.toDate();
        } else if (deadlineValue is String && deadlineValue.isNotEmpty) {
          deadline = DateTime.tryParse(deadlineValue);
        }
        final bool isLocal = taskData['isLocal'] == true;

        final now = DateTime.now();
        bool isExpired = false;
        bool isDueToday = false;
        if (deadline != null) {
          isExpired = deadline.isBefore(now);
          final d = DateTime(deadline.year, deadline.month, deadline.day);
          final t = DateTime(now.year, now.month, now.day);
          isDueToday = d == t; // その日中が期日
        }
        final String badgeText = _buildRelativeDueText(deadline);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Dismissible(
            key: ValueKey('task-$questId-${completedView ? 'done' : 'active'}'),
            direction: completedView
                ? (isLocal ? DismissDirection.startToEnd : DismissDirection.none)
                : DismissDirection.startToEnd,
            background: Container(
              decoration: BoxDecoration(
                color: completedView ? Colors.orange.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: Icon(
                completedView ? Icons.undo : Icons.check,
                color: completedView ? Colors.orange : Colors.green,
              ),
            ),
            confirmDismiss: (direction) async {
              if (completedView) {
                // 完了一覧: ローカルのみスワイプで未完了へ戻す
                return isLocal;
              } else {
                // 未完了一覧: Firestoreは確認、ローカルは即時
                if (isLocal) return true;
                final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('討伐の確認'),
                        content: const Text('このタスクを完了にしますか？'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('完了')), 
                        ],
                      ),
                    ) ??
                    false;
                return ok;
              }
            },
            onDismissed: (direction) async {
              if (completedView) {
                // ローカル完了 → 未完了に戻す
                if (isLocal) {
                  final idx = _localTodos.indexWhere((e) => e['id'] == questId);
                  if (idx != -1) {
                    setState(() {
                      _localTodos[idx]['completed'] = false;
                    });
                    await _saveLocalTodos();
                  }
                }
              } else {
                if (isLocal) {
                  final idx = _localTodos.indexWhere((e) => e['id'] == questId);
                  if (idx != -1) {
                    setState(() {
                      _localTodos[idx]['completed'] = true;
                    });
                    await _saveLocalTodos();
                  }
                } else {
                  _confirmAndSubmitTask(questId, taskData);
                }
              }
            },
            child: AnimatedContainer(
            decoration: BoxDecoration(
                color: completedView ? _cBlue.withOpacity(0.04) : _cWhite,
                borderRadius: BorderRadius.circular(12),
                // iOS風: 影は基本0、極薄のヘアライン枠
                boxShadow: const [],
                border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
              ),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: InkWell(
                customBorder: const CircleBorder(),
                onTap: completedView
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        if (isLocal) {
                          // まず演出を出してから、短い遅延で完了へ移動（見えやすさ優先）
                          _playCheckPulse(questId);
                          Future.delayed(const Duration(milliseconds: 380), () {
                            if (!mounted) return;
                            setState(() {
                              final idx = _localTodos.indexWhere((e) => e['id'] == questId);
                              if (idx != -1) {
                                _localTodos[idx]['completed'] = true;
                              }
                            });
                            _saveLocalTodos();
                          });
                        } else {
                          // Firestoreは確認の上で完了にする。演出は先に出す。
                          _playCheckPulse(questId);
                          _confirmAndSubmitTask(questId, taskData);
                        }
                      },
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        tween: Tween(begin: 0, end: completedView ? 1 : 0),
                        builder: (context, t, child) {
                          final bool checked = completedView;
                          return Icon(
                            checked ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                            color: checked ? _cBlue : _cBlack,
                            size: 22,
                          );
                        },
                      ),
                      // 完了演出: 小さな粒が四方に弾けるバースト
                      if (_pulsingChecks.contains(questId))
                        TweenAnimationBuilder<double>(
                          key: ValueKey('burst-$questId'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, _) {
                            final int particleCount = 10;
                            final double maxR = 14.0; // 半径
                            final double r = maxR * t;
                            final double opacity = (1 - t).clamp(0.0, 1.0);
                            return Opacity(
                              opacity: opacity,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: List.generate(particleCount, (i) {
                                  final double angle = (2 * math.pi / particleCount) * i;
                                  final double dx = math.cos(angle) * r;
                                  final double dy = math.sin(angle) * r;
                                  return Transform.translate(
                                    offset: Offset(dx, dy),
                                    child: Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: _cBlue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      if (_pulsingChecks.contains(questId))
                        TweenAnimationBuilder<double>(
                          key: ValueKey('pulse-$questId'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 450),
                          onEnd: () {
                            if (mounted) {
                              setState(() {
                                _pulsingChecks.remove(questId);
                              });
                            }
                          },
                          builder: (context, t, _) {
                            final double size = 22 + 12 * t; // 22→34
                            final double opacity = (1 - t).clamp(0.0, 1.0);
                            return Opacity(
                              opacity: opacity,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _cBlue.withOpacity(opacity),
                                    width: 2 - 1.2 * t, // 2→0.8
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      questName,
                      style: TextStyle(
                        color: (isExpired && !completedView) ? Colors.red : _cBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 期日バッジ
                  if (deadline != null)
                    Semantics(
                      // アクセシビリティ読み上げ
                      label: (isExpired
                              ? '期日 $badgeText, 期限切れ'
                              : (isDueToday ? '期日 $badgeText, 今日中'
                                            : '期日 $badgeText')),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpired
                                  ? Icons.warning_amber_rounded
                                  : Icons.schedule,
                              size: 14,
                              color: (isDueToday || isExpired) ? Colors.red : _cBlack,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              badgeText,
                              style: TextStyle(
                                  color: (isDueToday || isExpired) ? Colors.red : _cBlack,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  description.isNotEmpty ? description : (taskData['taskType']?.toString() ?? ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _cBlack, fontSize: 13),
                ),
              ),
              trailing: (completedView && isLocal)
                  // 完了一覧のローカル項目限定で「未完了へ戻す」
                  ? IconButton(
                      tooltip: '未完了へ戻す',
                      icon: const Icon(CupertinoIcons.arrow_uturn_left, size: 20, color: _cBlue),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        final idx = _localTodos.indexWhere((e) => e['id'] == questId);
                        if (idx != -1) {
                          setState(() {
                            _localTodos[idx]['completed'] = false;
                          });
                          _saveLocalTodos();
                        }
                      },
                    )
                  : (!isLocal && !completedView)
                      ? FutureBuilder<bool>(
                          future: _isCurrentUserSupporting(questId),
                          builder: (context, snapshot) {
                            final bool isSupporting = snapshot.data ?? false;
                            return IconButton(
                              icon: Icon(isSupporting ? CupertinoIcons.star_fill : CupertinoIcons.star, color: _cBlue),
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                await _toggleTakoyakiSupport(
                                  questId,
                                  taskData['createdBy'] as String?,
                                  taskData,
                                );
                                await _refreshQuests();
                                if (mounted) setState(() {});
                              },
                            );
                          },
                        )
                      : null,
              onTap: () {
                if (completedView) return;
                if (isLocal) return; // ローカルは詳細画面なし
                _confirmAndSubmitTask(questId, taskData);
              },
              onLongPress: () {
                // 完了一覧のローカル項目は長押しでも未完了へ戻せる
                if (completedView && isLocal) {
                  final idx = _localTodos.indexWhere((e) => e['id'] == questId);
                  if (idx != -1) {
                    setState(() {
                      _localTodos[idx]['completed'] = false;
                    });
                    _saveLocalTodos();
                  }
                }
              },
            ),
            ),
          ),
        );
      },
    );
  }

  String _buildRelativeDueText(DateTime? deadline) {
    if (deadline == null) return '期限なし';
    final now = DateTime.now();
    final d = DateTime(deadline.year, deadline.month, deadline.day);
    final t = DateTime(now.year, now.month, now.day);
    // 今日なら時刻のみ、それ以外は日付+時刻
    if (d == t) {
      return DateFormat('HH:mm').format(deadline);
    } else {
      return DateFormat('MM/dd HH:mm').format(deadline);
    }
  }

  Future<void> _confirmAndSubmitTask(String questId, Map<String, dynamic> taskData) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('討伐の確認'),
          content: const Text('本当に討伐しますか？\n（間違って押した場合は「いいえ」でキャンセルできます）'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('いいえ')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('はい')),
          ],
        );
      },
    );
    if (result == true) {
      _submitTask(questId, taskData);
    }
  }

  Widget _buildBulletinBoardPage(Map<String, dynamic> taskData) {
    print('DEBUG: _buildBulletinBoardPage called with taskData: $taskData');
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final questId = taskData['id'] as String;
    final isCracking = _crackingTasks.contains(questId);
    final isFadingOut = _fadingOutTaskIndex == questId;

    final deadline = taskData['deadline'] as Timestamp?;
  // ignore: unused_local_variable
  final bool isExpired =
        deadline != null && deadline.toDate().isBefore(DateTime.now());
    final textColor = const Color(0xFF00FFF7); // 蛍光水色
    final detailTextColor = const Color(0xFF00FFF7); // 蛍光水色
    final deadlineText =
        deadline != null
            ? DateFormat('MM/dd HH:mm').format(deadline.toDate())
            : '期限なし';
    final questName = taskData['name'] as String? ?? '名称未設定';
    final description = taskData['description'] as String? ?? '';
    final taskType = taskData['taskType'] as String? ?? '課題';
    final creatorId = taskData['createdBy'] as String?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return AnimatedOpacity(
      opacity: isFadingOut ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 500),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: screenHeight * 0.13,
            left: screenWidth * 0.04,
            child: FutureBuilder<String>(
              future: _getCreatorCharacterImage(
                taskData['createdBy'] as String?,
              ),
              builder: (context, snapshot) {
                Widget imageWidget;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  imageWidget = const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  imageWidget = Image.asset(
                    'assets/character_gorilla.png',
                    fit: BoxFit.cover,
                  );
                } else {
                  imageWidget = Image.asset(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/character_gorilla.png',
                        fit: BoxFit.cover,
                      );
                    },
                  );
                }
                final creatorIconSize = screenWidth * 0.14;
                return Container(
                  width: creatorIconSize,
                  height: creatorIconSize,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.cyan.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: imageWidget,
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/countdown.png', fit: BoxFit.contain),
            ),
          ),
          if (isCracking)
            Positioned.fill(
              child: Opacity(
                opacity: 0.7,
                child: Image.asset(
                  'assets/crack_overlay.png',
                  fit: BoxFit.contain,
                ),
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
                    questName.length > 12
                        ? '${questName.substring(0, 12)}...'
                        : questName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenHeight * 0.025,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'NotoSansJP',
                      shadows: [
                        BoxShadow(
                          color: textColor.withOpacity(0.7),
                          blurRadius: 6,
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
                        "課題: $taskType\n詳細: $description\n期限: $deadlineText",
                        style: TextStyle(
                          fontSize: screenHeight * 0.020,
                          color: detailTextColor,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              color: detailTextColor.withOpacity(0.5),
                              blurRadius: 4,
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
          Positioned(
            top: screenHeight * 0.363,
            left: screenWidth * 0.08,
            width: screenWidth * 0.22,
            height: screenHeight * 0.035,
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
                  return const SizedBox.shrink();
                }
                final counts = snapshot.data!;
                return TaskProgressGauge(
                  defeatedCount: counts['completed'] ?? 0,
                  totalParticipants: counts['total'] ?? 0,
                );
              },
            ),
          ),
          Positioned(
            top: screenHeight * 0.218,
            right: screenWidth * 0.13,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                minimumSize: Size(screenWidth * 0.06, screenHeight * 0.035),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.6),
              ),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('討伐の確認'),
                      content: const Text(
                        '本当に討伐しますか？\n（間違って押した場合は「いいえ」でキャンセルできます）',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('いいえ'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('はい'),
                        ),
                      ],
                    );
                  },
                );
                if (result == true) {
                  _submitTask(questId, taskData);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/buttons/common_navigation/park_active.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '討伐',
                    style: TextStyle(
                      color: Color(0xFF00FFF7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (creatorId == currentUserId)
            Positioned(
              top: screenHeight * 0.14,
              right: screenWidth * 0.05,
              child: IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF00FFF7), size: 20),
                onPressed: () {
                  _showEditQuestDialog(context, taskData);
                },
              ),
            ),
          Positioned(
            top: screenHeight * 0.33,
            right: screenWidth * 0.13,
            child: InkWell(
              onTap:
                  () => _toggleTakoyakiSupport(
                    questId,
                    taskData['createdBy'] as String?,
                    taskData,
                  ),
              borderRadius: BorderRadius.circular(screenWidth * 0.08),
              child: Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                child: Center(
                  child: FutureBuilder<bool>(
                    future: _isCurrentUserSupporting(questId),
                    builder: (context, snapshot) {
                      final bool isSupporting = snapshot.data ?? false;
                      return Container(
                        width: screenWidth * 0.12,
                        height: screenWidth * 0.12,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              isSupporting
                                  ? 'assets/takoyaki.png'
                                  : 'assets/takoyaki_off.png',
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownText(Map<String, dynamic> taskData) {
    final deadline = taskData['deadline'] as Timestamp?;

    if (deadline == null) {
      return const Text(
        '期限なし',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    return _CountdownWidget(deadline: deadline.toDate());
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
                    fontFamily: 'NotoSansJP',
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

  // ignore: unused_element
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
  Future<String> _getCreatorCharacterImage(String? userId) async {
    if (userId == null) {
      return 'assets/character_gorilla.png'; // デフォルト画像
    }
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (userDoc.exists) {
        return (userDoc.data()?['characterImage'] as String?) ??
            'assets/character_gorilla.png';
      }
      return 'assets/character_gorilla.png';
    } catch (e) {
      print('Error getting creator character image: $e');
      return 'assets/character_gorilla.png';
    }
  }

  // ★★★ この2つのメソッドを新しく追加 ★★★
  Future<bool> _isCurrentUserSupporting(String questId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final questDoc =
          await FirebaseFirestore.instance
              .collection('quests')
              .doc(questId)
              .get();
      final supporters = (questDoc.data()?['supporterIds'] as List?) ?? [];
      return supporters.contains(user.uid);
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleTakoyakiSupport(
    String questId,
    String? creatorId,
    Map<String, dynamic> taskData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || creatorId == null) return;
    if (user.uid == creatorId) {
      // 自分自身には贈れない
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('自分の クエストに たこ焼きは 贈れません！')));
      return;
    }

    final bool isCurrentlySupporting = await _isCurrentUserSupporting(questId);
    final int takoyakiChange = isCurrentlySupporting ? -1 : 1;

    // 自分のたこ焼きが足りるかチェック（削除：自分のたこ焼きは減らないため不要）
    // if (takoyakiChange > 0 && _takoyakiCount < 1) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text('たこ焼きが 足りません！')));
    //   return;
    // }

    final questRef = FirebaseFirestore.instance
        .collection('quests')
        .doc(questId);
    final creatorRef = FirebaseFirestore.instance
        .collection('users')
        .doc(creatorId);
    // final selfRef = FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. クエストの応援者リストを更新
        transaction.update(questRef, {
          'supporterIds':
              isCurrentlySupporting
                  ? FieldValue.arrayRemove([user.uid])
                  : FieldValue.arrayUnion([user.uid]),
        });

        // 2. 作成者のたこ焼きを増減
        transaction.update(creatorRef, {
          'takoyakiCount': FieldValue.increment(takoyakiChange),
        });

        // 3. 自分のたこ焼きを増減（削除：自分のたこ焼きは減らない）
        // transaction.update(selfRef, {
        //   'takoyakiCount': FieldValue.increment(-takoyakiChange),
        // });
      });

      // 作成者向けの通知データを保存
      if (takoyakiChange > 0) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(creatorId)
            .collection('notifications')
            .add({
              'type': 'takoyaki_received',
              'message': '神が あなたの 作った クエストに たこ焼きを 送りました',
              'questId': questId,
              'questName': taskData['name'] ?? 'クエスト',
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(creatorId)
            .collection('notifications')
            .add({
              'type': 'takoyaki_returned',
              'message': '神が あなたの 作った クエストから たこ焼きを 取り戻しました',
              'questId': questId,
              'questName': taskData['name'] ?? 'クエスト',
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
      }

      // 通知メッセージを表示
      if (takoyakiChange > 0) {
        // 作成者の情報を取得
        final creatorDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(creatorId)
                .get();
        final creatorData = creatorDoc.data();
        final creatorCharacter =
            creatorData?['character'] as String? ?? '不明なキャラクター';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_userName}は ${creatorCharacter}に クエスト作成の お礼の たこ焼きを 一個 渡した',
              style: const TextStyle(
                fontFamily: 'NotoSansJP',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 2.5),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // 作成者にたこ焼き受信通知を送信（Cloud Functions経由のプッシュ通知）
        await FirebaseFirestore.instance
            .collection('users')
            .doc(creatorId)
            .collection('notifications')
            .add({
              'type': 'takoyaki_received',
              'senderId': FirebaseAuth.instance.currentUser?.uid,
              'reason': 'クエスト作成のお礼',
              'questId': questId,
              'questName': taskData['name'] ?? 'クエスト',
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
      } else {
        // 作成者の情報を取得
        final creatorDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(creatorId)
                .get();
        final creatorData = creatorDoc.data();
        final creatorCharacter =
            creatorData?['character'] as String? ?? '不明なキャラクター';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_userName}は ${creatorCharacter}から たこ焼きを 一個 取り戻した',
              style: const TextStyle(
                fontFamily: 'NotoSansJP',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 2.5),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // UIを強制的に更新してたこ焼きボタンの状態を切り替える
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error toggling takoyaki support: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('処理に 失敗しました。')));
    }

    // 達成度に応じた報酬をチェック
    await _checkAndDistributeAchievementRewards(questId, taskData);
  }

  // ★★★ ここまで ★★★

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
      final enrolledUserIds =
          (questData?['enrolledUserIds'] as List?)?.length ?? 0;

      return {'completed': completedUserIds, 'total': enrolledUserIds};
    } catch (e) {
      print('Error getting subjugation info: $e');
      return {'completed': 0, 'total': 0};
    }
  }

  void _showEditQuestDialog(
    BuildContext context,
    Map<String, dynamic> taskData,
  ) {
    final questId = taskData['id'] as String;
    String editedTaskType = taskData['taskType'] as String;
    String editedDescription = taskData['description'] as String;
    DateTime editedDeadline = (taskData['deadline'] as Timestamp).toDate();
    final List<String> taskTypes = ['レポート', '出席', '発表', '試験', 'その他'];

    final descriptionController = TextEditingController(
      text: editedDescription,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('クエストを編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: editedTaskType,
                      items:
                          taskTypes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() {
                          editedTaskType = newValue!;
                        });
                      },
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: '詳細'),
                      onChanged: (value) => editedDescription = value,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '期限: ${DateFormat('MM/dd HH:mm').format(editedDeadline)}',
                    ),
                    ElevatedButton(
                      child: Text('期限を変更'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: editedDeadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date == null) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(editedDeadline),
                        );
                        if (time == null) return;
                        setDialogState(() {
                          editedDeadline = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('キャンセル'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('保存'),
                  onPressed: () {
                    _updateQuest(questId, {
                      'taskType': editedTaskType,
                      'description': editedDescription,
                      'deadline': Timestamp.fromDate(editedDeadline),
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateQuest(String questId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('quests')
          .doc(questId)
          .update(data);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("クエストを 更新しました！")));
      }
    } catch (e) {
      print("Error updating quest: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("クエストの 更新に 失敗しました...")));
      }
    }
  }

  // 達成度に応じた報酬をチェック
  Future<void> _checkAndDistributeAchievementRewards(
    String questId,
    Map<String, dynamic> taskData,
  ) async {
    try {
      final questDoc =
          await FirebaseFirestore.instance
              .collection('quests')
              .doc(questId)
              .get();

      if (!questDoc.exists) return;

      final questData = questDoc.data()!;
      final completedUserIds = List<String>.from(
        questData['completedUserIds'] ?? [],
      );
      final enrolledUserIds = List<String>.from(
        questData['enrolledUserIds'] ?? [],
      );
      final creatorId = questData['createdBy'] as String?;

      if (creatorId == null || enrolledUserIds.isEmpty) return;

      final completionRate = completedUserIds.length / enrolledUserIds.length;
      final isHalfCompleted = completionRate >= 0.5 && completionRate < 1.0;
      final isFullyCompleted = completionRate >= 1.0;

      // 既に報酬が配布済みかチェック
      final alreadyRewarded =
          questData['achievementRewardsDistributed'] ?? false;
      if (alreadyRewarded) return;

      if (isHalfCompleted) {
        // 半数達成: 作成者に2個、全員に1個
        await _distributeHalfCompletionRewards(
          questId,
          creatorId,
          enrolledUserIds,
        );
      } else if (isFullyCompleted) {
        // 全員達成: 作成者に10個、全員に5個
        await _distributeFullCompletionRewards(
          questId,
          creatorId,
          enrolledUserIds,
        );
      }
    } catch (e) {
      print('Error checking achievement rewards: $e');
    }
  }

  // 半数達成時の報酬配布
  Future<void> _distributeHalfCompletionRewards(
    String questId,
    String creatorId,
    List<String> enrolledUserIds,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 作成者に2個
        final creatorRef = FirebaseFirestore.instance
            .collection('users')
            .doc(creatorId);
        transaction.update(creatorRef, {
          'takoyakiCount': FieldValue.increment(2),
        });

        // 全員に1個
        for (final userId in enrolledUserIds) {
          final userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userId);
          transaction.update(userRef, {
            'takoyakiCount': FieldValue.increment(1),
          });
        }

        // 報酬配布済みフラグを設定
        final questRef = FirebaseFirestore.instance
            .collection('quests')
            .doc(questId);
        transaction.update(questRef, {
          'achievementRewardsDistributed': true,
          'achievementType': 'half',
        });
      });

      // クエスト情報を取得
      final questDoc =
          await FirebaseFirestore.instance
              .collection('quests')
              .doc(questId)
              .get();
      final questData = questDoc.data() ?? {};
      final subjectName =
          questData['subjectName'] ?? questData['name'] ?? '授業名不明';
      final taskType = questData['taskType'] ?? '課題';

      // 自分が対象者の場合、UIを更新
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && enrolledUserIds.contains(currentUser.uid)) {
        setState(() {
          _takoyakiCount += 1;
        });
        await _saveTakoyakiCountToFirebase();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '「$subjectName」の「$taskType」が半数達成！全員にたこ焼き1個、作成者に2個配布されました！',
              style: TextStyle(fontFamily: 'NotoSansJP', color: Colors.white),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white, width: 2.5),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error distributing half completion rewards: $e');
    }
  }

  // 全員達成時の報酬配布
  Future<void> _distributeFullCompletionRewards(
    String questId,
    String creatorId,
    List<String> enrolledUserIds,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 作成者に10個
        final creatorRef = FirebaseFirestore.instance
            .collection('users')
            .doc(creatorId);
        transaction.update(creatorRef, {
          'takoyakiCount': FieldValue.increment(10),
        });

        // 全員に5個
        for (final userId in enrolledUserIds) {
          final userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userId);
          transaction.update(userRef, {
            'takoyakiCount': FieldValue.increment(5),
          });
        }

        // 報酬配布済みフラグを設定
        final questRef = FirebaseFirestore.instance
            .collection('quests')
            .doc(questId);
        transaction.update(questRef, {
          'achievementRewardsDistributed': true,
          'achievementType': 'full',
        });
      });

      // クエスト情報を取得
      final questDoc =
          await FirebaseFirestore.instance
              .collection('quests')
              .doc(questId)
              .get();
      final questData = questDoc.data() ?? {};
      final subjectName =
          questData['subjectName'] ?? questData['name'] ?? '授業名不明';
      final taskType = questData['taskType'] ?? '課題';

      // 自分が対象者の場合、UIを更新
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && enrolledUserIds.contains(currentUser.uid)) {
        setState(() {
          _takoyakiCount += 5;
        });
        await _saveTakoyakiCountToFirebase();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '「$subjectName」の「$taskType」が全員達成！全員にたこ焼き5個、作成者に10個配布されました！',
              style: TextStyle(fontFamily: 'NotoSansJP', color: Colors.white),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white, width: 2.5),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error distributing full completion rewards: $e');
    }
  }

  // ★ たこ焼きの増やし方・使い方ダイアログ表示メソッドを追加
  void _showTakoyakiInfoDialog(BuildContext context) {
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
                            'たこ焼きの増やし方・使い方',
                            style: TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '【たこ焼きの増やし方】',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '・ログインボーナス',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '・クエスト討伐',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '・クエスト作成',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '・クエストへのいいね',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '・単位レビュー投稿',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '【たこ焼きの使い方】',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '・レビュー閲覧',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '・アイテム購入（ver2.0で実装！）',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansJP',
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
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

  // 同じ授業を取っている人に新しいクエスト通知を送信
  Future<void> _sendNewQuestNotifications(
    List<String> enrolledUserIds,
    dynamic selectedClass,
  ) async {
    try {
      final courseName = selectedClass['subjectName'] ?? '授業名不明';
      final questName = selectedClass['subjectName'] ?? 'クエスト';
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      for (String userId in enrolledUserIds) {
        // 自分以外のユーザーに通知を送信
        if (userId != currentUserId) {
          await NotificationService().showNewQuestNotification(
            creatorName: _userName,
            questName: questName,
            courseName: courseName,
          );
        }
      }
    } catch (e) {
      print('Error sending new quest notifications: $e');
    }
  }
}

class _CountdownWidget extends StatefulWidget {
  final DateTime deadline;

  const _CountdownWidget({Key? key, required this.deadline}) : super(key: key);

  @override
  _CountdownWidgetState createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final remaining =
        widget.deadline.isAfter(now)
            ? widget.deadline.difference(now)
            : Duration.zero;

    if (mounted) {
      setState(() {
        _remaining = remaining;
      });

      if (_remaining.inMinutes < 30 && _remaining.inSeconds > 0) {
        if (_animationController == null) {
          _animationController = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 500),
          )..repeat(reverse: true);
        }
      } else {
        _animationController?.dispose();
        _animationController = null;
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (_remaining.isNegative || _remaining.inSeconds == 0) {
      return Text(
        "討伐失敗",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: screenHeight * 0.035,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
          fontFamily: 'display_free_tfb',
          shadows: [
            Shadow(
              color: Colors.redAccent.withOpacity(0.8),
              blurRadius: 8,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    // デフォルトは水色
    Color numberColor = const Color(0xFF00FFF7);
    Color labelColor = Colors.white;
    bool blink = false;

    if (_remaining.inMinutes < 60) {
      // 1時間未満で赤文字、30分未満で点滅
      numberColor = Colors.redAccent;
      labelColor = Colors.redAccent;
      if (_remaining.inMinutes < 30) {
        blink = true;
      }
    }

    Widget textWidget = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: screenHeight * 0.035,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
            text: days.toString(),
            style: TextStyle(
              color: numberColor,
              shadows: [
                Shadow(color: numberColor.withOpacity(0.9), blurRadius: 24),
                Shadow(color: numberColor.withOpacity(0.7), blurRadius: 12),
                Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
          TextSpan(
            text: 'd',
            style: TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: screenHeight * 0.02,
              color: labelColor,
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(
            text: hours.toString().padLeft(2, '0'),
            style: TextStyle(
              color: numberColor,
              shadows: [
                Shadow(color: numberColor.withOpacity(0.9), blurRadius: 24),
                Shadow(color: numberColor.withOpacity(0.7), blurRadius: 12),
                Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
          TextSpan(
            text: 'h',
            style: TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: screenHeight * 0.02,
              color: labelColor,
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(
            text: minutes.toString().padLeft(2, '0'),
            style: TextStyle(
              color: numberColor,
              shadows: [
                Shadow(color: numberColor.withOpacity(0.9), blurRadius: 24),
                Shadow(color: numberColor.withOpacity(0.7), blurRadius: 12),
                Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
          TextSpan(
            text: 'm',
            style: TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: screenHeight * 0.02,
              color: labelColor,
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(
            text: seconds.toString().padLeft(2, '0'),
            style: TextStyle(
              color: numberColor,
              shadows: [
                Shadow(color: numberColor.withOpacity(0.9), blurRadius: 24),
                Shadow(color: numberColor.withOpacity(0.7), blurRadius: 12),
                Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
          TextSpan(
            text: 's',
            style: TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: screenHeight * 0.02,
              color: labelColor,
            ),
          ),
        ],
      ),
    );

    if (blink && _animationController != null) {
      return FadeTransition(opacity: _animationController!, child: textWidget);
    }
    return textWidget;
  }
}
