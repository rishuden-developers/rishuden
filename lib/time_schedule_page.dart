import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

enum AttendanceStatus { present, absent, late, none }

class TimeSchedulePage extends ConsumerStatefulWidget {
  const TimeSchedulePage({super.key});
  @override
  ConsumerState<TimeSchedulePage> createState() => _TimeSchedulePageState();
}

class _TimeSchedulePageState extends ConsumerState<TimeSchedulePage> {
  late PageController _pageController;
  static const int _initialPage = 5000; // 無限スクロールのための開始ページ

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
  Map<String, int> _absenceCount = {};
  Map<String, int> _lateCount = {};
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

  // ★★★ グローバルなcourseId管理 ★★★
  static Map<String, String> _globalSubjectToCourseId = {};
  static int _globalCourseIdCounter = 0;

  // ★★★ courseIdをTimetableProviderから取得するメソッドを追加 ★★★
  Map<String, String> get courseIds =>
      ref.watch(timetableProvider)['courseIds'] ?? {};

  // ★★★ courseIdをTimetableProviderに保存するメソッドを追加 ★★★
  void _updateCourseIds(Map<String, String> courseIds) {
    ref.read(timetableProvider.notifier).updateCourseIds(courseIds);
  }

  // データの取得メソッド（UIは変更しない）
  Map<String, String> get cellNotes =>
      ref.watch(timetableProvider)['cellNotes'] ?? {};
  Map<String, String> get weeklyNotes =>
      ref.watch(timetableProvider)['weeklyNotes'] ?? {};
  Map<String, String> get attendancePolicies =>
      ref.watch(timetableProvider)['attendancePolicies'] ?? {};
  Map<String, Map<String, String>> get attendanceStatus =>
      ref.watch(timetableProvider)['attendanceStatus'] ?? {};
  Map<String, int> get absenceCount =>
      ref.watch(timetableProvider)['absenceCount'] ?? {};
  Map<String, int> get lateCount =>
      ref.watch(timetableProvider)['lateCount'] ?? {};

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
      ref.watch(timetableProvider)['teacherNames'] ?? {};

