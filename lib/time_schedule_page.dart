import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'character_provider.dart';

// 共通フッターと遷移先ページのインポート
import 'common_bottom_navigation.dart';
import 'park_page.dart';
import 'credit_review_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';

// データモデル定義
enum AttendancePolicy { mandatory, flexible, skip, none }

class TimetableEntry {
  final String id;
  final String subjectName;
  final String classroom;
  final int dayOfWeek;
  final int period;
  final Color color;
  final AttendancePolicy initialPolicy;

  TimetableEntry({
    required this.id,
    required this.subjectName,
    required this.classroom,
    required this.dayOfWeek,
    required this.period,
    this.color = Colors.white,
    this.initialPolicy = AttendancePolicy.none,
  });
}

enum AttendanceStatus { present, absent, late, none }

// モックデータ
final List<TimetableEntry> mockTimetable = [
  TimetableEntry(
    id: '1',
    subjectName: "微分積分学I",
    classroom: "A-101",
    dayOfWeek: 0,
    period: 1,
    color: Colors.lightBlue[100]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '2',
    subjectName: "プログラミング基礎",
    classroom: "B-203",
    dayOfWeek: 0,
    period: 2,
    color: Colors.greenAccent[100]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '3',
    subjectName: "文学史",
    classroom: "共通C301",
    dayOfWeek: 0,
    period: 4,
    color: Colors.amber[200]!,
    initialPolicy: AttendancePolicy.flexible,
  ),
  TimetableEntry(
    id: '12',
    subjectName: "特別講義X",
    classroom: "大講義室",
    dayOfWeek: 0,
    period: 6,
    color: Colors.grey[300]!,
  ),
  TimetableEntry(
    id: '4',
    subjectName: "線形代数学",
    classroom: "A-102",
    dayOfWeek: 1,
    period: 1,
    color: Colors.orangeAccent[100]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '5',
    subjectName: "英語コミュニケーション",
    classroom: "C-301",
    dayOfWeek: 1,
    period: 3,
    color: Colors.purpleAccent[100]!,
  ),
  TimetableEntry(
    id: '6',
    subjectName: "経済学原論",
    classroom: "D-105",
    dayOfWeek: 2,
    period: 2,
    color: Colors.redAccent[100]!,
    initialPolicy: AttendancePolicy.flexible,
  ),
  TimetableEntry(
    id: '7',
    subjectName: "健康科学",
    classroom: "体育館",
    dayOfWeek: 2,
    period: 4,
    color: Colors.lime[200]!,
    initialPolicy: AttendancePolicy.skip,
  ),
  TimetableEntry(
    id: '8',
    subjectName: "実験物理学",
    classroom: "E-Lab1",
    dayOfWeek: 3,
    period: 3,
    color: Colors.tealAccent[100]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '9',
    subjectName: "実験物理学",
    classroom: "E-Lab1",
    dayOfWeek: 3,
    period: 4,
    color: Colors.tealAccent[100]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '13',
    subjectName: "ゼミ準備",
    classroom: "研究室A",
    dayOfWeek: 3,
    period: 6,
    color: Colors.brown[100]!,
  ),
  TimetableEntry(
    id: '10',
    subjectName: "キャリアデザイン",
    classroom: "講堂",
    dayOfWeek: 4,
    period: 5,
    color: Colors.pinkAccent[100]!,
    initialPolicy: AttendancePolicy.flexible,
  ),
  TimetableEntry(
    id: '11',
    subjectName: "第二外国語(独)",
    classroom: "F-202",
    dayOfWeek: 4,
    period: 2,
    color: Colors.indigo[100]!,
    initialPolicy: AttendancePolicy.skip,
  ),
  TimetableEntry(
    id: '14',
    subjectName: "統計学",
    classroom: "Z-101",
    dayOfWeek: 1,
    period: 2,
    color: Colors.cyan[100]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
];

class TimeSchedulePage extends StatefulWidget {
  const TimeSchedulePage({super.key});
  @override
  State<TimeSchedulePage> createState() => _TimeSchedulePageState();
}

class _TimeSchedulePageState extends State<TimeSchedulePage> {
  final List<String> _days = const ['月', '火', '水', '木', '金', '土', '日'];
  final int _academicPeriods = 6;
  String _mainCharacterName = 'キャラクター';
  String _mainCharacterImagePath = 'assets/character_unknown.png';
  List<List<TimetableEntry?>> _timetableGrid = [];
  Map<String, String> _cellNotes = {};
  Map<String, String> _weeklyNotes = {};
  Set<String> _cancellations = {};
  Map<String, AttendancePolicy> _attendancePolicies = {};
  final String _lunchPeriodKeyPrefix = "L_";
  final String _academicCellKeyPrefix = "C_";
  final String _afterSchoolKeyPrefix = "A_";
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
  final double _lunchRowHeight = 55.0;
  final List<List<String>> _periodTimes = const [
    ["8:50", "10:20"],
    ["10:30", "12:00"],
    ["13:30", "15:00"],
    ["15:10", "16:40"],
    ["16:50", "18:20"],
    ["18:30", "20:00"],
  ];
  Timer? _highlightTimer;
  int _currentDayIndex = -1;
  int _currentPeriodIndex = -1;
  bool _isLunchTime = false;
  Map<String, AttendanceStatus> _attendanceStatus = {};
  Map<String, int> _absenceCount = {};
  Map<String, int> _lateCount = {};
  late DateTime _displayedMonday;
  List<String> _dayDates = [];
  String _weekDateRange = "";
  List<Map<String, dynamic>> _sundayEvents = [];
  double _timeGaugeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonday = now.subtract(Duration(days: now.weekday - 1));
    final tuesdayDate = _displayedMonday.add(const Duration(days: 1));
    final cancellationKey = "14_${DateFormat('yyyyMMdd').format(tuesdayDate)}";
    _cancellations = {cancellationKey};
    _initializeTimetableGrid();
    _updateWeekDates();
    _updateHighlight();
    _highlightTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateHighlight();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final characterProvider = Provider.of<CharacterProvider>(context);
    bool characterInfoChanged = false;
    if (_mainCharacterName != characterProvider.characterName ||
        _mainCharacterImagePath != characterProvider.characterImage) {
      _mainCharacterName = characterProvider.characterName;
      _mainCharacterImagePath = characterProvider.characterImage;
      characterInfoChanged = true;
    }
    if (_displayedCharacters.isEmpty || characterInfoChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _placeCharactersRandomly();
          });
        }
      });
    }
  }

  // ★★★ このメソッドを丸ごと追加 ★★★
  // ★★★ このメソッドを丸ごと置き換え ★★★
  // ★★★ このメソッドを丸ごと置き換えてください ★★★
  double _calculateActiveTimeProgress(DateTime now) {
    // 授業コマの時間定義 [開始(分), 終了(分), このブロックの長さ(分)]
    final classBlocks = [
      [8 * 60 + 50, 10 * 60 + 20, 90.0], // 1限
      [10 * 60 + 30, 12 * 60 + 0, 90.0], // 2限
      [13 * 60 + 30, 15 * 60 + 0, 90.0], // 3限
      [15 * 60 + 10, 16 * 60 + 40, 90.0], // 4限
      [16 * 50 + 50, 18 * 60 + 20, 90.0], // 5限
      [18 * 60 + 30, 20 * 60 + 0, 90.0], // 6限
    ];

    final double totalActiveMinutes = 540.0;
    double elapsedActiveMinutes = 0;
    bool timeFound = false;
    final double currentTimeInMinutes = now.hour * 60.0 + now.minute;

    if (currentTimeInMinutes < classBlocks.first[0]) return 0.0;

    if (currentTimeInMinutes >= classBlocks.last[1]) {
      timeFound = false;
    } else {
      for (int i = 0; i < classBlocks.length; i++) {
        final block = classBlocks[i];
        // ★★★ ここで .toDouble() を追加して型を変換 ★★★
        final double blockStart = block[0].toDouble();
        final double blockEnd = block[1].toDouble();
        final double blockDuration = block[2].toDouble();

        if (i > 0 &&
            currentTimeInMinutes > classBlocks[i - 1][1] &&
            currentTimeInMinutes < blockStart) {
          timeFound = true;
          break;
        }

        if (currentTimeInMinutes >= blockStart &&
            currentTimeInMinutes <= blockEnd) {
          elapsedActiveMinutes += (currentTimeInMinutes - blockStart);
          timeFound = true;
          break;
        }

        elapsedActiveMinutes += blockDuration;
      }
    }

    final double classTimeHeightRatio =
        (_periodRowHeight * 6 + _lunchRowHeight) /
        (_periodRowHeight * 6 + _lunchRowHeight * 2);

    if (timeFound) {
      return (elapsedActiveMinutes / totalActiveMinutes) * classTimeHeightRatio;
    } else {
      final double afterClassStart = 20 * 60.0;
      final double afterClassEnd = 24 * 60.0;
      if (currentTimeInMinutes >= afterClassEnd) return 1.0;
      if (currentTimeInMinutes < afterClassStart) {
        // 20時より前で、授業も休憩時間でもない場合（＝6限終了直後など）
        return classTimeHeightRatio;
      }

      final double afterClassDuration = afterClassEnd - afterClassStart;
      final double afterClassElapsed = currentTimeInMinutes - afterClassStart;

      final double afterClassPortion = 1.0 - classTimeHeightRatio;
      return classTimeHeightRatio +
          (afterClassElapsed / afterClassDuration) * afterClassPortion;
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
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
    if (mounted) {
      setState(() {});
    }
  }

  void _goToPreviousWeek() {
    _displayedMonday = _displayedMonday.subtract(const Duration(days: 7));
    _updateWeekDates();
  }

  void _goToNextWeek() {
    _displayedMonday = _displayedMonday.add(const Duration(days: 7));
    _updateWeekDates();
  }

  // ★★★ このメソッドを丸ごと置き換えてください ★★★
  void _updateHighlight() {
    final now = DateTime.now();

    // --- 現在のコマをハイライトする処理 (これは変更なし) ---
    final day = now.weekday;
    final currentTime = now.hour * 100 + now.minute;
    int newDayIndex = -1;
    int newPeriodIndex = -1;
    bool newIsLunchTime = false;

    if (day >= 1 && day <= 6) {
      newDayIndex = day - 1;
      if (currentTime >= 850 && currentTime <= 1020)
        newPeriodIndex = 0;
      else if (currentTime >= 1030 && currentTime <= 1200)
        newPeriodIndex = 1;
      else if (currentTime > 1200 && currentTime < 1330)
        newIsLunchTime = true;
      else if (currentTime >= 1330 && currentTime <= 1500)
        newPeriodIndex = 2;
      else if (currentTime >= 1510 && currentTime <= 1640)
        newPeriodIndex = 3;
      else if (currentTime >= 1650 && currentTime <= 1820)
        newPeriodIndex = 4;
      else if (currentTime >= 1830 && currentTime <= 2000)
        newPeriodIndex = 5;
      else {
        newDayIndex = -1;
      }
    }
    if (newDayIndex != _currentDayIndex ||
        newPeriodIndex != _currentPeriodIndex ||
        newIsLunchTime != _isLunchTime) {
      if (mounted) {
        setState(() {
          _currentDayIndex = newDayIndex;
          _currentPeriodIndex = newPeriodIndex;
          _isLunchTime = newIsLunchTime;
        });
      }
    }

    // --- ★★★ ここからがゲージの進捗計算部分 ★★★ ---
    // 以前の複雑な計算ロジックを削除し、新しい関数を呼び出すだけにする
    final newProgress = _calculateActiveTimeProgress(now);

    if (_timeGaugeProgress != newProgress && mounted) {
      setState(() {
        _timeGaugeProgress = newProgress;
      });
    }
  }

  void _initializeTimetableGrid() {
    _timetableGrid = List.generate(
      _days.length,
      (dayIndex) => List.generate(_academicPeriods, (periodIndex) => null),
    );
    for (var entry in mockTimetable) {
      if (entry.dayOfWeek >= 0 &&
          entry.dayOfWeek < _days.length &&
          entry.period > 0 &&
          entry.period <= _academicPeriods) {
        _timetableGrid[entry.dayOfWeek][entry.period - 1] = entry;
        _attendancePolicies[entry.id] = entry.initialPolicy;
      }
    }
  }

  void _placeCharactersRandomly() {
    List<Map<String, String>> newCharacterList = [];
    List<Map<String, int>> availableEmptyCells = [];
    if (_timetableGrid.isEmpty && mockTimetable.isNotEmpty) {
      _initializeTimetableGrid();
    }
    for (int day = 0; day < 6; day++) {
      for (int period = 0; period < _academicPeriods; period++) {
        String noteText = _getNoteForCell(day, periodIndex: period);
        if (_timetableGrid[day][period] == null && noteText.isEmpty) {
          availableEmptyCells.add({'day': day, 'period': period});
        }
      }
    }
    availableEmptyCells.shuffle();
    final random = Random();
    if (availableEmptyCells.isNotEmpty &&
        _mainCharacterImagePath.isNotEmpty &&
        _mainCharacterImagePath != 'assets/character_unknown.png') {
      final mainCharPos = availableEmptyCells.removeAt(0);
      newCharacterList.add({
        'path': _mainCharacterImagePath,
        'day': mainCharPos['day'].toString(),
        'period': mainCharPos['period'].toString(),
      });
    }
    List<String> additionalCharacterPool = List<String>.from(
      _otherCharacterImagePaths,
    );
    additionalCharacterPool.remove(_mainCharacterImagePath);
    additionalCharacterPool.shuffle();
    int addedCharactersCount = 0;
    for (String charPath in additionalCharacterPool) {
      if (addedCharactersCount >= 2 || availableEmptyCells.isEmpty) {
        break;
      }
      bool shouldPlaceThisRareChar = true;
      if (charPath == 'assets/character_god.png' ||
          charPath == 'assets/character_takuji.png') {
        if (random.nextDouble() > 0.3) {
          shouldPlaceThisRareChar = false;
        }
      }
      if (shouldPlaceThisRareChar) {
        if (availableEmptyCells.isNotEmpty) {
          final additionalCharPos = availableEmptyCells.removeAt(0);
          newCharacterList.add({
            'path': charPath,
            'day': additionalCharPos['day'].toString(),
            'period': additionalCharPos['period'].toString(),
          });
          addedCharactersCount++;
        }
      }
    }
    _displayedCharacters = newCharacterList;
  }

  String _getNoteForCell(
    int dayIndex, {
    int? periodIndex,
    bool isAfterSchool = false,
  }) {
    String oneTimeNoteKey;
    String weeklyNoteKey;
    final DateTime cellDate = _displayedMonday.add(Duration(days: dayIndex));
    if (isAfterSchool) {
      oneTimeNoteKey =
          "${_afterSchoolKeyPrefix}${dayIndex}_${DateFormat('yyyyMMdd').format(cellDate)}";
      weeklyNoteKey = "W_A_$dayIndex";
    } else if (periodIndex != null) {
      oneTimeNoteKey =
          "${_academicCellKeyPrefix}${dayIndex}_${periodIndex}_${DateFormat('yyyyMMdd').format(cellDate)}";
      weeklyNoteKey = "W_C_${dayIndex}_$periodIndex";
    } else {
      oneTimeNoteKey =
          "${_lunchPeriodKeyPrefix}${dayIndex}_${DateFormat('yyyyMMdd').format(cellDate)}";
      weeklyNoteKey = "W_L_$dayIndex";
    }
    return _cellNotes[oneTimeNoteKey] ?? _weeklyNotes[weeklyNoteKey] ?? '';
  }

  Future<void> _showNoteDialog(
    BuildContext context,
    int dayIndex, {
    int? academicPeriodIndex,
    bool isAfterSchool = false,
  }) async {
    String weeklyNoteKey;
    String oneTimeNoteKey;
    String dialogTitle;
    TimetableEntry? entry;
    final DateTime cellDate = _displayedMonday.add(Duration(days: dayIndex));
    if (isAfterSchool) {
      weeklyNoteKey = "W_A_$dayIndex";
      oneTimeNoteKey =
          "${_afterSchoolKeyPrefix}${dayIndex}_${DateFormat('yyyyMMdd').format(cellDate)}";
      dialogTitle = "${_days[dayIndex]}曜日 放課後";
    } else if (academicPeriodIndex != null) {
      entry = _timetableGrid[dayIndex][academicPeriodIndex];
      weeklyNoteKey = "W_C_${dayIndex}_$academicPeriodIndex";
      oneTimeNoteKey =
          "${_academicCellKeyPrefix}${dayIndex}_${academicPeriodIndex}_${DateFormat('yyyyMMdd').format(cellDate)}";
      dialogTitle = "${_days[dayIndex]}曜 ${academicPeriodIndex + 1}限";
    } else {
      weeklyNoteKey = "W_L_$dayIndex";
      oneTimeNoteKey =
          "${_lunchPeriodKeyPrefix}${dayIndex}_${DateFormat('yyyyMMdd').format(cellDate)}";
      dialogTitle = "${_days[dayIndex]}曜日 昼休み";
    }
    final String initialText =
        _cellNotes[oneTimeNoteKey] ?? _weeklyNotes[weeklyNoteKey] ?? '';
    final bool isInitiallyWeekly =
        _weeklyNotes.containsKey(weeklyNoteKey) &&
        !_cellNotes.containsKey(oneTimeNoteKey);
    final AttendancePolicy initialPolicy =
        (entry != null)
            ? (_attendancePolicies[entry.id] ?? AttendancePolicy.none)
            : AttendancePolicy.none;
    TextEditingController noteController = TextEditingController(
      text: initialText,
    );
    bool isWeekly = isInitiallyWeekly;
    AttendancePolicy selectedPolicy = initialPolicy;
    bool? noteWasSaved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.brown[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Text(
                dialogTitle,
                style: TextStyle(
                  fontFamily: 'misaki',
                  fontSize: 16,
                  color: Colors.brown[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: noteController,
                      maxLines: 5,
                      minLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'この時間の予定やメモをどうぞ...',
                        hintStyle: TextStyle(color: Colors.brown[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange[700]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text(
                        "毎週のメモにする",
                        style: TextStyle(fontFamily: 'misaki', fontSize: 13),
                      ),
                      value: isWeekly,
                      onChanged:
                          (bool? value) =>
                              setDialogState(() => isWeekly = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (entry != null) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 8.0,
                          bottom: 8.0,
                          left: 4.0,
                        ),
                        child: Text(
                          "出席方針:",
                          style: TextStyle(fontFamily: 'misaki', fontSize: 13),
                        ),
                      ),
                      SegmentedButton<AttendancePolicy>(
                        segments: const <ButtonSegment<AttendancePolicy>>[
                          ButtonSegment<AttendancePolicy>(
                            value: AttendancePolicy.mandatory,
                            label: Text(
                              '毎回',
                              style: TextStyle(fontFamily: 'misaki'),
                            ),
                          ),
                          ButtonSegment<AttendancePolicy>(
                            value: AttendancePolicy.flexible,
                            label: Text(
                              '気分',
                              style: TextStyle(fontFamily: 'misaki'),
                            ),
                          ),
                          ButtonSegment<AttendancePolicy>(
                            value: AttendancePolicy.skip,
                            label: Text(
                              '切る',
                              style: TextStyle(fontFamily: 'misaki'),
                            ),
                          ),
                        ],
                        selected: {selectedPolicy},
                        onSelectionChanged: (
                          Set<AttendancePolicy> newSelection,
                        ) {
                          setDialogState(() {
                            selectedPolicy = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Colors.brown[100],
                          selectedBackgroundColor: Colors.orange[300],
                          selectedForegroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'キャンセル',
                    style: TextStyle(
                      fontFamily: 'misaki',
                      color: Colors.brown[600],
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontFamily: 'misaki', color: Colors.white),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        );
      },
    );
    if (noteWasSaved == true) {
      setState(() {
        if (entry != null) {
          _attendancePolicies[entry.id] = selectedPolicy;
        }
        final newText = noteController.text.trim();
        if (newText.isEmpty) {
          _cellNotes.remove(oneTimeNoteKey);
          _weeklyNotes.remove(weeklyNoteKey);
        } else {
          if (isWeekly) {
            _weeklyNotes[weeklyNoteKey] = newText;
            _cellNotes.remove(oneTimeNoteKey);
          } else {
            _cellNotes[oneTimeNoteKey] = newText;
            _weeklyNotes.remove(weeklyNoteKey);
          }
        }
        _placeCharactersRandomly();
      });
    }
  }

  void _setAttendanceStatus(
    String uniqueKey,
    String entryId,
    AttendanceStatus status,
  ) {
    setState(() {
      final oldStatus = _attendanceStatus[uniqueKey] ?? AttendanceStatus.none;
      final newStatus = (oldStatus == status) ? AttendanceStatus.none : status;
      _attendanceStatus[uniqueKey] = newStatus;
      if (oldStatus != AttendanceStatus.absent &&
          newStatus == AttendanceStatus.absent) {
        _absenceCount[entryId] = (_absenceCount[entryId] ?? 0) + 1;
      } else if (oldStatus == AttendanceStatus.absent &&
          newStatus != AttendanceStatus.absent) {
        _absenceCount[entryId] = (_absenceCount[entryId] ?? 1) - 1;
      }
      if (oldStatus != AttendanceStatus.late &&
          newStatus == AttendanceStatus.late) {
        _lateCount[entryId] = (_lateCount[entryId] ?? 0) + 1;
      } else if (oldStatus == AttendanceStatus.late &&
          newStatus != AttendanceStatus.late) {
        _lateCount[entryId] = (_lateCount[entryId] ?? 1) - 1;
      }
    });
  }

  Color _getWarningColor(int count, Color defaultColor) {
    if (count >= 3) return Colors.red[200]!;
    if (count == 2) return Colors.orange[200]!;
    if (count == 1) return Colors.yellow[200]!;
    return defaultColor;
  }

  Color _getColorForPolicy(AttendancePolicy policy, Color baseColor) {
    switch (policy) {
      case AttendancePolicy.mandatory:
        return baseColor;
      case AttendancePolicy.flexible:
        return Color.alphaBlend(Colors.white.withOpacity(0.3), baseColor);
      case AttendancePolicy.skip:
        return Colors.blueGrey[200]!;
      case AttendancePolicy.none:
      default:
        return baseColor;
    }
  }

  // ★★★ このメソッドを丸ごと追加 ★★★
  Widget _buildTimeGaugeBackground() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500), // ゲージが伸びる速さ
          curve: Curves.easeOut,
          // 全体の高さに進捗度を掛けて、現在のゲージの高さを決める
          height: MediaQuery.of(context).size.height * _timeGaugeProgress,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00BFFF).withOpacity(0.3), // 上の色（少し透明）
                const Color(0xFF00FFFF).withOpacity(0.5), // 下の色（少し透明）
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icon(
          Icons.check_circle,
          color: Colors.green[600],
          size: 18,
        ); // サイズを18に
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

  // ★★★ ボタンのサイズを強制的に小さくする最終手段 ★★★
  Widget _buildAttendancePopupMenu(String uniqueKey, TimetableEntry entry) {
    final AttendanceStatus currentStatus =
        _attendanceStatus[uniqueKey] ?? AttendanceStatus.none;

    // 「毎回出席」の方針でない場合は何も表示しない
    if ((_attendancePolicies[entry.id] ?? AttendancePolicy.none) !=
        AttendancePolicy.mandatory) {
      return const SizedBox.shrink();
    }

    // Themeでラップして、タップ領域を強制的に小さくする
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: PopupMenuButton<AttendanceStatus>(
        // ★ iconプロパティではなくchildプロパティを使う
        child: _buildAttendanceStatusIcon(currentStatus),
        tooltip: '出欠を記録',
        onSelected: (AttendanceStatus newStatus) {
          _setAttendanceStatus(uniqueKey, entry.id, newStatus);
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

  // ★★★ レイアウトを全面的に刷新した最終版 ★★★
  Widget _buildClassPeriodCell(int dayIndex, int periodIndex) {
    final entry =
        (_timetableGrid.isNotEmpty &&
                dayIndex < _timetableGrid.length &&
                periodIndex < _timetableGrid[dayIndex].length)
            ? _timetableGrid[dayIndex][periodIndex]
            : null;
    final String noteText = _getNoteForCell(dayIndex, periodIndex: periodIndex);
    final DateTime cellDate = _displayedMonday.add(Duration(days: dayIndex));
    final String uniqueKey =
        (entry != null)
            ? "${entry.id}_${DateFormat('yyyyMMdd').format(cellDate)}"
            : "";
    final bool isApiCancelled =
        (entry != null) && _cancellations.contains(uniqueKey);
    Map<String, String?>? characterToDisplay;
    for (var charInfo in _displayedCharacters) {
      if (charInfo['day'] == dayIndex.toString() &&
          charInfo['period'] == periodIndex.toString()) {
        characterToDisplay = charInfo;
        break;
      }
    }

    if (isApiCancelled) {
      return Expanded(
        flex: 1,
        child: SizedBox.expand(
          child: InkWell(
            onTap:
                () => _showNoteDialog(
                  context,
                  dayIndex,
                  academicPeriodIndex: periodIndex,
                ),
            child: Container(
              margin: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.orangeAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.pink[300]!, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "休講！",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 3,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    entry!.subjectName,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.95),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget cellContent;
    if (entry != null) {
      cellContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.subjectName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
                          color: Colors.black.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (noteText.isNotEmpty)
                      Text(
                        noteText,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.blueGrey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _buildAttendancePopupMenu(uniqueKey, entry),
            ],
          ),
        ],
      );
    } else if (noteText.isNotEmpty) {
      cellContent = Center(
        child: Text(
          noteText.length > 10 ? '${noteText.substring(0, 8)}…' : noteText,
          style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      );
    } else {
      cellContent = SizedBox.expand(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder:
              (Widget child, Animation<double> animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
          child:
              characterToDisplay != null
                  ? Image.asset(
                    characterToDisplay['path']!,
                    key: ValueKey<String>(characterToDisplay['path']!),
                    fit: BoxFit.contain,
                  )
                  : const SizedBox.shrink(),
        ),
      );
    }

    final policy =
        (entry != null)
            ? (_attendancePolicies[entry.id] ?? AttendancePolicy.none)
            : AttendancePolicy.none;
    final bool isMarkedAsAbsent =
        (_attendanceStatus[uniqueKey] ?? AttendanceStatus.none) ==
        AttendanceStatus.absent;
    final bool hasCharacter = characterToDisplay != null;
    final bool hasNote = noteText.isNotEmpty;
    final bool isCompletelyEmpty = (entry == null && !hasNote && !hasCharacter);
    final bool isCharacterOnly = (entry == null && !hasNote && hasCharacter);
    Color baseCellColor;
    if (isCompletelyEmpty || isCharacterOnly) {
      baseCellColor = Colors.transparent;
    } else if (entry != null) {
      baseCellColor = _getColorForPolicy(policy, entry.color);
    } else {
      baseCellColor = Colors.white.withOpacity(0.7);
    }
    final Color borderColor =
        isCompletelyEmpty || isCharacterOnly
            ? Colors.transparent
            : (entry != null
                ? entry.color.withOpacity(0.5)
                : Colors.grey[300]!.withOpacity(0.5));
    Color finalBackgroundColor = baseCellColor;
    if (entry != null) {
      final int currentAbsenceCount = _absenceCount[entry.id] ?? 0;
      finalBackgroundColor = _getWarningColor(
        currentAbsenceCount,
        baseCellColor,
      );
    }
    final bool isHighlighted =
        (_currentDayIndex == dayIndex && _currentPeriodIndex == periodIndex);

    return Expanded(
      flex: 1,
      child: InkWell(
        onTap:
            () => _showNoteDialog(
              context,
              dayIndex,
              academicPeriodIndex: periodIndex,
            ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(0.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 5, 4, 3),
                decoration: BoxDecoration(
                  color: finalBackgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      isHighlighted
                          ? Border.all(color: Colors.blueAccent, width: 2.5)
                          : Border.all(color: borderColor, width: 0.5),
                  boxShadow:
                      isHighlighted
                          ? [
                            BoxShadow(
                              color: Colors.blue[200]!.withOpacity(0.7),
                              blurRadius: 5.0,
                              spreadRadius: 1.0,
                            ),
                          ]
                          : [],
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isMarkedAsAbsent ? 0.5 : 1.0,
                  child: cellContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassPeriodRow(int periodIndex) {
    return SizedBox(
      height: _periodRowHeight,
      child: Row(
        children: List.generate(6, (dayIndex) {
          return _buildClassPeriodCell(dayIndex, periodIndex);
        }),
      ),
    );
  }

  Widget _buildLunchRow() {
    return SizedBox(
      height: _lunchRowHeight,
      child: Row(
        children: List.generate(6, (dayIndex) {
          final String noteText = _getNoteForCell(dayIndex);
          final bool isHighlighted =
              (_isLunchTime && _currentDayIndex == dayIndex);
          final bool hasNote = noteText.isNotEmpty;
          return Expanded(
            flex: 1,
            child: InkWell(
              onTap: () => _showNoteDialog(context, dayIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(0.5),
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color:
                      hasNote
                          ? Colors.lightGreen[100]!.withOpacity(0.8)
                          : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border:
                      isHighlighted
                          ? Border.all(color: Colors.amber[600]!, width: 2.5)
                          : Border.all(
                            color:
                                hasNote
                                    ? Colors.green[300]!.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.4),
                            width: 0.5,
                          ),
                  boxShadow:
                      isHighlighted
                          ? [
                            BoxShadow(
                              color: Colors.amber[300]!.withOpacity(0.8),
                              blurRadius: 5.0,
                            ),
                          ]
                          : [],
                ),
                child: Center(
                  child: Text(
                    noteText.isNotEmpty
                        ? (noteText.length > 10
                            ? '${noteText.substring(0, 8)}…'
                            : noteText)
                        : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.green[900],
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAfterSchoolRow() {
    return SizedBox(
      height: _lunchRowHeight,
      child: Row(
        children: List.generate(6, (dayIndex) {
          final String noteText = _getNoteForCell(
            dayIndex,
            isAfterSchool: true,
          );
          final bool hasNote = noteText.isNotEmpty;
          return Expanded(
            flex: 1,
            child: InkWell(
              onTap:
                  () => _showNoteDialog(context, dayIndex, isAfterSchool: true),
              child: Container(
                margin: const EdgeInsets.all(0.5),
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color:
                      hasNote
                          ? Colors.indigo[50]!.withOpacity(0.8)
                          : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color:
                        hasNote
                            ? Colors.indigo[200]!.withOpacity(0.6)
                            : Colors.white.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    noteText.isNotEmpty
                        ? (noteText.length > 10
                            ? '${noteText.substring(0, 8)}…'
                            : noteText)
                        : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.indigo[900],
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showSundayEventDialog() async {
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
              title: const Text(
                '日曜の予定を追加',
                style: TextStyle(fontFamily: 'misaki'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(hintText: '予定のタイトル'),
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
                            color: Colors.blue,
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
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text(
                      "毎週の予定にする",
                      style: TextStyle(fontFamily: 'misaki', fontSize: 13),
                    ),
                    value: isWeekly,
                    onChanged: (bool? value) {
                      setDialogState(() => isWeekly = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        startTime != null &&
                        endTime != null &&
                        (endTime!.hour * 60 + endTime!.minute) >
                            (startTime!.hour * 60 + startTime!.minute)) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('保存'),
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

  List<Widget> _buildSundayEventCells(double totalHeight) {
    List<Widget> eventCells = [];
    final int totalMinutes = (20 * 60 + 0) - (8 * 60 + 50);
    final DateTime currentSunday = _displayedMonday.add(
      const Duration(days: 6),
    );

    final List<Map<String, dynamic>> eventsToShow =
        _sundayEvents.where((event) {
          if (event['isWeekly'] == true) {
            return true;
          }
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
              color:
                  (event['isWeekly'] as bool)
                      ? Colors.pink[200]?.withOpacity(0.8)
                      : Colors.pink[100]?.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.pink[200]!),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'misaki',
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    return eventCells;
  }

  // ★★★ _buildFullTimetableメソッドを丸ごと置き換え ★★★

  // ★★★ _buildFullTimetableメソッドを丸ごと置き換え ★★★

  // ★★★ このメソッドをクラス内に追加（または復活）させてください ★★★

  // ★★★ 各曜日のヘッダーを生成する新しい関数 ★★★
  Widget _buildDayHeader(int dayIndex) {
    final bool isSunday = dayIndex == 6;
    return SizedBox(
      height: 50, // ヘッダーの高さ
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
                color:
                    isSunday ? Colors.red[400] : Colors.white.withOpacity(0.9),
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _dayDates.isNotEmpty ? _dayDates[dayIndex] : "",
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'misaki',
                color:
                    isSunday ? Colors.red[300] : Colors.white.withOpacity(0.8),
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTimetableHeader() {
    return Row(
      children: [
        const SizedBox(width: 65), // 時系列バーの幅と合わせるための空白
        Expanded(
          child: Row(
            children: List.generate(7, (dayIndex) {
              final isSunday = dayIndex == 6;
              return Expanded(
                flex: 1,
                child: SizedBox(
                  height: 40,
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
                            color: isSunday ? Colors.red[400] : Colors.white,
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
                            color: isSunday ? Colors.red[300] : Colors.white70,
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

  // ★★★ _buildNewContinuousTimeColumnメソッドを丸ごと置き換え ★★★
  // ★★★ このメソッドを丸ごと置き換えてください ★★★
  Widget _buildNewContinuousTimeColumn() {
    final double totalColumnHeight =
        (_periodRowHeight * _academicPeriods) +
        _lunchRowHeight +
        _lunchRowHeight;
    final List<double> rowHeights = [
      _periodRowHeight,
      _periodRowHeight,
      _lunchRowHeight,
      _periodRowHeight,
      _periodRowHeight,
      _periodRowHeight,
      _periodRowHeight,
      _lunchRowHeight,
    ];
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
      // --- 容器の外枠 ---
      width: 65,
      height: totalColumnHeight + 10,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.grey[700]!, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(12)), // 容器の角を丸める
      ),
      child: ClipRRect(
        // 中身が外枠からはみ出ないようにする
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Stack(
          children: [
            // --- 奥：時間でたまるゲージ（液体）---
            Align(
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                height: totalColumnHeight * _timeGaugeProgress,
                decoration: BoxDecoration(
                  // ★★★ 角を丸くして「試験管」風に ★★★
                  borderRadius: BorderRadius.circular(10),
                  // ★★★「危険な液体」風のグラデーション ★★★
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 20, 182, 226).withOpacity(0.7),
                      const Color.fromARGB(255, 134, 19, 159).withOpacity(0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // --- 手前：テキストと区切り線 ---
            Column(
              children: List.generate(rowHeights.length, (index) {
                final bool isClassPeriod =
                    (index < 2 || (index > 2 && index < 7));
                int? timeIndex;
                if (index < 2) {
                  timeIndex = index;
                } else if (index > 2 && index < 7) {
                  timeIndex = index - 1;
                }

                return Container(
                  height: rowHeights[index],
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
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
                        periodLabels[index],
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

  Widget _buildTimetableGridOnly() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (dayIndex) {
        if (dayIndex == 6) {
          // 日曜
          final double totalHeight =
              (_periodRowHeight * _academicPeriods) + (_lunchRowHeight * 2);
          return Expanded(
            flex: 1,
            child: InkWell(
              onTap: () => _showSundayEventDialog(),
              child: SizedBox(
                height: totalHeight,
                child: Stack(children: _buildSundayEventCells(totalHeight)),
              ),
            ),
          );
        }
        // 月曜から土曜
        return Expanded(
          flex: 1,
          child: Column(
            children: [
              SizedBox(
                height: _periodRowHeight,
                child: _buildClassPeriodCell(dayIndex, 0),
              ),
              SizedBox(
                height: _periodRowHeight,
                child: _buildClassPeriodCell(dayIndex, 1),
              ),
              SizedBox(
                height: _lunchRowHeight,
                child: _buildLunchCell(dayIndex),
              ),
              SizedBox(
                height: _periodRowHeight,
                child: _buildClassPeriodCell(dayIndex, 2),
              ),
              SizedBox(
                height: _periodRowHeight,
                child: _buildClassPeriodCell(dayIndex, 3),
              ),
              SizedBox(
                height: _periodRowHeight,
                child: _buildClassPeriodCell(dayIndex, 4),
              ),
              SizedBox(
                height: _periodRowHeight,
                child: _buildClassPeriodCell(dayIndex, 5),
              ),
              SizedBox(
                height: _lunchRowHeight,
                child: _buildAfterSchoolCell(dayIndex),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ★★★ 以下4つのメソッドを、クラス内に丸ごと追加してください ★★★

  // 1. 新しい「日付ヘッダー」（表の外に配置）
  Widget _buildDateHeaderRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
      child: Row(
        children: [
          const SizedBox(width: 65), // 時系列バーの幅と合わせるための空白
          Expanded(
            child: Row(
              children: List.generate(7, (dayIndex) {
                final isSunday = dayIndex == 6;
                return Expanded(
                  flex: 1,
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
                            color: isSunday ? Colors.red[400] : Colors.white,
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
                            color: isSunday ? Colors.red[300] : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // 2. 新しい「時系列バー」（ゲージ効果付き）
  Widget _buildTimeGaugeColumn() {
    final List<double> rowHeights = [
      _periodRowHeight,
      _periodRowHeight,
      _lunchRowHeight,
      _periodRowHeight,
      _periodRowHeight,
      _periodRowHeight,
      _periodRowHeight,
      _lunchRowHeight,
    ];
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
    final double totalColumnHeight = rowHeights.reduce((a, b) => a + b);

    return SizedBox(
      width: 65,
      child: Stack(
        children: [
          // 奥：時間でたまるゲージ
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              height: totalColumnHeight * _timeGaugeProgress,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BFFF), Color(0xFF00FFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // 手前：テキストと区切り線
          Column(
            children: List.generate(rowHeights.length, (index) {
              final isClassPeriod = (index < 2 || (index > 2 && index < 7));
              int? timeIndex;
              if (index < 2) {
                timeIndex = index;
              } else if (index > 2 && index < 7) {
                timeIndex = index - 1;
              }

              return Container(
                height: rowHeights[index],
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.0,
                    ),
                  ),
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
                      periodLabels[index],
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
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // 3. 曜日ごとの行を生成するメソッド
  Widget _buildDayRow(int dayIndex) {
    // 日曜日の場合
    if (dayIndex == 6) {
      final double totalHeight =
          (_periodRowHeight * _academicPeriods) + (_lunchRowHeight * 2);
      return Expanded(
        flex: 1,
        child: InkWell(
          onTap: () => _showSundayEventDialog(),
          child: SizedBox(
            height: totalHeight,
            child: Stack(children: _buildSundayEventCells(totalHeight)),
          ),
        ),
      );
    }
    // 月曜から土曜の場合
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          SizedBox(
            height: _periodRowHeight,
            child: _buildClassPeriodCell(dayIndex, 0),
          ),
          SizedBox(
            height: _periodRowHeight,
            child: _buildClassPeriodCell(dayIndex, 1),
          ),
          SizedBox(height: _lunchRowHeight, child: _buildLunchCell(dayIndex)),
          SizedBox(
            height: _periodRowHeight,
            child: _buildClassPeriodCell(dayIndex, 2),
          ),
          SizedBox(
            height: _periodRowHeight,
            child: _buildClassPeriodCell(dayIndex, 3),
          ),
          SizedBox(
            height: _periodRowHeight,
            child: _buildClassPeriodCell(dayIndex, 4),
          ),
          SizedBox(
            height: _periodRowHeight,
            child: _buildClassPeriodCell(dayIndex, 5),
          ),
          SizedBox(
            height: _lunchRowHeight,
            child: _buildAfterSchoolCell(dayIndex),
          ),
        ],
      ),
    );
  }

  // 4. 昼と放課後のセルを生成するメソッド (以前のRowから分離)
  Widget _buildLunchCell(int dayIndex) {
    return InkWell(
      onTap: () => _showNoteDialog(context, dayIndex),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color:
              _getNoteForCell(dayIndex).isNotEmpty
                  ? Colors.lightGreen[100]!.withOpacity(0.8)
                  : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            _getNoteForCell(dayIndex),
            style: TextStyle(
              fontSize: 9,
              color: Colors.green[900],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAfterSchoolCell(int dayIndex) {
    return InkWell(
      onTap: () => _showNoteDialog(context, dayIndex, isAfterSchool: true),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color:
              _getNoteForCell(dayIndex, isAfterSchool: true).isNotEmpty
                  ? Colors.indigo[50]!.withOpacity(0.8)
                  : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            _getNoteForCell(dayIndex, isAfterSchool: true),
            style: TextStyle(
              fontSize: 9,
              color: Colors.indigo[900],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 17),
              onPressed: _goToPreviousWeek,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              constraints: const BoxConstraints(),
            ),
            Text(
              _weekDateRange,
              style: const TextStyle(
                fontFamily: 'misaki',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 17),
              onPressed: _goToNextWeek,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.white),
            tooltip: '壁紙として保存',
            onPressed: () {
              /* TODO */
            },
          ),
        ],
      ),
      // ★★★ body全体を、背景画像を持つContainerで囲む構造に戻します ★★★
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // 背景画像
            Positioned.fill(
              child: Image.asset(
                "assets/background_plaza.png",
                fit: BoxFit.cover,
              ),
            ),
            // 黒のオーバーレイ（暗くする）
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4), // 数値で暗さ調整（0.0〜1.0）
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // --- 1. 新しいヘッダー行 ---
                  _buildNewTimetableHeader(),

                  // --- 2. メインのコンテンツ（時系列 + すりガラスの表） ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- 2-1. 左側の時系列バー ---
                          _buildNewContinuousTimeColumn(),

                          // --- 2-2. 右側のすりガラスの時間割グリッド ---
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
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: _buildTimetableGridOnly(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CommonBottomNavigation(
                currentPage: AppPage.timetable,
                parkIconAsset: 'assets/button_park_icon.png',
                parkIconActiveAsset: 'assets/button_park_icon_active.png',
                timetableIconAsset: 'assets/button_timetable.png',
                timetableIconActiveAsset: 'assets/button_timetable_active.png',
                creditReviewIconAsset: 'assets/button_unit_review.png',
                creditReviewActiveAsset: 'assets/button_unit_review_active.png',
                rankingIconAsset: 'assets/button_ranking.png',
                rankingIconActiveAsset: 'assets/button_ranking_active.png',
                itemIconAsset: 'assets/button_dressup.png',
                itemIconActiveAsset: 'assets/button_dressup_active.png',
                onParkTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ParkPage(),
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
                onTimetableTap: () {
                  print("Already on Timetable Page");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ★★★ このクラスをファイルの一番下に追加 ★★★
class SlantedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    final double slantAmount = size.height * 0.5; // 斜めになる度合い
    path.lineTo(size.width - slantAmount, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
