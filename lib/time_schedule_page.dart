import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
// import 'package:provider/provider.dart'; // Riverpodを使用しているので、これはおそらく不要。もしエラーが出たら削除を検討
import 'package:flutter_riverpod/flutter_riverpod.dart';
<<<<<<< HEAD
import 'package:flutter/services.dart';
import 'dart:io';

=======
import 'package:firebase_messaging/firebase_messaging.dart';
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 共通フッターと遷移先ページのインポート
import 'common_bottom_navigation.dart';
import 'park_page.dart';
import 'credit_review_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'timetable_entry.dart';
import 'timetable.dart';
import 'utils/course_pattern_detector.dart';
import 'utils/course_color_generator.dart';
import 'course_pattern.dart';
import 'providers/timetable_provider.dart';
import 'providers/current_page_provider.dart';
import 'providers/global_course_mapping_provider.dart';
import 'providers/global_review_mapping_provider.dart';
import 'level_gauge.dart';
import 'task_progress_gauge.dart';

// main.dartで定義された handleAttendanceAction をインポート
import '../main.dart' show handleAttendanceAction;

enum AttendanceStatus { present, absent, late, none }

class TimeSchedulePage extends ConsumerStatefulWidget {
  const TimeSchedulePage({super.key});
  @override
  ConsumerState<TimeSchedulePage> createState() => _TimeSchedulePageState();
}

class _TimeSchedulePageState extends ConsumerState<TimeSchedulePage> {
  late PageController _pageController;
  static const int _initialPage = 5000; // 無限スクロールのための開始ページ

  // main.dart からインポートしたグローバル関数を呼び出すためのラッパー
  Future<void> _handleAttendanceAction(String actionId, String classId) async {
    await _handleAttendanceAction(actionId, classId);
  }

  final List<String> _days = const ['月', '火', '水', '木', '金', '土', '日'];
  final int _academicPeriods = 6;
  String _mainCharacterName = 'キャラクター';
  String _mainCharacterImagePath = 'assets/character_unknown.png';
  List<List<TimetableEntry?>> _timetableGrid = [];
  Set<String> _cancellations = {};
  List<Map<String, String>> _displayedCharacters = [];
  final List<String> _otherCharacterImagePaths = [
    'assets/character_wizard.png',
    'assets/character_merchant.png',
    'assets/character_gorilla.png',
    'assets/character_swordman.png',
    'assets/character_takuji.png',
    'assets/character_god.png',
    'assets/character_adventurer.png',
  ];
  final double _periodRowHeight = 70.0;
  final double _lunchRowHeight = 70.0;
  final List<List<String>> _periodTimes = const [
    ["8:50", "10:20"],
    ["10:30", "12:00"],
    ["13:30", "15:00"],
    ["15:10", "16:40"],
    ["16:50", "18:20"],
    ["18:30", "20:00"],
  ];
  Timer? _highlightTimer;
  late DateTime _displayedMonday;
  List<String> _dayDates = [];
  String _weekDateRange = "";
  List<Map<String, dynamic>> _sundayEvents = [];
  Map<int, List<Map<String, dynamic>>> _weekdayEvents = {};
  double _timeGaugeProgress = 0.0;
  Map<String, Color> _courseColors = {};

  final List<Color> _neonColors = [
    const Color(0xFF00E5FF), // cyanAccent
    const Color(0xFF69F0AE), // greenAccent[400]
    const Color(0xFFFFFF00), // yellowAccent
    const Color(0xFFE1BEE7), // purpleAccent[100]
    const Color(0xFFFFFFFF), // white
    const Color(0xFF40C4FF), // lightBlueAccent
    const Color(0xFF76FF03), // limeAccent[400]
  ];

  // ★★★ courseIdをTimetableProviderから取得するメソッド
  Map<String, String> get courseIds =>
      ref.watch(timetableProvider.select((data) => data['courseIds'] as Map<String, String>?)) ?? {};

  // ★★★ courseIdをTimetableProviderに保存するメソッド
  void _updateCourseIds(Map<String, String> courseIds) {
    ref.read(timetableProvider.notifier).updateCourseIds(courseIds);
  }

  // データの取得メソッド（UIは変更しない）
  Map<String, String> get cellNotes =>
      ref.watch(timetableProvider.select((data) => data['cellNotes'] as Map<String, String>?)) ?? {};
  Map<String, String> get weeklyNotes =>
      ref.watch(timetableProvider.select((data) => data['weeklyNotes'] as Map<String, String>?)) ?? {};
  Map<String, String> get attendancePolicies =>
      ref.watch(timetableProvider.select((data) => data['attendancePolicies'] as Map<String, String>?)) ?? {};
  Map<String, Map<String, String>> get attendanceStatus =>
      ref.watch(timetableProvider.select((data) => data['attendanceStatus'] as Map<String, Map<String, String>>?)) ?? {};
  
  // absenceCount と lateCount は main.dart の _handleAttendanceAction が更新し、
  // _listenToAttendanceCounts が購読して Riverpodのプロバイダを更新するので、ref.watch で取得
  Map<String, int> get absenceCount =>
      ref.watch(timetableProvider.select((data) => data['absenceCount'] as Map<String, int>?)) ?? {};
  Map<String, int> get lateCount =>
      ref.watch(timetableProvider.select((data) => data['lateCount'] as Map<String, int>?)) ?? {};

  // データの更新メソッド（UIは変更しない）
  void _updateCellNotes(Map<String, String> notes) {
    ref.read(timetableProvider.notifier).updateCellNotes(notes);
  }

  void _updateWeeklyNotes(Map<String, String> notes) {
    ref.read(timetableProvider.notifier).updateWeeklyNotes(notes);
  }

  void _updateAttendancePolicies(Map<String, String> policies) {
    ref.read(timetableProvider.notifier).updateAttendancePolicies(policies);
  }

  void _updateAttendanceStatus(Map<String, Map<String, String>> status) {
    ref.read(timetableProvider.notifier).updateAttendanceStatus(status);
  }

  void _updateAbsenceCount(Map<String, int> count) {
    ref.read(timetableProvider.notifier).updateAbsenceCount(count);
  }

  void _updateLateCount(Map<String, int> count) {
    ref.read(timetableProvider.notifier).updateLateCount(count);
  }

  // 教員名を更新
  void _updateTeacherNames(Map<String, String> teacherNames) {
    ref.read(timetableProvider.notifier).updateTeacherNames(teacherNames);
  }

  // 教員名を取得
  Map<String, String> get teacherNames =>
      ref.watch(timetableProvider.select((data) => data['teacherNames'] as Map<String, String>?)) ?? {};