  // 時間割データを読み込み
  void _loadTimetableData() {
    print('Loading timetable data from Firebase...');
    ref.read(timetableProvider.notifier).loadFromFirestore();

    // ★★★ 保存されたcourseIdを読み込んで復元 ★★★
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedCourseIds = courseIds;
      if (savedCourseIds.isNotEmpty) {
        // _globalSubjectToCourseIdに復元
        _globalSubjectToCourseId.clear();
        _globalSubjectToCourseId.addAll(savedCourseIds);

        // globalCourseMappingProviderにも復元（正規化された授業名で）
        final globalMappingNotifier = ref.read(
          globalCourseMappingProvider.notifier,
        );
        for (var entry in savedCourseIds.entries) {
          final normalizedName = globalMappingNotifier.normalizeSubjectName(
            entry.key,
          );
          globalMappingNotifier.addCourseMapping(normalizedName, entry.value);
        }

        print('DEBUG: 保存されたcourseIdを復元しました: $_globalSubjectToCourseId');
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
    _loadTimetableData();
  }

  Future<void> _fetchCharacterInfoFromFirebase() async {
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
    final savedCourseIds = courseIds;

    for (var entry in timeTableEntries) {
      String courseId;

      // 保存されたcourseIdがある場合はそれを使用
      if (savedCourseIds.containsKey(entry.subjectName)) {
        courseId = savedCourseIds[entry.subjectName]!;
        print('DEBUG: 保存されたcourseIdを使用: ${entry.subjectName} -> $courseId');
      } else {
        // 保存されていない場合は新しく生成
        courseId = ref
            .read(globalCourseMappingProvider.notifier)
            .getOrCreateCourseId(entry.subjectName);
        print('DEBUG: 新しいcourseIdを生成: ${entry.subjectName} -> $courseId');
      }

      entry.courseId = courseId;
      courseIdMap[entry.subjectName] = courseId;

      // ★★★ 新しい授業にデフォルトの出席方針を設定 ★★★
      final currentPolicies = Map<String, String>.from(attendancePolicies);
      if (!currentPolicies.containsKey(courseId)) {
        currentPolicies[courseId] = AttendancePolicy.mandatory.toString();
        _updateAttendancePolicies(currentPolicies);
        print(
          'DEBUG: 新しい授業 "${entry.subjectName}" -> courseId: $courseId -> デフォルト出席方針: mandatory',
        );
      }

      print('DEBUG: ${entry.subjectName} -> courseId: ${entry.courseId}');
    }

    // ★★★ courseIdをTimetableProviderに保存 ★★★
    _updateCourseIds(courseIdMap);

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

  void _setAttendanceStatus(
    String uniqueKey,
    String courseId,
    AttendanceStatus status,
  ) {
    setState(() {
      // ★★★ 新しい構造を使用：courseIdと日付で出席状態を管理 ★★★
      final date = DateFormat('yyyyMMdd').format(
        _displayedMonday.add(
          Duration(days: _getDayIndexFromUniqueKey(uniqueKey)),
        ),
      );

      // Providerの新しいメソッドを使用
      if (status == AttendanceStatus.none) {
        // 出席状態を削除
        ref
            .read(timetableProvider.notifier)
            .setAttendanceStatus(courseId, date, '');
      } else {
        // 出席状態を設定
        ref
            .read(timetableProvider.notifier)
            .setAttendanceStatus(courseId, date, status.toString());
      }

      // courseId を使って欠席・遅刻をカウント
      final currentStatus = ref
          .read(timetableProvider.notifier)
          .getAttendanceStatus(courseId, date);
      final oldStatus =
          currentStatus != null
              ? AttendanceStatus.values.firstWhere(
                (e) => e.toString() == currentStatus,
              )
              : AttendanceStatus.none;

      if (oldStatus != AttendanceStatus.absent &&
          status == AttendanceStatus.absent) {
        final newAbsenceCount = Map<String, int>.from(absenceCount);
        newAbsenceCount[courseId] = (newAbsenceCount[courseId] ?? 0) + 1;
        _updateAbsenceCount(newAbsenceCount);
      } else if (oldStatus == AttendanceStatus.absent &&
          status != AttendanceStatus.absent) {
        final newAbsenceCount = Map<String, int>.from(absenceCount);
        newAbsenceCount[courseId] = (newAbsenceCount[courseId] ?? 1) - 1;
        _updateAbsenceCount(newAbsenceCount);
      }
      if (oldStatus != AttendanceStatus.late &&
          status == AttendanceStatus.late) {
        final newLateCount = Map<String, int>.from(lateCount);
        newLateCount[courseId] = (newLateCount[courseId] ?? 0) + 1;
        _updateLateCount(newLateCount);
      } else if (oldStatus == AttendanceStatus.late &&
          status != AttendanceStatus.late) {
        final newLateCount = Map<String, int>.from(lateCount);
        newLateCount[courseId] = (newLateCount[courseId] ?? 1) - 1;
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
      final date = DateFormat('yyyyMMdd').parse(dateStr);
      return date.difference(_displayedMonday).inDays;
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
    final int absenceCount = this.absenceCount[courseId] ?? 0;
    final int lateCount = this.lateCount[courseId] ?? 0;
    final double warningLevel = (absenceCount * 1.0) + (lateCount * 0.5);
    final double t = (warningLevel / 3.0).clamp(0.0, 1.0);
    final warningColor = Colors.redAccent[400]!;
    return Color.lerp(baseColor, warningColor, t)!;
  }

  // ★★★ このメソッドを、以下の完成版に丸ごと置き換えてください ★★★

  List<Widget> _buildClassEntriesAsPositioned(
    int dayIndex,
    double totalHeight,
  ) {
    List<Widget> positionedWidgets = [];
    if (_timetableGrid.isEmpty || dayIndex >= _timetableGrid.length) {
      return positionedWidgets;
    }

    final double rowHeight = totalHeight / 8.0;

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

      final int absenceCount = this.absenceCount[entry.courseId] ?? 0;
      final int lateCount = this.lateCount[entry.courseId] ?? 0;
      final bool hasCount = absenceCount > 0 || lateCount > 0;
      final String noteText = _getNoteForCell(
        dayIndex,
        periodIndex: periodIndex,
      );

      final classWidget = Container(
        margin: const EdgeInsets.all(0.5),
        padding: const EdgeInsets.fromLTRB(6, 5, 4, 3),
        decoration: decoration,
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
                // 教員名を表示
                if (entry.courseId != null &&
                    teacherNames[entry.courseId] != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    teacherNames[entry.courseId]!,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // ★★★ ここからが修正箇所 ★★★
                if (hasCount) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (absenceCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[900]?.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cancel,
                                color: Colors.red[200],
                                size: 9,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$absenceCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (absenceCount > 0 && lateCount > 0)
                        const SizedBox(width: 3),
                      if (lateCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[900]?.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.watch_later,
                                color: Colors.orange[200],
                                size: 9,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$lateCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                // ★★★ ここまでが修正箇所 ★★★
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (entry.classroom.isNotEmpty)
                            Text(
                              entry.classroom,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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

  // ★★★ このメソッドを、以下の完成版に丸ごと置き換えてください ★★★

  List<Widget> _buildWeekdayEventsAsPositioned(
    int dayIndex,
    double totalHeight,
  ) {
    List<Widget> positionedWidgets = [];
    final double totalMinutes = (20 * 60 + 0) - (8 * 60 + 50);

    if (!_weekdayEvents.containsKey(dayIndex)) {
      return positionedWidgets;
    }

    // ★★★ 表示する週の日付を取得 ★★★
    final DateTime currentDay = _displayedMonday.add(Duration(days: dayIndex));

    // ★★★ 毎週の予定と、今週の予定のみをフィルタリング ★★★
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

      final startMinutes =
          (startTime.hour * 60 + startTime.minute) - (8 * 60 + 50);
      final endMinutes = (endTime.hour * 60 + endTime.minute) - (8 * 60 + 50);
      final top = (startMinutes / totalMinutes) * totalHeight;
      final height = ((endMinutes - startMinutes) / totalMinutes) * totalHeight;
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
            // ★ InkWellで囲んでタップできるようにする
            onTap: () {
              // 新しい編集ダイアログを呼び出す
              _showEditWeekdayEventDialog(
                dayIndex,
                eventsToShow.indexOf(event),
              );
            },
            child: eventWidget,
          ),
        ),
      );
    }
    return positionedWidgets;
  }
  // ★★★ このメソッドをクラス内に丸ごと追加してください ★★★

  Future<void> _showEditWeekdayEventDialog(
    int dayIndex,
    int eventIndex, {
    TimeOfDay? newEventStartTime,
  }) async {
    final eventToEdit =
        eventIndex != -1 ? _weekdayEvents[dayIndex]![eventIndex] : null;

    final titleController = TextEditingController(
      text: eventToEdit?['title'] ?? '',
    );
    TimeOfDay startTime;
    TimeOfDay endTime;
    bool isWeekly;

    if (eventIndex == -1) {
      // 新規作成
      startTime = newEventStartTime ?? TimeOfDay.now();
      final endHour = startTime.hour + 1;
      endTime = TimeOfDay(
        hour: endHour > 23 ? 23 : endHour,
        minute: endHour > 23 ? 59 : startTime.minute,
      );
      isWeekly = false;
      titleController.text = '';
    } else {
      // 編集
      startTime = eventToEdit!['start'];
      endTime = eventToEdit['end'];
      isWeekly = eventToEdit['isWeekly'];
    }

    final String? initialTitle = eventToEdit?['title'];
    final TimeOfDay initialStartTime = eventToEdit?['start'] ?? startTime;
    final TimeOfDay initialEndTime = eventToEdit?['end'] ?? endTime;
    final bool initialIsWeekly = eventToEdit?['isWeekly'] ?? isWeekly;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ★★★ 変更検知ロジック ★★★
            final isTitleValid = titleController.text.isNotEmpty;
            final isTimeValid =
                (endTime.hour * 60 + endTime.minute) >
                (startTime.hour * 60 + startTime.minute);
            final hasChanged =
                titleController.text != initialTitle ||
                startTime != initialStartTime ||
                endTime != initialEndTime ||
                isWeekly != initialIsWeekly;
            final canSave = isTitleValid && isTimeValid && hasChanged;

            // ★★★ テキスト変更時にUIを更新 ★★★
            titleController.addListener(() {
              setDialogState(() {});
            });

            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 22, 22, 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Text(
                '${_days[dayIndex]}の予定',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'misaki',
                ),
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
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setDialogState(() => startTime = picked);
                          }
                        },
                        child: Text(
                          "開始: ${startTime.format(context)}",
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
                            initialTime: endTime,
                          );
                          if (picked != null) {
                            setDialogState(() => endTime = picked);
                          }
                        },
                        child: Text(
                          "終了: ${endTime.format(context)}",
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
                if (eventIndex != -1)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('delete'),
                    child: const Text(
                      '削除',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed:
                      canSave
                          ? () => Navigator.of(context).pop('update')
                          : null,
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

    if (result == 'update') {
      setState(() {
        if (_weekdayEvents[dayIndex] == null) {
          _weekdayEvents[dayIndex] = [];
        }
        if (eventIndex == -1) {
          _weekdayEvents[dayIndex]!.add({
            'title': titleController.text,
            'start': startTime,
            'end': endTime,
            'isWeekly': isWeekly,
            'date': _displayedMonday.add(Duration(days: dayIndex)),
          });
        } else {
          _weekdayEvents[dayIndex]![eventIndex] = {
            'title': titleController.text,
            'start': startTime,
            'end': endTime,
            'isWeekly': isWeekly,
            'date': _weekdayEvents[dayIndex]![eventIndex]['date'],
          };
        }
        _weekdayEvents[dayIndex]!.sort(
          (a, b) => (a['start'] as TimeOfDay).hour.compareTo(
            (b['start'] as TimeOfDay).hour,
          ),
        );
      });
    } else if (result == 'delete') {
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('予定を削除'),
              content: const Text('この予定を削除しますか？'),
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
            ),
      );
      if (confirmDelete == true) {
        setState(() {
          _weekdayEvents[dayIndex]!.removeAt(eventIndex);
        });
      }
    }
  }

  // ★★★ このメソッドを、以下の完成版に丸ごと置き換えてください ★★★
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
            const double timetableStartInMinutes = 8 * 60 + 50;
            const double timetableEndInMinutes = 20 * 60 + 0;
            const double totalMinutesInTimetable =
                timetableEndInMinutes - timetableStartInMinutes;
            final double minutesFromTop =
                (tappedY / totalHeight) * totalMinutesInTimetable;
            double totalMinutesFromMidnight =
                minutesFromTop + timetableStartInMinutes;
            if (totalMinutesFromMidnight > timetableEndInMinutes - 60) {
              totalMinutesFromMidnight = timetableEndInMinutes - 60;
            }
            // ★★★ 開始時刻を一番近い30分単位に丸める ★★★
            final double roundedTotalMinutes =
                (totalMinutesFromMidnight / 30).round() * 30.0;
            int hour = roundedTotalMinutes.toInt() ~/ 60;
            int minute = roundedTotalMinutes.toInt() % 60;

            final startTime = TimeOfDay(hour: hour, minute: minute);
            _showSundayEventDialog(newEventStartTime: startTime);
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

              // 行インデックスを時間割の時限インデックスに変換
              int periodIndex;
              if (tappedRowIndex < 2) {
                periodIndex = tappedRowIndex; // 1限、2限
              } else if (tappedRowIndex == 2) {
                return; // 昼休みは無視
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
              const double timetableStartInMinutes = 8 * 60 + 50;
              const double timetableEndInMinutes = 20 * 60 + 0;
              const double totalMinutesInTimetable =
                  timetableEndInMinutes - timetableStartInMinutes;
              final double minutesFromTop =
                  (tappedY / totalHeight) * totalMinutesInTimetable;
              double totalMinutesFromMidnight =
                  minutesFromTop + timetableStartInMinutes;

              if (totalMinutesFromMidnight > timetableEndInMinutes - 60) {
                totalMinutesFromMidnight = timetableEndInMinutes - 60;
              }
              // ★★★ 開始時刻を一番近い30分単位に丸める ★★★
              final double roundedTotalMinutes =
                  (totalMinutesFromMidnight / 30).round() * 30.0;
              int hour = roundedTotalMinutes.toInt() ~/ 60;
              int minute = roundedTotalMinutes.toInt() % 60;

              final startTime = TimeOfDay(hour: hour, minute: minute);
              _showEditWeekdayEventDialog(
                dayIndex,
                -1,
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
              content: Column(
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
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: startTime ?? TimeOfDay.now(),
                          );
                          if (picked != null)
                            setDialogState(() => startTime = picked);
                        },
                        child: Text(
                          "開始: ${startTime?.format(context) ?? '未選択'}",
                          style: const TextStyle(
                            color: Colors.tealAccent,
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
                          if (picked != null)
                            setDialogState(() => endTime = picked);
                        },
                        child: Text(
                          "終了: ${endTime?.format(context) ?? '未選択'}",
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

  Future<void> _showNoteDialog(
    BuildContext context,
    int dayIndex, {
    int? academicPeriodIndex,
  }) async {
    TimetableEntry? entry;
    if (academicPeriodIndex != null) {
      entry = _timetableGrid[dayIndex][academicPeriodIndex];
    } else {
      return;
    }

    // ★★★ uniqueKeyをcourseIdベースに変更 ★★★
    final String oneTimeNoteKey;
    if (entry?.courseId != null) {
      oneTimeNoteKey =
          "${entry!.courseId}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
    } else {
      // 後方互換性のため、courseIdがない場合は古い形式を使用
      oneTimeNoteKey =
          "C_${dayIndex}_${academicPeriodIndex}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
    }
    final String weeklyNoteKey;
    if (entry?.courseId != null) {
      weeklyNoteKey = "W_${entry!.courseId}";
    } else {
      // 後方互換性のため、courseIdがない場合は古い形式を使用
      weeklyNoteKey = "W_C_${dayIndex}_$academicPeriodIndex";
    }

    final String initialText =
        cellNotes[oneTimeNoteKey] ?? weeklyNotes[weeklyNoteKey] ?? '';
    final bool isInitiallyWeekly =
        weeklyNotes.containsKey(weeklyNoteKey) &&
        !cellNotes.containsKey(oneTimeNoteKey);
    // ★★★ 出席方針の初期値もcourseIdベースで取得 ★★★
    String? initialPolicyString;
    if (entry?.courseId != null) {
      initialPolicyString = attendancePolicies[entry!.courseId];
    }
    if (initialPolicyString == null && entry?.id != null) {
      initialPolicyString = attendancePolicies[entry!.id];
    }
    initialPolicyString ??= AttendancePolicy.flexible.toString();

    final AttendancePolicy initialPolicy = AttendancePolicy.values.firstWhere(
      (p) => p.toString() == initialPolicyString,
      orElse: () => AttendancePolicy.flexible,
    );

    TextEditingController noteController = TextEditingController(
      text: initialText,
    );
    bool isWeekly = isInitiallyWeekly;
    AttendancePolicy selectedPolicy = initialPolicy;

    // 教員名コントローラーを追加
    final teacherNameController = TextEditingController(
      text: entry?.courseId != null ? teacherNames[entry!.courseId] ?? '' : '',
    );

    bool? noteWasSaved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ★★★ 変更を検知するためのロジックを追加 ★★★
            final bool hasChanged =
                noteController.text != initialText ||
                isWeekly != isInitiallyWeekly ||
                selectedPolicy != initialPolicy ||
                teacherNameController.text.trim() !=
                    (entry?.courseId != null
                        ? teacherNames[entry!.courseId] ?? ''
                        : '');

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
                    style: TextStyle(
                      fontFamily: 'misaki',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${entry?.subjectName ?? ''} (${entry?.originalLocation ?? ''})",
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
                    // 教員名入力フィールドを追加
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        bottom: 8.0,
                        left: 4.0,
                      ),
                      child: Text(
                        "教員名:",
                        style: TextStyle(
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
                        style: TextStyle(
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
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    disabledBackgroundColor: Colors.grey[800],
                  ),
                  child: Text(
                    '保存',
                    style: TextStyle(fontFamily: 'misaki', color: Colors.black),
                  ),
                  onPressed:
                      hasChanged
                          ? () => Navigator.of(dialogContext).pop(true)
                          : null,
                ),
              ],
            );
          },
        );
      },
    );

    if (noteWasSaved == true) {
      final currentEntry = entry;
      if (currentEntry != null) {
        final newText = noteController.text.trim();

        // ★★★ メモ保存ロジックを全面的に修正 ★★★
        final newCellNotes = Map<String, String>.from(cellNotes);
        final newWeeklyNotes = Map<String, String>.from(weeklyNotes);

        if (newText.isEmpty) {
          // テキストが空なら両方のメモを削除
          newCellNotes.remove(oneTimeNoteKey);
          newWeeklyNotes.remove(weeklyNoteKey);
        } else {
          if (isWeekly) {
            // 「毎週」がオンの場合
            newWeeklyNotes[weeklyNoteKey] = newText; // 週次メモとして保存
            newCellNotes.remove(oneTimeNoteKey); // その日のメモは削除
          } else {
            // 「毎週」がオフの場合
            newCellNotes[oneTimeNoteKey] = newText; // その日のメモとして保存
            newWeeklyNotes.remove(weeklyNoteKey); // 週次メモは削除
          }
        }

        // 更新されたマップでStateを更新
        _updateCellNotes(newCellNotes);
        _updateWeeklyNotes(newWeeklyNotes);

        if (currentEntry.courseId != null) {
          _updateAttendancePolicies({
            ...attendancePolicies,
            currentEntry.courseId!: selectedPolicy.toString(),
          });

          // 教員名を保存（空でも保存してクリアできるようにする）
          final teacherName = teacherNameController.text.trim();
          ref
              .read(timetableProvider.notifier)
              .setTeacherName(currentEntry.courseId!, teacherName);
        }
      }
    }
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
    String? policyString = attendancePolicies[entry.courseId];
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
        .getAttendanceStatus(entry.courseId ?? '', date);
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
        onSelected: (AttendanceStatus newStatus) {
          if (entry.courseId != null) {
            _setAttendanceStatus(uniqueKey, entry.courseId!, newStatus);
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
    final int totalMinutes = (20 * 60 + 0) - (8 * 60 + 50);
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
      final double startMinutes =
          (startTime.hour * 60 + startTime.minute) - (8 * 60 + 50);
      final double endMinutes =
          (endTime.hour * 60 + endTime.minute) - (8 * 60 + 50);
      if (startMinutes < 0 || endMinutes > totalMinutes) continue;
      final double top = (startMinutes / totalMinutes) * totalHeight;
      final double height =
          ((endMinutes - startMinutes) / totalMinutes) * totalHeight;
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

  // ★★★ このメソッドを、以下の完成版に丸ごと置き換えてください ★★★
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
    final teacherNameController = TextEditingController(
      text: teacherNames[courseId] ?? '',
    );

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
                      decoration: InputDecoration(
                        labelText: 'メモ',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: attendancePolicy,
                      decoration: InputDecoration(
                        labelText: '出席ポリシー',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'flexible', child: Text('柔軟')),
                        DropdownMenuItem(value: 'mandatory', child: Text('必須')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          // StatefulBuilder内での状態更新
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: teacherNameController,
                      decoration: InputDecoration(
                        labelText: '教員名',
                        border: OutlineInputBorder(),
                        hintText: '例: 田中太郎',
                      ),
                    ),
                    SizedBox(height: 16),
                    // 出席ボタン
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final uniqueKey =
                                "${courseId}_${DateFormat('yyyyMMdd').format(_displayedMonday)}";
                            _setAttendanceStatus(
                              uniqueKey,
                              courseId,
                              AttendanceStatus.present,
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('出席'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final uniqueKey =
                                "${courseId}_${DateFormat('yyyyMMdd').format(_displayedMonday)}";
                            _setAttendanceStatus(
                              uniqueKey,
                              courseId,
                              AttendanceStatus.absent,
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('欠席'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final uniqueKey =
                                "${courseId}_${DateFormat('yyyyMMdd').format(_displayedMonday)}";
                            _setAttendanceStatus(
                              uniqueKey,
                              courseId,
                              AttendanceStatus.late,
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('遅刻'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // 出席状況表示
                    Text(
                      '出席: ${absenceCount[courseId] ?? 0} | 欠席: ${absenceCount[courseId] ?? 0} | 遅刻: ${lateCount[courseId] ?? 0}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
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

                    // 教員名を保存
                    final teacherName = teacherNameController.text.trim();
                    if (teacherName.isNotEmpty) {
                      ref
                          .read(timetableProvider.notifier)
                          .setTeacherName(courseId, teacherName);
                    }

                    Navigator.of(context).pop();
                  },
                  child: Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }
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