  // 時間割データを読み込み
  void _loadTimetableData() {
    print('Loading timetable data from Firebase...');
    ref.read(timetableProvider.notifier).loadFromFirestore();

    // ★★★ 保存されたcourseIdを読み込んで復元 ★★★
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedCourseIds = courseIds; // Riverpodから取得
      if (savedCourseIds.isNotEmpty) {
        // globalCourseMappingProviderにも復元（正規化された授業名で）
        final globalMappingNotifier = ref.read(
          globalCourseMappingProvider.notifier,
        );
        for (var entry in savedCourseIds.entries) {
          // 古い形式のデータの場合は、後方互換性のために古いAPIを使用
          final normalizedName = globalMappingNotifier.normalizeSubjectName(
            entry.key,
          );
          // 古い形式のaddCourseMappingを使用（後方互換性のため）
          // 新しい形式では、授業名・教室・曜日・時限が必要だが、
          // 保存されたデータには教室・曜日・時限の情報がないため、
          // 古いAPIを使用して復元する
          globalMappingNotifier.addCourseMappingBySubjectName(
            normalizedName,
            entry.value,
          );
        }

        print('DEBUG: 保存されたcourseIdを復元しました: $savedCourseIds');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _loadTimetableData();
    _updateHighlight();
    _highlightTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateHighlight();
      }
    });
    // ★追加: FCMの初期化とデバイストークンの取得・保存を開始
    _initializeFCM();
    // ★追加: 出欠カウントのリアルタイム更新を購読開始
    _listenToAttendanceCounts();
  }

  bool _isInitialWeekLoaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialWeekLoaded) {
      _changeWeek(_initialPage);
      _isInitialWeekLoaded = true;
    }
    _fetchCharacterInfoFromFirebase();
    // ホットリロード時にもデータを再読み込み
    // _loadTimetableData(); // initStateで既に呼ばれているので重複を避ける
  }

  Future<void> _fetchCharacterInfoFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _mainCharacterName = data['character'] ?? '剣士';
            _mainCharacterImagePath =
                data['characterImage'] ?? 'assets/character_swordman.png';
          });
        }
      }
    } catch (e) {
      print('Error fetching character info: $e');
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ★週を変更するためのメソッド
  void _changeWeek(int page) {
    setState(() {
      final weekOffset = page - _initialPage;
      final today = DateTime.now();
      _displayedMonday = today
          .subtract(Duration(days: today.weekday - 1))
          .add(Duration(days: weekOffset * 7));
      _initializeTimetableGrid(_displayedMonday);
      _updateWeekDates();
    });
  }

  Future<void> _initializeTimetableGrid(DateTime weekStart) async {
    List<TimetableEntry> timeTableEntries = await getWeeklyTimetableEntries(
      weekStart,
    );

    // ★★★ 保存されたcourseIdを優先的に使用 ★★★
    Map<String, String> courseIdMap = {};
    final savedCourseIds = courseIds; // Riverpodから取得

    for (var entry in timeTableEntries) {
      String courseId;

      // 保存されたcourseIdがある場合はそれを使用
      if (savedCourseIds.containsKey(entry.subjectName)) {
        courseId = savedCourseIds[entry.subjectName]!;
        print('DEBUG: 保存されたcourseIdを使用: ${entry.subjectName} -> $courseId');
      } else {
        // 保存されていない場合は新しく生成（授業名・教室・曜日・時限を使用）
        courseId = ref
            .read(globalCourseMappingProvider.notifier)
            .getOrCreateCourseId(
              entry.subjectName,
              entry.classroom,
              entry.dayOfWeek,
              entry.period,
            );
        print(
          'DEBUG: 新しいcourseIdを生成: ${entry.subjectName} (${entry.classroom}, 曜日:${entry.dayOfWeek}, 時限:${entry.period}) -> $courseId',
        );
      }

      entry.courseId = courseId;
      courseIdMap[entry.subjectName] = courseId;
    }

    // ★★★ courseIdをTimetableProviderに保存 ★★★
    _updateCourseIds(courseIdMap);

    // ★★★ Firestoreのusers/{uid}/timetable/entriesにもcourseIdを必ず含めて保存 ★★★
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final entriesToSave =
            timeTableEntries.map((entry) => entry.toMap()).toList();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('timetable')
            .doc('entries')
            .set({'entries': entriesToSave}, SetOptions(merge: true));
        print('DEBUG: FirestoreにcourseId付きで時間割エントリを保存しました');
      }
    } catch (e) {
      print('ERROR: Firestoreへの時間割保存に失敗: $e');
    }

    // ★★★ 乱数で色を生成 ★★★
    _courseColors.clear();
    for (var entry in timeTableEntries) {
      if (entry.courseId != null &&
          !_courseColors.containsKey(entry.courseId)) {
        // courseIdのハッシュ値を使って一貫した色を生成
        final int hash = entry.courseId!.hashCode;
        final Random random = Random(hash);

        // 明るく見やすい色を生成
        final int r = 100 + random.nextInt(156); // 100-255
        final int g = 100 + random.nextInt(156); // 100-255
        final int b = 100 + random.nextInt(156); // 100-255

        _courseColors[entry.courseId!] = Color.fromARGB(255, r, g, b);
        print(
          'DEBUG: courseId ${entry.courseId} -> 乱数色: ${_courseColors[entry.courseId]} (hash: $hash)',
        );
      }
    }

    List<List<TimetableEntry?>> grid = List.generate(
      _days.length,
      (dayIndex) => List.generate(_academicPeriods, (periodIndex) => null),
    );
    for (var entry in timeTableEntries) {
      grid[entry.dayOfWeek][entry.period - 1] = entry;
    }
    setState(() {
      _timetableGrid = grid;
    });
  }

  // ★★★ Firebaseにレギュラー授業情報を保存 ★★★
  Future<void> _saveRegularScheduleToFirebase(
    Map<String, String> subjectToRegularSlot,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final regularScheduleData = <String, dynamic>{};

        for (var entry in subjectToRegularSlot.entries) {
          String subjectName = entry.key;
          String regularSlot = entry.value;
          List<String> slotParts = regularSlot.split('_');
          int regularDay = int.parse(slotParts[0]);
          int regularPeriod = int.parse(slotParts[1]);

          regularScheduleData[subjectName] = {
            'regularDay': regularDay,
            'regularPeriod': regularPeriod,
            'regularSlot': regularSlot,
            'lastUpdated': DateTime.now().toIso8601String(),
          };
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('regularSchedule')
            .doc('subjects')
            .set(regularScheduleData, SetOptions(merge: true));

        print('DEBUG: レギュラー授業情報をFirebaseに保存しました');
      }
    } catch (e) {
      print('ERROR: Firebaseへの保存に失敗しました: $e');
    }
  }

  void _updateWeekDates() {
    final startOfWeek = _displayedMonday;
    final endOfWeek = _displayedMonday.add(const Duration(days: 6));
    _weekDateRange =
        "${DateFormat.Md('ja').format(startOfWeek)} 〜 ${DateFormat.Md('ja').format(endOfWeek)}";
    _dayDates = List.generate(
      _days.length,
      (index) => DateFormat.d(
        'ja',
      ).format(_displayedMonday.add(Duration(days: index))),
    );
    if (mounted) setState(() {});
  }

  final double _timeColumnWidth = 60.0;
  void _goToPreviousWeek() {
    setState(() {
      _displayedMonday = _displayedMonday.subtract(const Duration(days: 7));
      _updateWeekDates();
    });
    _initializeTimetableGrid(_displayedMonday);
  }

  void _goToNextWeek() {
    setState(() {
      _displayedMonday = _displayedMonday.add(const Duration(days: 7));
      _updateWeekDates();
    });
    _initializeTimetableGrid(_displayedMonday);
  }

  void _updateHighlight() {
    final now = DateTime.now();
    final newProgress = _calculateActiveTimeProgress(now);
    if (_timeGaugeProgress != newProgress && mounted) {
      setState(() {
        _timeGaugeProgress = newProgress;
      });
    }
  }

  double _calculateActiveTimeProgress(DateTime now) {
    final currentTimeInMinutes = now.hour * 60.0 + now.minute;
    final blocks = [
      {
        'start': 8 * 60 + 50.0,
        'end': 10 * 60 + 20.0,
        'height': _periodRowHeight,
      },
      {'start': 10 * 60 + 20.0, 'end': 10 * 60 + 30.0, 'height': 0.0},
      {
        'start': 10 * 60 + 30.0,
        'end': 12 * 60 + 0.0,
        'height': _periodRowHeight,
      },
      {
        'start': 12 * 60 + 0.0,
        'end': 13 * 60 + 30.0,
        'height': _periodRowHeight,
      },
      {
        'start': 13 * 60 + 30.0,
        'end': 15 * 60 + 0.0,
        'height': _periodRowHeight,
      },
      {'start': 15 * 60 + 0.0, 'end': 15 * 60 + 10.0, 'height': 0.0},
      {
        'start': 15 * 60 + 10.0,
        'end': 16 * 60 + 40.0,
        'height': _periodRowHeight,
      },
      {'start': 16 * 60 + 40.0, 'end': 16 * 60 + 50.0, 'height': 0.0},
      {
        'start': 16 * 60 + 50.0,
        'end': 18 * 60 + 20.0,
        'height': _periodRowHeight,
      },
      {'start': 18 * 60 + 20.0, 'end': 18 * 60 + 30.0, 'height': 0.0},
      {
        'start': 18 * 60 + 30.0,
        'end': 20 * 60 + 0.0,
        'height': _periodRowHeight,
      },
      {'start': 20 * 60 + 0.0, 'end': 24 * 60.0, 'height': _periodRowHeight},
    ];
    double accumulatedHeight = 0.0;
    final double totalHeight = _periodRowHeight * 8;
    if (currentTimeInMinutes < blocks.first['start']!) return 0.0;
    if (currentTimeInMinutes >= blocks.last['end']!) return 1.0;
    for (final block in blocks) {
      final double blockStart = block['start']!;
      final double blockEnd = block['end']!;
      final double blockHeight = block['height']!;
      if (currentTimeInMinutes < blockStart) break;
      if (currentTimeInMinutes >= blockStart &&
          currentTimeInMinutes <= blockEnd) {
        final double blockDuration = blockEnd - blockStart;
        if (blockDuration > 0) {
          final double progressInBlock =
              (currentTimeInMinutes - blockStart) / blockDuration;
          accumulatedHeight += blockHeight * progressInBlock;
        }
        break;
      }
      accumulatedHeight += blockHeight;
    }
    return (accumulatedHeight / totalHeight).clamp(0.0, 1.0);
  }

  void _placeCharactersRandomly() {
    // This method needs to be updated to work with the new Stack layout
  }

  String _getNoteForCell(int dayIndex, {int? periodIndex}) {
    // ★★★ courseIdベースでメモを取得するように修正 ★★★
    if (periodIndex != null &&
        _timetableGrid.isNotEmpty &&
        dayIndex < _timetableGrid.length &&
        periodIndex < _timetableGrid[dayIndex].length) {
      final entry = _timetableGrid[dayIndex][periodIndex];
      if (entry != null) {
        final String oneTimeNoteKey;
        if (entry.courseId != null) {
          oneTimeNoteKey =
              "${entry.courseId}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
        } else {
          // 後方互換性のため、courseIdがない場合は古い形式を使用
          oneTimeNoteKey =
              "C_${dayIndex}_${periodIndex}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
        }
        final String weeklyNoteKey;
        if (entry.courseId != null) {
          weeklyNoteKey = "W_${entry.courseId}";
        } else {
          // 後方互換性のため、courseIdがない場合は古い形式を使用
          weeklyNoteKey = "W_C_${dayIndex}_$periodIndex";
        }

        // ★★★ 修正：その日の特定のメモが存在する場合はそれを優先表示 ★★★
        if (cellNotes.containsKey(oneTimeNoteKey)) {
          return cellNotes[oneTimeNoteKey] ?? '';
        }

        // ★★★ その日の特定のメモが存在しない場合のみ、週次メモを表示 ★★★
        if (weeklyNotes.containsKey(weeklyNoteKey)) {
          return weeklyNotes[weeklyNoteKey] ?? '';
        }

        return '';
      }
    }

    // フォールバック：古い形式のキーを使用
    final oneTimeNoteKey =
        "C_${dayIndex}_${periodIndex}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
    final String weeklyNoteKey = "W_C_${dayIndex}_$periodIndex";

    // ★★★ 修正：その日の特定のメモが存在する場合はそれを優先表示 ★★★
    if (cellNotes.containsKey(oneTimeNoteKey)) {
      return cellNotes[oneTimeNoteKey] ?? '';
    }

    // ★★★ その日の特定のメモが存在しない場合のみ、週次メモを表示 ★★★
    if (weeklyNotes.containsKey(weeklyNoteKey)) {
      return weeklyNotes[weeklyNoteKey] ?? '';
    }

    return '';
  }

  // ★このメソッドはRiverpod経由で状態を更新するだけなので、Firestoreへの直接書き込みは行わない
  // ★Firestoreへの書き込みはmain.dartの_handleAttendanceActionに一元化
  void _setAttendanceStatus(
    String uniqueKey,
    String courseId,
    AttendanceStatus status,
  ) {
    setState(() {
      final date = DateFormat('yyyyMMdd').format(
        _displayedMonday.add(
          Duration(days: _getDayIndexFromUniqueKey(uniqueKey)),
        ),
      );

      // ★★★ 修正点：Providerから直接データを読み込む ★★★
      final allAttendanceStatus =
          ref.read(timetableProvider)['attendanceStatus']
              as Map<String, Map<String, String>>? ??
          {};
      final courseStatus = allAttendanceStatus[courseId] ?? {};
      final oldStatusString = courseStatus[date];

      final oldStatus =
          oldStatusString != null && oldStatusString.isNotEmpty
              ? AttendanceStatus.values.firstWhere(
                (s) => s.toString() == oldStatusString,
                orElse: () => AttendanceStatus.none,
              )
              : AttendanceStatus.none;

      final newStatus = status;

      // 状態が変化しない場合は何もしない
      if (oldStatus == newStatus) {
        return;
      }

      // ★★★ 新しいステータスをProviderに保存 ★★★
      if (newStatus == AttendanceStatus.none) {
        ref
            .read(timetableProvider.notifier)
            .setAttendanceStatus(courseId, date, '');
      } else {
        ref
            .read(timetableProvider.notifier)
            .setAttendanceStatus(courseId, date, newStatus.toString());
      }

      // ★★★ 状態の変化に基づいてカウントを更新（Riverpodの状態を直接更新） ★★★
      // このカウント更新は、main.dartの_handleAttendanceActionがFirestoreを更新し、
      // _listenToAttendanceCountsがFirestoreから読み込んでRiverpodを更新する、という流れがあるため
      // ここで二重に更新する必要はないが、UIの即時更新のために行う場合もある
      // ただし、_handleAttendanceActionが呼ばれる前にUIに即時反映させたい場合は残す
      // ここでは、_handleAttendanceActionがFirestoreを更新するのと同時に、
      // この_setAttendanceStatusがRiverpodを更新するというパターンを維持する

      // 欠席カウントのロジック
      if (oldStatus != AttendanceStatus.absent &&
          newStatus == AttendanceStatus.absent) {
        final newAbsenceCount = Map<String, int>.from(absenceCount);
        newAbsenceCount[courseId] = (newAbsenceCount[courseId] ?? 0) + 1;
        _updateAbsenceCount(newAbsenceCount);
      } else if (oldStatus == AttendanceStatus.absent &&
          newStatus != AttendanceStatus.absent) {
        final newAbsenceCount = Map<String, int>.from(absenceCount);
        newAbsenceCount[courseId] = max(
          0,
          (newAbsenceCount[courseId] ?? 1) - 1,
        );
        _updateAbsenceCount(newAbsenceCount);
      }

      // 遅刻カウントのロジック
      if (oldStatus != AttendanceStatus.late &&
          newStatus == AttendanceStatus.late) {
        final newLateCount = Map<String, int>.from(lateCount);
        newLateCount[courseId] = (newLateCount[courseId] ?? 0) + 1;
        _updateLateCount(newLateCount);
      } else if (oldStatus == AttendanceStatus.late &&
          newStatus != AttendanceStatus.late) {
        final newLateCount = Map<String, int>.from(lateCount);
        newLateCount[courseId] = max(0, (newLateCount[courseId] ?? 1) - 1);
        _updateLateCount(newLateCount);
      }
    });
  }

  // ★★★ uniqueKeyから日付のインデックスを取得するヘルパーメソッド ★★★
  int _getDayIndexFromUniqueKey(String uniqueKey) {
    // uniqueKeyの形式: "courseId_20241201" または "C_0_1_20241201"
    final parts = uniqueKey.split('_');
    if (parts.length >= 2) {
      final dateStr = parts.last;
      try {
        // 安全な解析を試みる
        final date = DateFormat('yyyyMMdd').parse(dateStr);
        return date.difference(_displayedMonday).inDays;
      } on FormatException catch (e) {
        // 解析失敗時にエラーログを出力
        print('Error parsing date from uniqueKey: "$uniqueKey"');
        print('Date string was: "$dateStr"');
        print('FormatException: $e');
        return 0; // エラー時はフォールバック
      }
    }
    return 0; // フォールバック
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Color _getNeonWarningColor(Color baseColor, String? courseId) {
    if (courseId == null) {
      return baseColor;
    }
    final int absenceCount = this.absenceCount[courseId] ?? 0; // Riverpodから取得
    final int lateCount = this.lateCount[courseId] ?? 0; // Riverpodから取得
    final double warningLevel = (absenceCount * 1.0) + (lateCount * 0.5);
    final double t = (warningLevel / 3.0).clamp(0.0, 1.0);
    final warningColor = Colors.redAccent[400]!;
    return Color.lerp(baseColor, warningColor, t)!;
  }

  List<Widget> _buildClassEntriesAsPositioned(
    int dayIndex,
    double totalHeight,
  ) {
    List<Widget> positionedWidgets = [];
    if (_timetableGrid.isEmpty || dayIndex >= _timetableGrid.length) {
      return positionedWidgets;
    }

    final double rowHeight = totalHeight / 8.0;

    // === 現在時刻の授業判定 ===
    final now = DateTime.now();
    final int todayWeekday = (now.weekday - 1) % 7; // Dart: 月曜=1, 日曜=7→0
    final int nowHour = now.hour;
    final int nowMinute = now.minute;
    int? currentPeriod;
    for (int i = 0; i < _periodTimes.length; i++) {
      final start = _parseTime(_periodTimes[i][0]);
      final end = _parseTime(_periodTimes[i][1]);
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      final nowMinutes = nowHour * 60 + nowMinute;
      if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
        currentPeriod = i + 1;
        break;
      }
    }

    for (
      int periodIndex = 0;
      periodIndex < _timetableGrid[dayIndex].length;
      periodIndex++
    ) {
      final entry = _timetableGrid[dayIndex][periodIndex];
      if (entry == null) continue;

      int visualRowIndex;
      final int period = entry.period;
      if (period <= 2) {
        visualRowIndex = period - 1;
      } else {
        visualRowIndex = period;
      }
      final double top = visualRowIndex * rowHeight;
      final double height = rowHeight;

      // ★★★ デバッグ用ログを追加 ★★★
      print(
        'DEBUG: Building cell - Day: $dayIndex, Period: $periodIndex, Subject: ${entry.subjectName}, CourseID: ${entry.courseId}, Teacher: ${teacherNames[entry.courseId]}',
      );

      // ★★★ uniqueKeyをcourseIdベースに変更 ★★★
      final String uniqueKey;
      if (entry.courseId != null) {
        uniqueKey =
            "${entry.courseId}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
      } else {
        // 後方互換性のため、courseIdがない場合は古い形式を使用
        uniqueKey =
            "${entry.id}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
      }

      // ★★★ 後方互換性のためのロジック変更 ★★★
      // まずcourseIdで出席方針を試し、なければ古い形式(id)で試す
      String? policyString = attendancePolicies[entry.courseId];
      if (policyString == null) {
        policyString = attendancePolicies[entry.id];
      }
      // それでもなければデフォルト値を設定
      policyString ??= AttendancePolicy.flexible.toString();

      final AttendancePolicy policy = AttendancePolicy.values.firstWhere(
        (p) => p.toString() == policyString,
        orElse: () => AttendancePolicy.flexible,
      );

      Color textColor = Colors.white;
      BoxDecoration decoration = BoxDecoration();

      switch (policy) {
        case AttendancePolicy.mandatory:
          // ★★★ courseIdベースで色を決定 ★★★
          Color baseColor;
          if (entry.courseId != null &&
              _courseColors.containsKey(entry.courseId)) {
            baseColor = _courseColors[entry.courseId]!;
            print(
              'DEBUG: ${entry.subjectName} (${entry.dayOfWeek}曜${entry.period}限) -> courseId: ${entry.courseId} -> 使用色: $baseColor',
            );
          } else {
            // フォールバック：subjectNameで色生成
            final int colorIndex =
                entry.subjectName.hashCode % _neonColors.length;
            baseColor = _neonColors[colorIndex];
            print(
              'DEBUG: ${entry.subjectName} (${entry.dayOfWeek}曜${entry.period}限) -> フォールバック色: $baseColor',
            );
          }
          final neonColor = _getNeonWarningColor(baseColor, entry.courseId);
          textColor = neonColor;
          decoration = BoxDecoration(
            color: neonColor.withOpacity(0.1),
            border: Border.all(color: neonColor, width: 1.5),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: neonColor.withOpacity(0.6), blurRadius: 10.0),
            ],
          );
          break;
        case AttendancePolicy.flexible:
          textColor = Colors.grey[400]!;
          decoration = BoxDecoration(
            color: Colors.grey[850]!.withOpacity(0.6),
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(6),
          );
          break;
        case AttendancePolicy.skip:
          textColor = Colors.grey[600]!;
          decoration = BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: Border.all(color: Colors.grey[850]!),
            borderRadius: BorderRadius.circular(6),
          );
          break;
      }
      if (entry.isCancelled) {
        textColor = Colors.red[300]!;
        decoration = BoxDecoration(
          color: entry.color.withOpacity(0.1),
          border: Border.all(color: entry.color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(6),
        );
      }

      final int absenceCountForDisplay = this.absenceCount[entry.courseId] ?? 0; // Riverpodから取得
      final int lateCountForDisplay = this.lateCount[entry.courseId] ?? 0; // Riverpodから取得
      final bool hasCount = absenceCountForDisplay > 0 || lateCountForDisplay > 0;
      final String noteText = _getNoteForCell(
        dayIndex,
        periodIndex: periodIndex,
      );

      // === 今あっている授業だけ枠を追加 ===
      final bool isNowClass =
          dayIndex == todayWeekday && entry.period == currentPeriod;
      final BoxDecoration finalDecoration =
          isNowClass
              ? decoration.copyWith(
                border: Border.all(color: Colors.amber, width: 3),
              )
              : decoration;

      final classWidget = Container(
        margin: const EdgeInsets.all(0.5),
        padding: const EdgeInsets.fromLTRB(6, 5, 4, 3),
        decoration: finalDecoration,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subjectName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    height: 1.2,
                    color: textColor,
                    shadows:
                        policy == AttendancePolicy.mandatory
                            ? [Shadow(color: textColor, blurRadius: 8.0)]
                            : [],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // ★★★ 表示優先順位のロジック ★★★
                if (hasCount) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (absenceCountForDisplay > 0)
                        Text(
                          '$absenceCountForDisplay',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (absenceCountForDisplay > 0 && lateCountForDisplay > 0)
                        const SizedBox(width: 6),
                      if (lateCountForDisplay > 0)
                        Text(
                          '$lateCountForDisplay',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ] else if (entry.courseId != null && // entry.courseIdはnullの場合があるのでチェック
                    teacherNames.containsKey(entry.courseId!)) ...[ // teacherNamesのキーにアクセスする際に!でnullをアサート
                  const SizedBox(height: 1),
                  Text(
                    teacherNames[entry.courseId!]!, // ★ !で強制
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // MainAxisSize.AxisSize.min を MainAxisSize.min に修正
                        children: [
                          if (noteText.isNotEmpty)
                            Text(
                              noteText,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.tealAccent.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (entry.classroom.isNotEmpty)
                            Text(
                              entry.classroom,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      // ★★★ シンプルな構造でPositionedウィジェットを作成 ★★★
      positionedWidgets.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              print(
                'DEBUG: Cell tapped - dayIndex: $dayIndex, periodIndex: $periodIndex, subject: ${entry.subjectName}',
              );
              _showNoteDialog(
                context,
                dayIndex,
                academicPeriodIndex: periodIndex,
              );
            },
            child: classWidget,
          ),
        ),
      );
    }
    return positionedWidgets;
  }

  List<Widget> _buildWeekdayEventsAsPositioned(
    int dayIndex,
    double totalHeight,
  ) {
    List<Widget> positionedWidgets = [];

    // 時間帯の定義
    const int classStartMinutes = 8 * 60 + 50; // 8:50
    const int classEndMinutes = 20 * 60 + 0; // 20:00
    const int dayEndMinutes = 24 * 60 + 0; // 24:00

    // 授業時間と放課後時間の高さ配分
    final double classTimeHeight = totalHeight * 0.85; // 授業時間は85%
    final double afterSchoolHeight = totalHeight * 0.15; // 放課後は15%

    if (!_weekdayEvents.containsKey(dayIndex)) {
      return positionedWidgets;
    }

    // 表示する週の日付を取得
    final DateTime currentDay = _displayedMonday.add(Duration(days: dayIndex));

    // 毎週の予定と、今週の予定のみをフィルタリング
    final List<Map<String, dynamic>> eventsToShow =
        _weekdayEvents[dayIndex]!.where((event) {
          if (event['isWeekly'] == true) {
            return true; // 毎週の予定は常に表示
          }
          // isWeeklyでない場合は日付をチェック
          final DateTime eventDate = event['date'];
          return eventDate.year == currentDay.year &&
              eventDate.month == currentDay.month &&
              eventDate.day == currentDay.day;
        }).toList();

    for (var event in eventsToShow) {
      final TimeOfDay startTime = event['start'];
      final TimeOfDay endTime = event['end'];
      final String title = event['title'];

      final int startMinutes = startTime.hour * 60 + startTime.minute;
      final int endMinutes = endTime.hour * 60 + endTime.minute;

      double top, height;

      if (startMinutes < classEndMinutes) {
        // 授業時間内の予定
        final double classStartMinutesFromBase =
            (startMinutes - classStartMinutes).toDouble();
        final double classEndMinutesFromBase =
            (endMinutes - classStartMinutes).toDouble();

        top =
            (classStartMinutesFromBase /
                (classEndMinutes - classStartMinutes)) *
            classTimeHeight;
        height =
            ((classEndMinutesFromBase - classStartMinutesFromBase) /
                (classEndMinutes - classStartMinutes)) *
            classTimeHeight;
      } else {
        // 放課後の予定
        final double afterSchoolStartMinutesFromBase =
            (startMinutes - classEndMinutes).toDouble();
        final double afterSchoolEndMinutesFromBase =
            (endMinutes - classEndMinutes).toDouble();

        top =
            classTimeHeight +
            (afterSchoolStartMinutesFromBase /
                    (dayEndMinutes - classEndMinutes)) *
                afterSchoolHeight;
        height =
            ((afterSchoolEndMinutesFromBase - afterSchoolStartMinutesFromBase) /
                (dayEndMinutes - classEndMinutes)) *
            afterSchoolHeight;
      }

      if (height <= 0) continue;

      const eventColor = Colors.amberAccent;
      final eventWidget = Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 0.5),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: eventColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: eventColor.withOpacity(0.9)),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 4.0)],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

      positionedWidgets.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: InkWell(
            onTap: () {
              _showEventDialog(
                dayIndex: dayIndex,
                eventIndex: eventsToShow.indexOf(event),
              );
            },
            child: eventWidget,
          ),
        ),
      );
    }
    return positionedWidgets;
  }

  // 汎用イベントダイアログ関数（日曜・平日共通）
  Future<void> _showEventDialog({
    required int dayIndex,
    TimeOfDay? newEventStartTime,
    int eventIndex = -1,
  }) async {
    final isSunday = dayIndex == 6;
    final events = isSunday ? _sundayEvents : (_weekdayEvents[dayIndex] ?? []);
    final eventToEdit =
        (eventIndex != -1 && eventIndex < events.length)
            ? events[eventIndex]
            : null;

    final titleController = TextEditingController(
      text: eventToEdit?['title'] ?? '',
    );
    TimeOfDay startTime =
        eventToEdit?['start'] ??
        (newEventStartTime ?? const TimeOfDay(hour: 10, minute: 0));
    TimeOfDay endTime =
        eventToEdit?['end'] ??
        TimeOfDay(
          hour: (startTime.hour + 1 > 23 ? 23 : startTime.hour + 1),
          minute: startTime.minute,
        );
    bool isWeekly = eventToEdit?['isWeekly'] ?? false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            '${_days[dayIndex]}の予定',
            style: const TextStyle(color: Colors.white, fontFamily: 'misaki'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '予定のタイトル',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.amberAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.amberAccent,
                        ),
                        onPressed: () async {
                          final picked = await pickTime(context, startTime);
                          if (picked != null) {
                            startTime = picked;
                          }
                        },
                        child: Text('開始: ${startTime.format(context)}'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.amberAccent,
                        ),
                        onPressed: () async {
                          final picked = await pickTime(context, endTime);
                          if (picked != null) {
                            endTime = picked;
                          }
                        },
                        child: Text('終了: ${endTime.format(context)}'),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  value: isWeekly,
                  onChanged: (v) {
                    isWeekly = v ?? false;
                  },
                  title: const Text(
                    '毎週の予定',
                    style: TextStyle(color: Colors.white),
                  ),
                  activeColor: Colors.amberAccent,
                  checkColor: Colors.black,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            if (eventToEdit != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    if (isSunday) {
                      _sundayEvents.removeAt(eventIndex);
                    } else {
                      _weekdayEvents[dayIndex]?.removeAt(eventIndex);
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: const Text(
                  '削除',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                if ((endTime.hour * 60 + endTime.minute) <=
                    (startTime.hour * 60 + startTime.minute))
                  return;
                setState(() {
                  final newEvent = {
                    'title': titleController.text,
                    'start': startTime,
                    'end': endTime,
                    'isWeekly': isWeekly,
                    'date': _displayedMonday.add(Duration(days: dayIndex)),
                  };
                  if (isSunday) {
                    if (eventToEdit == null) {
                      _sundayEvents.add(newEvent);
                    } else {
                      _sundayEvents[eventIndex] = newEvent;
                    }
                    _sundayEvents.sort(
                      (a, b) => (a['start'] as TimeOfDay).hour.compareTo(
                        (b['start'] as TimeOfDay).hour,
                      ),
                    );
                  } else {
                    _weekdayEvents[dayIndex] ??= [];
                    if (eventToEdit == null) {
                      _weekdayEvents[dayIndex]!.add(newEvent);
                    } else {
                      _weekdayEvents[dayIndex]![eventIndex] = newEvent;
                    }
                    _weekdayEvents[dayIndex]!.sort(
                      (a, b) => (a['start'] as TimeOfDay).hour.compareTo(
                        (b['start'] as TimeOfDay).hour,
                      ),
                    );
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                '保存',
                style: TextStyle(color: Colors.amberAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  // ★★★ _buildTimetableBackgroundCells はそのままでOKです ★★★
  Widget _buildTimetableBackgroundCells(int dayIndex) {
    return Column(
      children: List.generate(8, (index) {
        // ★★★ 修正点：Expandedをやめ、全てのコマが同じ高さになるようにする ★★★
        return Expanded(
          flex: 1,
          child: InkWell(
            onTap: () => _showWeekdayEventDialog(dayIndex),
            child: Container(
              margin: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayColumn(
    int dayIndex,
    double periodHeight,
    double specialHeight,
  ) {
    // For Sunday
    if (dayIndex == 6) {
      final double totalHeight = periodHeight * 8;
      return Expanded(
        flex: 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final double tappedY = details.localPosition.dy;
            const double classStartMinutes = 8 * 60 + 50; // 8:50
            const double classEndMinutes = 20 * 60 + 0; // 20:00
            const double dayEndMinutes = 24 * 60 + 0; // 24:00

            // 授業時間と放課後時間の高さ配分
            final double classTimeHeight = totalHeight * 0.85; // 授業時間は85%
            final double afterSchoolHeight = totalHeight * 0.15; // 放課後は15%

            double totalMinutesFromMidnight;

            if (tappedY < classTimeHeight) {
              // 授業時間エリアのタップ
              final double classTimeRatio = tappedY / classTimeHeight;
              totalMinutesFromMidnight =
                  classStartMinutes +
                  (classTimeRatio * (classEndMinutes - classStartMinutes));
            } else {
              // 放課後エリアのタップ
              final double afterSchoolRatio =
                  (tappedY - classTimeHeight) / afterSchoolHeight;
              totalMinutesFromMidnight =
                  classEndMinutes +
                  (afterSchoolRatio * (dayEndMinutes - classEndMinutes));
            }

            if (totalMinutesFromMidnight > dayEndMinutes - 60) {
              totalMinutesFromMidnight = dayEndMinutes - 60;
            }
            // 開始時刻を一番近い30分単位に丸める
            final double roundedTotalMinutes =
                (totalMinutesFromMidnight / 30).round() * 30.0;
            int hour = roundedTotalMinutes.toInt() ~/ 60;
            int minute = roundedTotalMinutes.toInt() % 60;

            final startTime = TimeOfDay(hour: hour, minute: minute);
            _showEventDialog(dayIndex: 6, newEventStartTime: startTime);
          },
          child: SizedBox(
            height: totalHeight,
            child: Stack(children: _buildSundayEventCells(totalHeight)),
          ),
        ),
      );
    }
    // For Weekdays
    return Expanded(
      flex: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              // ★★★ タップされた位置に授業コマがあるかチェック ★★★
              final double tappedY = details.localPosition.dy;
              final double rowHeight = totalHeight / 8.0;

              // タップされた位置の行インデックスを計算
              int tappedRowIndex = (tappedY / rowHeight).floor();

              // 昼休みの場合は、授業コマの存在チェックをスキップ
              if (tappedRowIndex == 2) {
                // 昼休みの場合、12:30をデフォルトにする
                const double totalMinutesFromMidnight = 12 * 60 + 30;
                final startTime = TimeOfDay(hour: 12, minute: 30);
                _showEventDialog(
                  dayIndex: dayIndex,
                  eventIndex: -1,
                  newEventStartTime: startTime,
                );
                return;
              }

              // 行インデックスを時間割の時限インデックスに変換
              int periodIndex;
              if (tappedRowIndex < 2) {
                periodIndex = tappedRowIndex; // 1限、2限
              } else {
                periodIndex = tappedRowIndex - 1; // 3限以降
              }

              // ★★★ 授業コマが存在する場合は、予定追加の処理を完全にスキップ ★★★
              if (periodIndex >= 0 &&
                  periodIndex < _timetableGrid[dayIndex].length &&
                  _timetableGrid[dayIndex][periodIndex] != null) {
                print(
                  'DEBUG: Skipping event dialog - class exists at period $periodIndex',
                );
                return;
              }

              print(
                'DEBUG: Showing event dialog - no class at period $periodIndex',
              );

              // 授業コマが存在しない場合のみ、予定追加ダイアログを表示
              const double classStartMinutes = 8 * 60 + 50; // 8:50
              const double classEndMinutes = 20 * 60 + 0; // 20:00
              const double dayEndMinutes = 24 * 60 + 0; // 24:00

              // 授業時間と放課後時間の高さ配分
              final double classTimeHeight = totalHeight * 0.85; // 授業時間は85%
              final double afterSchoolHeight = totalHeight * 0.15; // 放課後は15%

              double totalMinutesFromMidnight;

              if (tappedY < classTimeHeight) {
                // 授業時間エリアのタップ
                final double classTimeRatio = tappedY / classTimeHeight;
                totalMinutesFromMidnight =
                    classStartMinutes +
                    (classTimeRatio * (classEndMinutes - classStartMinutes));
              } else {
                // 放課後エリアのタップ
                final double afterSchoolRatio =
                    (tappedY - classTimeHeight) / afterSchoolHeight;
                totalMinutesFromMidnight =
                    classEndMinutes +
                    (afterSchoolRatio * (dayEndMinutes - classEndMinutes));
              }

              if (totalMinutesFromMidnight > dayEndMinutes - 60) {
                totalMinutesFromMidnight = dayEndMinutes - 60;
              }
              // 開始時刻を一番近い30分単位に丸める
              final double roundedTotalMinutes =
                  (totalMinutesFromMidnight / 30).round() * 30.0;
              int hour = roundedTotalMinutes.toInt() ~/ 60;
              int minute = roundedTotalMinutes.toInt() % 60;

              final startTime = TimeOfDay(hour: hour, minute: minute);
              _showEventDialog(
                dayIndex: dayIndex,
                eventIndex: -1,
                newEventStartTime: startTime,
              );
            },
            child: Stack(
              children: [
                ..._buildClassEntriesAsPositioned(dayIndex, totalHeight),
                ..._buildWeekdayEventsAsPositioned(dayIndex, totalHeight),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewTimetableGrid({
    required double periodRowHeight,
    required double lunchRowHeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (dayIndex) {
        return _buildDayColumn(dayIndex, periodRowHeight, lunchRowHeight);
      }),
    );
  }

  Future<void> _showWeekdayEventDialog(int dayIndex) async {
    final TextEditingController titleController = TextEditingController();
    TimeOfDay? startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay? endTime = const TimeOfDay(hour: 12, minute: 0);
    bool isWeekly = false;

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
                side: BorderSide(color: Colors.tealAccent.withOpacity(0.5)),
              ),
              title: Text(
                '${_days[dayIndex]}曜日の予定を追加',
                style: const TextStyle(
                  fontFamily: 'misaki',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: '予定のタイトル',
                        hintStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.tealAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: () async {
                            final TimeOfDay? picked = await pickTime(
                              context,
                              startTime ?? TimeOfDay.now(),
                            );
                            if (picked != null)
                              setDialogState(() => startTime = picked);
                          },
                          child: Text(
                            "開始: ${startTime?.format(context) ?? '未選択'}",
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final TimeOfDay? picked = await pickTime(
                              context,
                              endTime ?? startTime ?? TimeOfDay.now(),
                            );
                            if (picked != null)
                              setDialogState(() => endTime = picked);
                          },
                          child: Text(
                            "終了: ${endTime?.format(context) ?? '未選択'}",
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      title: const Text(
                        "毎週の予定にする",
                        style: TextStyle(
                          fontFamily: 'misaki',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      value: isWeekly,
                      activeColor: Colors.tealAccent,
                      checkColor: Colors.black,
                      onChanged:
                          (bool? value) =>
                              setDialogState(() => isWeekly = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'キャンセル',
                    style: TextStyle(
                      fontFamily: 'misaki',
                      color: Colors.brown[600],
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontFamily: 'misaki', color: Colors.white),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave == true) {
      setState(() {
        final newEvent = {
          'title': titleController.text,
          'start': startTime!,
          'end': endTime!,
          'isWeekly': isWeekly,
          'date': _displayedMonday.add(Duration(days: dayIndex)),
        };
        if (_weekdayEvents[dayIndex] == null) _weekdayEvents[dayIndex] = [];
        _weekdayEvents[dayIndex]!.add(newEvent);
        _weekdayEvents[dayIndex]!.sort(
          (a, b) => (a['start'] as TimeOfDay).hour.compareTo(
            (b['start'] as TimeOfDay).hour,
          ),
        );
      });
    }
  }

<<<<<<< HEAD
=======
  Future<void> _showSundayEventDialog({TimeOfDay? newEventStartTime}) async {
    final titleController = TextEditingController();
    TimeOfDay? startTime = newEventStartTime;
    TimeOfDay? endTime;
    if (newEventStartTime != null) {
      final endHour = newEventStartTime.hour + 1;
      endTime = TimeOfDay(
        hour: endHour > 23 ? 23 : endHour,
        minute: endHour > 23 ? 59 : newEventStartTime.minute,
      );
    }
    bool isWeekly = false;

    bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ★★★ 変更を検知するためのロジックを追加 ★★★
            final bool isTitleValid = titleController.text.isNotEmpty;
            final bool isTimeValid =
                startTime != null &&
                endTime != null &&
                (endTime!.hour * 60 + endTime!.minute) >
                    (startTime!.hour * 60 + startTime!.minute);
            final bool canSave = isTitleValid && isTimeValid;

            // ★★★ テキストが変更されたときにUIを更新 ★★★
            titleController.addListener(() {
              setDialogState(() {});
            });

            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 22, 22, 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: const Text(
                '日曜の予定',
                style: TextStyle(color: Colors.white, fontFamily: 'misaki'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '予定のタイトル',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.amberAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: startTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => startTime = picked);
                          }
                        },
                        child: Text(
                          "開始: ${startTime?.format(context) ?? '未選択'}",
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime:
                                endTime ?? startTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => endTime = picked);
                          }
                        },
                        child: Text(
                          "終了: ${endTime?.format(context) ?? '未選択'}",
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text(
                      "毎週の予定にする",
                      style: TextStyle(
                        fontFamily: 'misaki',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    value: isWeekly,
                    activeColor: Colors.amberAccent,
                    checkColor: Colors.black,
                    onChanged:
                        (bool? value) =>
                            setDialogState(() => isWeekly = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed:
                      canSave ? () => Navigator.of(context).pop(true) : null,
                  child: const Text(
                    '保存',
                    style: TextStyle(color: Colors.amberAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave == true) {
      setState(() {
        _sundayEvents.add({
          'title': titleController.text,
          'start': startTime!,
          'end': endTime!,
          'isWeekly': isWeekly,
          'date': _displayedMonday.add(const Duration(days: 6)),
        });
        _sundayEvents.sort(
          (a, b) => (a['start'] as TimeOfDay).hour.compareTo(
            (b['start'] as TimeOfDay).hour,
          ),
        );
      });
    }
  }

  // ★★★ _showNoteDialog の定義（こちらが正しい一つだけの定義） ★★★
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
  Future<void> _showNoteDialog(
    BuildContext context,
    int dayIndex, {
    int? academicPeriodIndex,
  }) async {
    TimetableEntry? entry;
    if (academicPeriodIndex != null &&
        dayIndex < _timetableGrid.length &&
        academicPeriodIndex < _timetableGrid[dayIndex].length) {
      entry = _timetableGrid[dayIndex][academicPeriodIndex];
<<<<<<< HEAD
    }

    if (entry == null) {
      return;
    }

    final oneTimeNoteKey =
        "${entry.courseId!}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
    final weeklyNoteKey = "W_${entry.courseId!}";
=======
    } else {
      return; // academicPeriodIndex がない場合は処理を終了
    }

    // entry が null の場合はここで処理を中断
    if (entry == null) {
      print('Error: TimetableEntry is null for dayIndex=$dayIndex, academicPeriodIndex=$academicPeriodIndex');
      return;
    }

    // ★★★ uniqueKeyをcourseIdベースに変更 ★★★
    final String oneTimeNoteKey;
    if (entry != null && entry.courseId != null) { // entryがnullでないことを確認
      oneTimeNoteKey =
          "${entry.courseId!}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
    } else {
      // 後方互換性のため、courseIdがない場合は古い形式を使用
      oneTimeNoteKey =
          "C_${dayIndex}_${academicPeriodIndex}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
    }
    final String weeklyNoteKey;
    if (entry != null && entry.courseId != null) { // entryがnullでないことを確認してからcourseIdにアクセス
      weeklyNoteKey = "W_${entry.courseId!}";
    } else {
      // 後方互換性のため、courseIdがない場合は古い形式を使用
      weeklyNoteKey = "W_C_${dayIndex}_$academicPeriodIndex";
    }
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5

    final initialText =
        cellNotes[oneTimeNoteKey] ?? weeklyNotes[weeklyNoteKey] ?? '';
    final isInitiallyWeekly =
        weeklyNotes.containsKey(weeklyNoteKey) &&
        !cellNotes.containsKey(oneTimeNoteKey);
<<<<<<< HEAD
    final initialPolicyString =
        attendancePolicies[entry.courseId] ??
        attendancePolicies[entry.id] ??
        AttendancePolicy.flexible.toString();
=======

    // ★★★ 出席方針の初期値もcourseIdベースで取得 ★★★
    String? initialPolicyString;
    if (entry != null && entry.courseId != null) { // entryがnullでないことを確認してからcourseIdにアクセス
      initialPolicyString = attendancePolicies[entry.courseId!];
    }
    if (initialPolicyString == null && entry.id != null) {
      initialPolicyString = attendancePolicies[entry.id];
    }
    initialPolicyString ??= AttendancePolicy.flexible.toString();
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5

    final initialPolicy = AttendancePolicy.values.firstWhere(
      (p) => p.toString() == initialPolicyString,
      orElse: () => AttendancePolicy.flexible,
    );

    final noteController = TextEditingController(text: initialText);
    var isWeekly = isInitiallyWeekly;
    var selectedPolicy = initialPolicy;

    final teacherNameController = TextEditingController(
<<<<<<< HEAD
      text: teacherNames[entry.courseId] ?? '',
    );

    final date = DateFormat(
      'yyyyMMdd',
    ).format(_displayedMonday.add(Duration(days: dayIndex)));

    // ★★★ 修正点：Providerから直接データを読み込む ★★★
    final allAttendanceStatus =
        ref.read(timetableProvider)['attendanceStatus']
            as Map<String, Map<String, String>>? ??
        {};
    final courseStatus = allAttendanceStatus[entry.courseId!] ?? {};
    final initialStatusString = courseStatus[date];

    var currentStatus =
        initialStatusString != null && initialStatusString.isNotEmpty
            ? AttendanceStatus.values.firstWhere(
              (s) => s.toString() == initialStatusString,
              orElse: () => AttendanceStatus.none,
            )
            : AttendanceStatus.none;

    await showDialog<void>(
=======
      text: entry.courseId != null ? teacherNames[entry.courseId!] ?? '' : '', // entryはnullでないのでentry.courseId?.でなくentry.courseIdとする
    );

    // ダイアログが開かれる直前に、現在の出欠状態を取得する（UI表示用）
    final String dateForStatus = DateFormat('yyyyMMdd').format(
        _displayedMonday.add(Duration(days: dayIndex)));
    String? currentStatusStringInDialog = entry.courseId != null // entryはnullでないのでentry.courseId?.でなくentry.courseIdとする
        ? ref.read(timetableProvider.notifier).getAttendanceStatus(entry.courseId!, dateForStatus)
        : null;
    AttendanceStatus currentAttendanceStatusInDialog = currentStatusStringInDialog != null && currentStatusStringInDialog.isNotEmpty
        ? AttendanceStatus.values.firstWhere(
            (s) => s.toString() == currentStatusStringInDialog,
            orElse: () => AttendanceStatus.none,
          )
        : AttendanceStatus.none;

    bool? noteWasSaved = await showDialog<bool>(
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
<<<<<<< HEAD
            final activeAbsentStyle = ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              elevation: 8,
              shadowColor: Colors.redAccent.withOpacity(0.5),
            );

            final activeLateStyle = ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.orangeAccent, width: 2),
              ),
              elevation: 8,
              shadowColor: Colors.orangeAccent.withOpacity(0.5),
            );

            final inactiveStyle = ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[700]!),
              ),
              elevation: 2,
            );
=======
            // ★★★ 変更を検知するためのロジックを追加 ★★★
            final bool hasChanged =
                noteController.text != initialText ||
                isWeekly != isInitiallyWeekly ||
                selectedPolicy != initialPolicy ||
                teacherNameController.text.trim() !=
                    (entry != null && entry.courseId != null // entryがnullでないことを確認してからcourseIdにアクセス
                        ? teacherNames[entry.courseId!] ?? ''
                        : '');
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5

            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 22, 22, 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_days[dayIndex]}曜 ${academicPeriodIndex! + 1}限",
                    style: const TextStyle(
                      fontFamily: 'misaki',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
<<<<<<< HEAD
                    "${entry!.subjectName} (${entry.originalLocation})",
=======
                    "${entry?.subjectName ?? ''} (${entry?.originalLocation ?? ''})", // entryがnullの場合も安全にアクセス
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
                    style: TextStyle(
                      fontFamily: 'misaki',
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: noteController,
                      maxLines: 5,
                      minLines: 3,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '授業のメモをどうぞ...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.amberAccent,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text(
                        "毎週のメモにする",
                        style: TextStyle(
                          fontFamily: 'misaki',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      value: isWeekly,
                      activeColor: Colors.amberAccent,
                      checkColor: Colors.black,
                      onChanged:
                          (bool? value) =>
                              setDialogState(() => isWeekly = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(color: Color.fromARGB(255, 78, 78, 78)),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        bottom: 8.0,
                        left: 4.0,
                      ),
                      child: Text(
                        "教員名:",
                        style: const TextStyle(
                          fontFamily: 'misaki',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TextField(
                      controller: teacherNameController,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '例: 田中太郎',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.amberAccent,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color.fromARGB(255, 78, 78, 78)),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        bottom: 8.0,
                        left: 4.0,
                      ),
                      child: Text(
                        "出席方針:",
                        style: const TextStyle(
                          fontFamily: 'misaki',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SegmentedButton<AttendancePolicy>(
                      segments: const <ButtonSegment<AttendancePolicy>>[
                        ButtonSegment<AttendancePolicy>(
                          value: AttendancePolicy.mandatory,
                          label: Text('毎回'),
                        ),
                        ButtonSegment<AttendancePolicy>(
                          value: AttendancePolicy.flexible,
                          label: Text('気分'),
                        ),
                        ButtonSegment<AttendancePolicy>(
                          value: AttendancePolicy.skip,
                          label: Text('切る'),
                        ),
                      ],
                      selected: {selectedPolicy},
                      onSelectionChanged: (Set<AttendancePolicy> newSelection) {
                        setDialogState(
                          () => selectedPolicy = newSelection.first,
                        );
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white70,
                        selectedBackgroundColor: Colors.amberAccent,
                        selectedForegroundColor: Colors.black,
                      ),
                    ),
                    if (selectedPolicy == AttendancePolicy.mandatory) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color.fromARGB(255, 78, 78, 78)),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          bottom: 8.0,
                          left: 4.0,
                        ),
                        child: Text(
                          "出席記録:",
                          style: const TextStyle(
                            fontFamily: 'misaki',
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
<<<<<<< HEAD
=======
                      // 現在の出席状態を表示
                      Builder(
                        builder: (context) {
                          final date = DateFormat('yyyyMMdd').format(
                            _displayedMonday.add(Duration(days: dayIndex)),
                          );
                          final currentStatusString =
                              entry != null && entry.courseId != null // entryがnullでないことを確認してからcourseIdにアクセス
                                  ? ref
                                      .read(timetableProvider.notifier)
                                      .getAttendanceStatus(
                                        entry.courseId!,
                                        date,
                                      )
                                  : null;
                          final AttendanceStatus currentStatus =
                              currentStatusString != null &&
                                      currentStatusString.isNotEmpty
                                  ? AttendanceStatus.values.firstWhere(
                                    (s) => s.toString() == currentStatusString,
                                    orElse: () => AttendanceStatus.none,
                                  )
                                  : AttendanceStatus.none;

                          // 欠席や遅刻の場合のみ表示
                          if (currentStatus == AttendanceStatus.absent ||
                              currentStatus == AttendanceStatus.late) {
                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        currentStatus == AttendanceStatus.absent
                                            ? Icons.cancel
                                            : Icons.watch_later,
                                        color:
                                            currentStatus ==
                                                    AttendanceStatus.absent
                                                ? Colors.red
                                                : Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        currentStatus == AttendanceStatus.absent
                                            ? '欠席'
                                            : '遅刻',
                                        style: TextStyle(
                                          color:
                                              currentStatus ==
                                                      AttendanceStatus.absent
                                                  ? Colors.red
                                                  : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                      // 出席記録ボタン
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
<<<<<<< HEAD
                              style:
                                  currentStatus == AttendanceStatus.absent
                                      ? activeAbsentStyle
                                      : inactiveStyle,
                              onPressed: () {
                                final newStatus =
                                    currentStatus == AttendanceStatus.absent
                                        ? AttendanceStatus.none
                                        : AttendanceStatus.absent;
                                _setAttendanceStatus(
                                  oneTimeNoteKey,
                                  entry!.courseId!,
                                  newStatus,
                                );
                                setDialogState(() => currentStatus = newStatus);
=======
                              onPressed: () async { // async を追加
                                if (entry != null && entry.courseId != null) { // entryがnullでないことを確認してからcourseIdにアクセス
                                  final date = DateFormat('yyyyMMdd').format(
                                    _displayedMonday.add(
                                      Duration(days: dayIndex),
                                    ),
                                  );
                                  final currentStatusString = entry != null && entry.courseId != null
                                      ? ref
                                          .read(timetableProvider.notifier)
                                          .getAttendanceStatus(
                                            entry.courseId!,
                                            date,
                                          )
                                      : null;
                                  final currentStatus =
                                      currentStatusString != null &&
                                              currentStatusString.isNotEmpty
                                          ? AttendanceStatus.values.firstWhere(
                                            (s) =>
                                                s.toString() ==
                                                currentStatusString,
                                            orElse: () => AttendanceStatus.none,
                                          )
                                          : AttendanceStatus.none;

                                  final String targetAction =
                                      currentStatus == AttendanceStatus.absent
                                          ? 'present_action' // 既に欠席なら出席（解除）
                                          : 'absent_action'; // そうでなければ欠席

                                  await _handleAttendanceAction(
                                    targetAction,
                                    entry.courseId!, // classId
                                  );
                                  // ダイアログの状態を更新して、現在の出欠表示を反映
                                  setDialogState(() {
                                      currentAttendanceStatusInDialog = (targetAction == 'present_action') ? AttendanceStatus.present : AttendanceStatus.absent;
                                  });
                                }
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('欠席'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
<<<<<<< HEAD
                              style:
                                  currentStatus == AttendanceStatus.late
                                      ? activeLateStyle
                                      : inactiveStyle,
                              onPressed: () {
                                final newStatus =
                                    currentStatus == AttendanceStatus.late
                                        ? AttendanceStatus.none
                                        : AttendanceStatus.late;
                                _setAttendanceStatus(
                                  oneTimeNoteKey,
                                  entry!.courseId!,
                                  newStatus,
                                );
                                setDialogState(() => currentStatus = newStatus);
=======
                              onPressed: () async { // async を追加
                                if (entry != null && entry.courseId != null) { // entryがnullでないことを確認してからcourseIdにアクセス
                                  final date = DateFormat('yyyyMMdd').format(
                                    _displayedMonday.add(
                                      Duration(days: dayIndex),
                                    ),
                                  );
                                  final currentStatusString = ref
                                      .read(timetableProvider.notifier)
                                      .getAttendanceStatus(
                                        entry.courseId!, // entry.courseIdはnullの場合があるので注意
                                        date,
                                      );
                                  final currentStatus =
                                      currentStatusString != null &&
                                              currentStatusString.isNotEmpty
                                          ? AttendanceStatus.values.firstWhere(
                                            (s) =>
                                                s.toString() ==
                                                currentStatusString,
                                            orElse: () => AttendanceStatus.none,
                                          )
                                          : AttendanceStatus.none;

                                  final String targetAction =
                                      currentStatus == AttendanceStatus.late
                                          ? 'present_action' // 既に遅刻なら出席（解除）
                                          : 'late_action'; // そうでなければ遅刻

                                  await _handleAttendanceAction(
                                    targetAction,
                                    entry.courseId!, // classId
                                  );
                                  // ダイアログの状態を更新して、現在の出欠表示を反映
                                  setDialogState(() {
                                      currentAttendanceStatusInDialog = (targetAction == 'present_action') ? AttendanceStatus.present : AttendanceStatus.late;
                                  });
                                }
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
                              },
                              icon: const Icon(Icons.watch_later_outlined),
                              label: const Text('遅刻'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
<<<<<<< HEAD
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[700]!),
=======
                      // 累計回数表示
                      if (entry != null && entry.courseId != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    color: Colors.red[400],
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '欠席',
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // absenceCount と lateCount は main.dart の _handleAttendanceAction が更新し、
                                  // time_schedule_page.dart の _listenToAttendanceCounts が購読して
                                  // Riverpodのプロバイダを更新するので、ref.watch で取得
                                  Text(
                                    '${absenceCount[entry.courseId!] ?? 0}回', // entryはnullでないのでentry.courseId?.でなくentry.courseIdとする
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(
                                    Icons.watch_later,
                                    color: Colors.orange[400],
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '遅刻',
                                    style: TextStyle(
                                      color: Colors.orange[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${lateCount[entry.courseId!] ?? 0}回', // entryはnullでないのでentry.courseId?.でなくentry.courseIdとする
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: Colors.red[400],
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '欠席',
                                  style: TextStyle(
                                    color: Colors.red[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${absenceCount[entry!.courseId] ?? 0}回',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.watch_later,
                                  color: Colors.orange[400],
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '遅刻',
                                  style: TextStyle(
                                    color: Colors.orange[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${lateCount[entry!.courseId] ?? 0}回',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontFamily: 'misaki', color: Colors.black),
                  ),
<<<<<<< HEAD
                  onPressed: () {
                    final newText = noteController.text.trim();
                    final newCellNotes = Map<String, String>.from(cellNotes);
                    final newWeeklyNotes = Map<String, String>.from(
                      weeklyNotes,
                    );
                    if (newText.isEmpty) {
                      newCellNotes.remove(oneTimeNoteKey);
                      newWeeklyNotes.remove(weeklyNoteKey);
                    } else {
                      if (isWeekly) {
                        newWeeklyNotes[weeklyNoteKey] = newText;
                        newCellNotes.remove(oneTimeNoteKey);
                      } else {
                        newCellNotes[oneTimeNoteKey] = newText;
                        newWeeklyNotes.remove(weeklyNoteKey);
                      }
                    }
                    _updateCellNotes(newCellNotes);
                    _updateWeeklyNotes(newWeeklyNotes);
                    _updateAttendancePolicies({
                      ...attendancePolicies,
                      entry!.courseId!: selectedPolicy.toString(),
                    });
                    final teacherName = teacherNameController.text.trim();
                    ref
                        .read(timetableProvider.notifier)
                        .setTeacherName(entry!.courseId!, teacherName);
                    Navigator.of(dialogContext).pop();
=======
                  onPressed: () async { // async を追加
                    final currentEntry = entry;
                    if (currentEntry != null) { // entryはnullでないのでcurrentEntryは常にnon-null。ただし、念のため残す
                      final newText = noteController.text.trim();

                      final newCellNotes = Map<String, String>.from(cellNotes);
                      final newWeeklyNotes = Map<String, String>.from(weeklyNotes);

                      if (newText.isEmpty) {
                        newCellNotes.remove(oneTimeNoteKey);
                        newWeeklyNotes.remove(weeklyNoteKey);
                      } else {
                        if (isWeekly) {
                          newWeeklyNotes[weeklyNoteKey] = newText;
                          newCellNotes.remove(oneTimeNoteKey);
                        } else {
                          newCellNotes[oneTimeNoteKey] = newText;
                          newWeeklyNotes.remove(weeklyNoteKey);
                        }
                      }

                      _updateCellNotes(newCellNotes);
                      _updateWeeklyNotes(newWeeklyNotes);

                      if (currentEntry.courseId != null) { // entryはnullでないのでcurrentEntry.courseId?.でなくcurrentEntry.courseIdとする
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance // await を追加
                              .collection('course_enrollments')
                              .doc(currentEntry.courseId!)
                              .set({
                                'enrolledUserIds': FieldValue.arrayUnion([user.uid]),
                              }, SetOptions(merge: true));
                        }

                        _updateAttendancePolicies({
                          ...attendancePolicies,
                          currentEntry.courseId!: selectedPolicy.toString(), // entryはnullでないのでcurrentEntry.courseId?.でなくcurrentEntry.courseIdとする
                        });

                        final teacherName = teacherNameController.text.trim();
                        if (teacherName.isNotEmpty) {
                          ref
                              .read(timetableProvider.notifier)
                              .setTeacherName(currentEntry.courseId!, teacherName); // entryはnullでないのでcurrentEntry.courseId?.でなくcurrentEntry.courseIdとする
                        } else {
                           ref
                              .read(timetableProvider.notifier)
                              .removeTeacherName(currentEntry.courseId!); // entryはnullでないのでcurrentEntry.courseId?.でなくcurrentEntry.courseIdとする
                        }
                      }
                    }
                    Navigator.of(dialogContext).pop(true);
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
                  },
                ),
              ],
            );
          },
        );
      },
    );
<<<<<<< HEAD
=======

    // ダイアログが閉じられた後に、もし出欠が変更された場合は
    // _listenToAttendanceCounts が Firestore の変更を検知して UI を更新する

>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
  }

  Widget _buildAttendanceStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icon(Icons.check_circle, color: Colors.green[600], size: 18);
      case AttendanceStatus.absent:
        return Icon(Icons.cancel, color: Colors.red[600], size: 18);
      case AttendanceStatus.late:
        return Icon(Icons.watch_later, color: Colors.orange[700], size: 18);
      case AttendanceStatus.none:
      default:
        return Icon(
          Icons.fact_check_outlined,
          color: Colors.grey[600],
          size: 18,
        );
    }
  }

  Widget _buildAttendancePopupMenu(String uniqueKey, TimetableEntry entry) {
    // ★★★ 後方互換性のためのロジック変更 ★★★
    String? policyString;
    if (entry.courseId != null) { // nullチェックを追加
      policyString = attendancePolicies[entry.courseId!];
    }
    if (policyString == null) {
      policyString = attendancePolicies[entry.id];
    }

    if (policyString != AttendancePolicy.mandatory.toString()) {
      return const SizedBox.shrink();
    }

    // ★★★ 新しい構造で出席状態を取得 ★★★
    final date = DateFormat('yyyyMMdd').format(
      _displayedMonday.add(
        Duration(days: _getDayIndexFromUniqueKey(uniqueKey)),
      ),
    );
    final currentStatusString = ref
        .read(timetableProvider.notifier)
        .getAttendanceStatus(entry.courseId ?? '', date); // entry.courseIdがnullの場合に備えて ?? ''
    final currentStatus =
        currentStatusString != null
            ? AttendanceStatus.values.firstWhere(
              (status) => status.toString() == currentStatusString,
              orElse: () => AttendanceStatus.none,
            )
            : AttendanceStatus.none;

    return Theme(
      data: Theme.of(
        context,
      ).copyWith(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: PopupMenuButton<AttendanceStatus>(
        child: _buildAttendanceStatusIcon(currentStatus),
        tooltip: '出欠を記録',
        onSelected: (AttendanceStatus newStatus) async {
          if (entry.courseId != null) { // entry.courseIdがnullの場合があるのでチェック
            // main.dart の _handleAttendanceAction を呼び出す
            String actionId;
            if (newStatus == AttendanceStatus.present) {
              actionId = 'present_action';
            } else if (newStatus == AttendanceStatus.absent) {
              actionId = 'absent_action';
            } else { // newStatus == AttendanceStatus.late
              actionId = 'late_action';
            }
            await _handleAttendanceAction(actionId, entry.courseId!); // entry.courseIdがnullでないことを保証
          }
        },
        itemBuilder:
            (BuildContext context) => <PopupMenuEntry<AttendanceStatus>>[
              const PopupMenuItem<AttendanceStatus>(
                value: AttendanceStatus.present,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Text('出席'),
                  ],
                ),
              ),
              const PopupMenuItem<AttendanceStatus>(
                value: AttendanceStatus.absent,
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text('欠席'),
                  ],
                ),
              ),
              const PopupMenuItem<AttendanceStatus>(
                value: AttendanceStatus.late,
                child: Row(
                  children: [
                    Icon(Icons.watch_later_outlined, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('遅刻'),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  List<Widget> _buildSundayEventCells(double totalHeight) {
    List<Widget> eventCells = [];

    // 時間帯の定義
    const int classStartMinutes = 8 * 60 + 50; // 8:50
    const int classEndMinutes = 20 * 60 + 0; // 20:00
    const int dayEndMinutes = 24 * 60 + 0; // 24:00

    // 授業時間と放課後時間の高さ配分
    final double classTimeHeight = totalHeight * 0.85; // 授業時間は85%
    final double afterSchoolHeight = totalHeight * 0.15; // 放課後は15%

    final DateTime currentSunday = _displayedMonday.add(
      const Duration(days: 6),
    );
    final List<Map<String, dynamic>> eventsToShow =
        _sundayEvents.where((event) {
          if (event['isWeekly'] == true) return true;
          final DateTime eventDate = event['date'];
          return eventDate.year == currentSunday.year &&
              eventDate.month == currentSunday.month &&
              eventDate.day == currentSunday.day;
        }).toList();

    for (var event in eventsToShow) {
      final TimeOfDay startTime = event['start'];
      final TimeOfDay endTime = event['end'];
      final String title = event['title'];

      final int startMinutes = startTime.hour * 60 + startTime.minute;
      final int endMinutes = endTime.hour * 60 + endTime.minute;

      double top, height;

      if (startMinutes < classEndMinutes) {
        // 授業時間内の予定
        final double classStartMinutesFromBase =
            (startMinutes - classStartMinutes).toDouble();
        final double classEndMinutesFromBase =
            (endMinutes - classStartMinutes).toDouble();

        top =
            (classStartMinutesFromBase /
                (classEndMinutes - classStartMinutes)) *
            classTimeHeight;
        height =
            ((classEndMinutesFromBase - classStartMinutesFromBase) /
                (classEndMinutes - classStartMinutes)) *
            classTimeHeight;
      } else {
        // 放課後の予定
        final double afterSchoolStartMinutesFromBase =
            (startMinutes - classEndMinutes).toDouble();
        final double afterSchoolEndMinutesFromBase =
            (endMinutes - classEndMinutes).toDouble();

        top =
            classTimeHeight +
            (afterSchoolStartMinutesFromBase /
                    (dayEndMinutes - classEndMinutes)) *
                afterSchoolHeight;
        height =
            ((afterSchoolEndMinutesFromBase - afterSchoolStartMinutesFromBase) /
                (dayEndMinutes - classEndMinutes)) *
            afterSchoolHeight;
      }

      if (height <= 0) continue;

      const eventColor = Colors.pinkAccent;
      eventCells.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 2.0),
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: eventColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: eventColor),
              boxShadow: [
                BoxShadow(color: eventColor.withOpacity(0.6), blurRadius: 8.0),
              ],
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'misaki',
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: eventColor, blurRadius: 10.0)],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }
    return eventCells;
  }

  Widget _buildNewContinuousTimeColumn({
    required double periodRowHeight,
    required double lunchRowHeight,
  }) {
    // 8つの行の高さリストを作成 (6つの授業コマ + 昼休み + 放課後)
    final List<double> rowHeights = [
      periodRowHeight, // 1限
      periodRowHeight, // 2限
      lunchRowHeight, // 昼休み
      periodRowHeight, // 3限
      periodRowHeight, // 4限
      periodRowHeight, // 5限
      periodRowHeight, // 6限
      periodRowHeight, // 放課後
    ];
    final double totalColumnHeight = rowHeights.reduce(
      (a, b) => a + b,
    ); // 全ての高さの合計

    final List<String> periodLabels = [
      '1',
      '2',
      '昼',
      '3',
      '4',
      '5',
      '6',
      '放課後',
    ];

    return Container(
      width: 45,
      height: totalColumnHeight, // 中身の合計高さと一致させる
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4), // 少し背景色を濃く
        // ★★★ オーバーフローの原因となっていた外側の枠線を削除 ★★★
        // border: Border.all(color: Colors.grey[700]!, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Stack(
          children: [
            // --- ゲージの進捗バー ---
            Align(
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                height: totalColumnHeight * _timeGaugeProgress,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 20, 182, 226).withOpacity(0.7),
                      const Color.fromARGB(255, 134, 19, 159).withOpacity(0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        20,
                        182,
                        226,
                      ).withOpacity(0.4),
                      blurRadius: 15.0,
                      spreadRadius: 5.0,
                    ),
                  ],
                ),
              ),
            ),
            // --- 時限ラベルと時間、そして罫線 ---
            Column(
              children: List.generate(rowHeights.length, (index) {
                final bool isClassPeriod =
                    (index < 2 || (index > 2 && index < 7));
                int? timeIndex;
                if (index < 2)
                  timeIndex = index;
                else if (index > 2 && index < 7)
                  timeIndex = index - 1;

                return Container(
                  height: rowHeights[index],
                  // Containerのdecorationで罫線を引く
                  decoration: BoxDecoration(
                    border:
                        index <
                                rowHeights.length -
                                    1 // 最後の行以外
                            ? Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(
                                  0.25,
                                ), // ★ 少し色を調整
                                width: 1.0,
                              ),
                            )
                            : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isClassPeriod && timeIndex != null) ...[
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _periodTimes[timeIndex][0],
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'misaki',
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              _periodTimes[timeIndex][1],
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'misaki',
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      Text(
                        periodLabels[index] == '放課後'
                            ? periodLabels[index].split('').join('\n')
                            : periodLabels[index],
                        style: TextStyle(
                          fontFamily: 'misaki',
                          fontSize: periodLabels[index].length > 1 ? 12 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        textAlign:
                            periodLabels[index] == '放課後'
                                ? TextAlign.center
                                : TextAlign.start,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // 新しいデザインの時間割ヘッダー（日付と曜日）
  Widget _buildNewTimetableHeader() {
    return Row(
      children: [
        SizedBox(width: _timeColumnWidth), // ★ 変数を使用
        Expanded(
          child: Row(
            children: List.generate(7, (dayIndex) {
              final isSunday = dayIndex == 6;
              return Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.all(1.5),
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                  ), // ★ 左右にパディングを追加
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _days[dayIndex],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'misaki',
                            color: isSunday ? Colors.red[300] : Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 2),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dayDates.isNotEmpty ? _dayDates[dayIndex] : "",
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'misaki',
                            color: isSunday ? Colors.red[200] : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ★週選択UI
  Widget _buildWeekSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 18,
            ),
            onPressed:
                () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
          ),
          Text(
            _weekDateRange,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
            onPressed:
                () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double bottomPaddingForNavBar = 100.0;
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/night_view.png", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  _buildWeekSelector(),
                  _buildNewTimetableHeader(),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _changeWeek,
                      itemBuilder: (context, page) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availableHeight = constraints.maxHeight;
                              final dynamicRowHeight = availableHeight / 8.0;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildNewContinuousTimeColumn(
                                    periodRowHeight: dynamicRowHeight,
                                    lunchRowHeight: dynamicRowHeight,
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 4.0,
                                          sigmaY: 4.0,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[800]!,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: _buildNewTimetableGrid(
                                            periodRowHeight: dynamicRowHeight,
                                            lunchRowHeight: dynamicRowHeight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _attendanceStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return '出席';
      case AttendanceStatus.absent:
        return '欠席';
      case AttendanceStatus.late:
        return '遅刻';
      case AttendanceStatus.none:
      default:
        return '未設定';
    }
  }

  // メモダイアログを表示
  void _showMemoDialog(String courseId, String subjectName) {
    final oneTimeNoteKey =
        "${courseId}_${DateFormat('yyyyMMdd').format(_displayedMonday)}";
    final weeklyNoteKey = "${courseId}_weekly";
    final memoController = TextEditingController(
      text: cellNotes[oneTimeNoteKey] ?? weeklyNotes[weeklyNoteKey] ?? '',
    );
    final attendancePolicy = attendancePolicies[courseId] ?? 'flexible';
    final teacherNameController = TextEditingController();

    // グローバル教員名を取得してセット
    _getGlobalTeacherName(courseId).then((name) {
      teacherNameController.text = name;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$subjectName のメモ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: memoController,
                      decoration: const InputDecoration(
                        labelText: 'メモ',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: attendancePolicy,
                      decoration: const InputDecoration(
                        labelText: '出席ポリシー',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'flexible', child: Text('柔軟')),
                        DropdownMenuItem(value: 'mandatory', child: Text('必須')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          // StatefulBuilder内での状態更新
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: teacherNameController,
                      decoration: const InputDecoration(
                        labelText: '教員名',
                        border: OutlineInputBorder(),
                        hintText: '例: 田中太郎',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 出席ボタン
<<<<<<< HEAD
=======
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // courseIdはnullでないので直接使用
                            await _handleAttendanceAction(
                              'present_action', // アクション識別子
                              courseId, // classId
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('出席'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // courseIdはnullでないので直接使用
                            await _handleAttendanceAction(
                              'absent_action', // アクション識別子
                              courseId, // classId
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('欠席'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // courseIdはnullでないので直接使用
                            await _handleAttendanceAction(
                              'late_action', // アクション識別子
                              courseId, // classId
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('遅刻'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 出席状況表示
                    Text(
                      '出席: ${absenceCount[courseId] ?? 0} | 遅刻: ${lateCount[courseId] ?? 0}', // 欠席カウントの重複修正
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    // メモを保存
                    final newText = memoController.text.trim();
                    final newCellNotes = Map<String, String>.from(cellNotes);
                    final oneTimeNoteKey =
                        "${courseId}_${DateFormat('yyyyMMdd').format(_displayedMonday)}";

                    if (newText.isEmpty) {
                      newCellNotes.remove(oneTimeNoteKey);
                    } else {
                      newCellNotes[oneTimeNoteKey] = newText;
                    }
                    _updateCellNotes(newCellNotes);

                    // 出席ポリシーを保存
                    final selectedPolicy = attendancePolicy;
                    final newPolicies = Map<String, String>.from(
                      attendancePolicies,
                    );
                    newPolicies[courseId] = selectedPolicy;
                    _updateAttendancePolicies(newPolicies);

                    // 教員名をグローバルに保存
                    final teacherName = teacherNameController.text.trim();
                    if (teacherName.isNotEmpty) {
<<<<<<< HEAD
                      await _setGlobalTeacherName(courseId, teacherName);
=======
                      ref
                          .read(timetableProvider.notifier)
                          .setTeacherName(courseId, teacherName);
                    } else {
                      ref
                          .read(timetableProvider.notifier)
                          .removeTeacherName(courseId); // 教員名が空の場合削除
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
                    }

                    Navigator.of(context).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

<<<<<<< HEAD
  // 教員名を取得
  Future<String> _getGlobalTeacherName(String courseId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .collection('meta')
            .doc('info')
            .get();
    return doc.data()?['teacherName'] ?? '';
  }

  // 教員名を保存
  Future<void> _setGlobalTeacherName(
    String courseId,
    String teacherName,
  ) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('meta')
        .doc('info')
        .set({'teacherName': teacherName}, SetOptions(merge: true));
  }

  Future<TimeOfDay?> pickTime(
    BuildContext context,
    TimeOfDay initialTime,
  ) async {
    if (Platform.isIOS) {
      TimeOfDay? picked;
      DateTime tempDateTime = DateTime(
        2023,
        1,
        1,
        initialTime.hour,
        initialTime.minute,
      );
      await showModalBottomSheet(
        context: context,
        builder: (context) {
          DateTime selectedDateTime = tempDateTime;
          return Container(
            height: 250,
            child: Column(
              children: [
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: tempDateTime,
                    onDateTimeChanged: (DateTime newTime) {
                      selectedDateTime = newTime;
                      picked = TimeOfDay(
                        hour: newTime.hour,
                        minute: newTime.minute,
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('完了'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
      return picked;
    } else {
      return await showTimePicker(context: context, initialTime: initialTime);
    }
  }
=======
  // ★追加するメソッド：FCM初期化とトークン保存、出欠カウント購読
  Future<void> _initializeFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
      String? token = await messaging.getToken();
      print('FCM Token: $token');

      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          _saveFCMTokenToFirestore(user.uid, token);
        }
      });

    } else {
      print('User declined or has not accepted notification permission');
    }
  }

  Future<void> _saveFCMTokenToFirestore(String uid, String? token) async {
    if (token == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('FCM Token saved to Firestore for user: $uid');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  void _listenToAttendanceCounts() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            if (mounted) {
              final Map<String, int> fetchedAbsence = Map<String, int>.from(
                  (data?['absenceCount'] as Map<String, dynamic>?)
                      ?.map((k, v) => MapEntry(k, v as int)) ?? {});
              final Map<String, int> fetchedLate = Map<String, int>.from(
                  (data?['lateCount'] as Map<String, dynamic>?)
                      ?.map((k, v) => MapEntry(k, v as int)) ?? {});

              ref.read(timetableProvider.notifier).updateAbsenceCount(fetchedAbsence);
              ref.read(timetableProvider.notifier).updateLateCount(fetchedLate);

              print('Attendance counts updated from Firestore: Absence=$fetchedAbsence, Late=$fetchedLate');
            }
          }
        });
      } else {
        if (mounted) {
          ref.read(timetableProvider.notifier).updateAbsenceCount({});
          ref.read(timetableProvider.notifier).updateLateCount({});
          print('User logged out. Attendance counts reset.');
        }
      }
    });
  }
>>>>>>> 939b5324a21a2f669460c73957ba967d8396a5e5
}

class SlantedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    final double slantAmount = size.height * 0.5;
    path.lineTo(size.width - slantAmount, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
} 