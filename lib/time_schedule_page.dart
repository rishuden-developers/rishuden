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

enum AttendancePolicy {
  mandatory, // 毎回出席
  flexible, // 気分次第
  skip, // 切る
  none, // 未設定
}

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

enum AttendanceStatus { present, absent, late, none, canceled }

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
  final List<String> _days = const ['月', '火', '水', '木', '金'];
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

  final double _periodRowHeight = 60.0;
  final double _lunchRowHeight = 50.0;
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

  late DateTime _displayedMonday;
  List<String> _dayDates = [];
  String _weekDateRange = "";

  // ★★★ 変更点：API連携のシミュレーション部分を追加 ★★★
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonday = now.subtract(Duration(days: now.weekday - 1));

    // ★★★ API連携シミュレーション ★★★
    // 本来はここでAPIを呼び出し、休校情報を取得します。
    // 今回は例として「今週の火曜2限 (ID: 14)」を休校に設定します。
    final tuesdayDate = _displayedMonday.add(const Duration(days: 1));
    final cancellationKey = "14_${DateFormat('yyyyMMdd').format(tuesdayDate)}";
    _cancellations = {cancellationKey};
    // ★★★ シミュレーションここまで ★★★

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

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _updateWeekDates() {
    final startOfWeek = _displayedMonday;
    final endOfWeek = _displayedMonday.add(const Duration(days: 4));
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

  void _updateHighlight() {
    final now = DateTime.now();
    final day = now.weekday;
    final currentTime = now.hour * 100 + now.minute;
    int newDayIndex = -1;
    int newPeriodIndex = -1;
    bool newIsLunchTime = false;
    if (day >= 1 && day <= 5) {
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
    for (int day = 0; day < _days.length; day++) {
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
      // Lunch
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
      // Lunch
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
                      style: TextStyle(
                        fontFamily: 'misaki',
                        fontSize: 14,
                        color: Colors.brown[900],
                      ),
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
                      title: Text(
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
                      Padding(
                        padding: const EdgeInsets.only(
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
                  child: Text(
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

  Widget _buildTimetableHeader() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.brown[100]?.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        border: Border.all(color: Colors.brown[300]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Center(
              child: Text(
                '時限',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'misaki',
                  color: Colors.brown[800],
                ),
              ),
            ),
          ),
          ...List.generate(_days.length, (index) {
            return Expanded(
              flex: 1,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _days[index],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'misaki',
                        color: Colors.brown[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dayDates.isNotEmpty ? _dayDates[index] : "",
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'misaki',
                        color: Colors.brown[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ★★★ 変更点：休校セルのデザインを全面的に刷新 ★★★
  // ★★★ 変更点：キャラクター専用セルの見た目を調整 ★★★
  Widget _buildClassPeriodCell(int dayIndex, int periodIndex) {
    final entry =
        (_timetableGrid.isNotEmpty &&
                dayIndex < _timetableGrid.length &&
                periodIndex < _timetableGrid[dayIndex].length)
            ? _timetableGrid[dayIndex][periodIndex]
            : null;
    final String noteText = _getNoteForCell(dayIndex, periodIndex: periodIndex);
    Map<String, String?>? characterToDisplay;
    for (var charInfo in _displayedCharacters) {
      if (charInfo['day'] == dayIndex.toString() &&
          charInfo['period'] == periodIndex.toString()) {
        characterToDisplay = charInfo;
        break;
      }
    }

    final DateTime cellDate = _displayedMonday.add(Duration(days: dayIndex));
    final String uniqueKey =
        (entry != null)
            ? "${entry.id}_${DateFormat('yyyyMMdd').format(cellDate)}"
            : "";
    final bool isApiCancelled =
        (entry != null) && _cancellations.contains(uniqueKey);
    final AttendanceStatus currentWeekStatus =
        (entry != null)
            ? (_attendanceStatus[uniqueKey] ?? AttendanceStatus.none)
            : AttendanceStatus.none;

    if (isApiCancelled) {
      return Expanded(
        flex: 1,
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
                Text(
                  "休講！",
                  style: TextStyle(
                    fontFamily: 'misaki',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.pink.shade900,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry!.subjectName,
                  style: TextStyle(
                    fontFamily: 'misaki',
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.95),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final policy =
        (entry != null)
            ? (_attendancePolicies[entry.id] ?? AttendancePolicy.none)
            : AttendancePolicy.none;

    Widget mainContent;
    if (entry != null) {
      final int currentAbsenceCount = _absenceCount[entry.id] ?? 0;
      mainContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (currentAbsenceCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text(
                "欠席: $currentAbsenceCount回",
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontFamily: 'misaki',
                ),
              ),
            ),
          Flexible(
            child: Text(
              entry.subjectName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                fontFamily: 'misaki',
                color: Colors.black.withOpacity(0.85),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if (entry.classroom.isNotEmpty) const SizedBox(height: 1),
          if (entry.classroom.isNotEmpty)
            Flexible(
              child: Text(
                entry.classroom,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.black.withOpacity(0.6),
                  fontFamily: 'misaki',
                ),
              ),
            ),
        ],
      );
    } else if (noteText.isNotEmpty) {
      mainContent = Center(
        child: Text(
          noteText.length > 10 ? '${noteText.substring(0, 8)}…' : noteText,
          style: TextStyle(
            fontSize: 9,
            color: Colors.brown[700],
            fontStyle: FontStyle.italic,
            fontFamily: 'misaki',
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      );
    } else {
      mainContent = AnimatedSwitcher(
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
      );
    }

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
    final bool isMarkedAsAbsent =
        (currentWeekStatus == AttendanceStatus.absent);

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
          padding:
              isCharacterOnly ? EdgeInsets.zero : const EdgeInsets.all(2.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
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
                  child: Stack(
                    children: [
                      Center(child: mainContent),
                      if (entry != null && hasNote)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(
                            Icons.sticky_note_2_outlined,
                            size: 14,
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                      if (entry != null && policy == AttendancePolicy.mandatory)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Divider(height: 1, thickness: 0.5),
                              SizedBox(
                                height: 24,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildAttendanceButton(
                                      uniqueKey,
                                      entry.id,
                                      AttendanceStatus.present,
                                      currentWeekStatus,
                                      Icons.check_circle_outline,
                                      Colors.green,
                                    ),
                                    _buildAttendanceButton(
                                      uniqueKey,
                                      entry.id,
                                      AttendanceStatus.absent,
                                      currentWeekStatus,
                                      Icons.cancel_outlined,
                                      Colors.red,
                                    ),
                                    _buildAttendanceButton(
                                      uniqueKey,
                                      entry.id,
                                      AttendanceStatus.late,
                                      currentWeekStatus,
                                      Icons.watch_later_outlined,
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
  }

  Widget _buildAttendanceButton(
    String uniqueKey,
    String entryId,
    AttendanceStatus status,
    AttendanceStatus currentStatus,
    IconData icon,
    Color color,
  ) {
    final bool isSelected = (status == currentStatus);
    return Expanded(
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon),
        color: isSelected ? color : Colors.grey[400],
        onPressed: () => _setAttendanceStatus(uniqueKey, entryId, status),
        splashRadius: 15,
      ),
    );
  }

  Widget _buildClassPeriodRow(int periodIndex) {
    return SizedBox(
      height: _periodRowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.brown[50]?.withOpacity(0.8),
                border: Border(
                  right: BorderSide(color: Colors.brown[200]!),
                  bottom: BorderSide(color: Colors.brown[200]!),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _periodTimes[periodIndex][0],
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'misaki',
                      color: Colors.brown[700],
                    ),
                  ),
                  Text(
                    '${periodIndex + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'misaki',
                      color: Colors.brown[800],
                    ),
                  ),

                  const Spacer(),
                  Text(
                    _periodTimes[periodIndex][1],
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'misaki',
                      color: Colors.brown[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...List.generate(_days.length, (dayIndex) {
            return _buildClassPeriodCell(dayIndex, periodIndex);
          }),
        ],
      ),
    );
  }

  Widget _buildLunchRow() {
    return SizedBox(
      height: _lunchRowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.lightGreen[300]?.withOpacity(0.9),
                border: Border(
                  right: BorderSide(color: Colors.brown[200]!),
                  bottom: BorderSide(color: Colors.brown[200]!),
                ),
              ),
              child: Center(
                child: Text(
                  '昼',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'misaki',
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ), // ★★★ カンマを修正 ★★★
          ...List.generate(_days.length, (dayIndex) {
            final String noteText = _getNoteForCell(dayIndex);
            final bool isHighlighted =
                (_isLunchTime && _currentDayIndex == dayIndex);
            final bool hasNote = noteText.isNotEmpty;
            final Color cellColor =
                hasNote
                    ? Colors.lightGreen[100]!.withOpacity(0.8)
                    : Colors.transparent;
            final Color borderColor =
                hasNote
                    ? Colors.green[300]!.withOpacity(0.6)
                    : Colors.transparent;
            return Expanded(
              flex: 1,
              child: InkWell(
                onTap: () => _showNoteDialog(context, dayIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(0.5),
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                    border:
                        isHighlighted
                            ? Border.all(color: Colors.amber[600]!, width: 2.5)
                            : Border.all(color: borderColor, width: 0.5),
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
                        fontFamily: 'misaki',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAfterSchoolRow() {
    return SizedBox(
      height: _lunchRowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.indigo[200]?.withOpacity(0.9),
                border: Border(
                  right: BorderSide(color: Colors.brown[200]!),
                  bottom: BorderSide(color: Colors.brown[200]!),
                ),
              ),
              child: Center(
                child: Text(
                  '放課後',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'misaki',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ), // ★★★ カンマを修正 ★★★
          ...List.generate(_days.length, (dayIndex) {
            final String noteText = _getNoteForCell(
              dayIndex,
              isAfterSchool: true,
            );
            final bool hasNote = noteText.isNotEmpty;
            final Color cellColor =
                hasNote
                    ? Colors.indigo[50]!.withOpacity(0.8)
                    : Colors.transparent;
            final Color borderColor =
                hasNote
                    ? Colors.indigo[200]!.withOpacity(0.6)
                    : Colors.transparent;
            return Expanded(
              flex: 1,
              child: InkWell(
                onTap:
                    () =>
                        _showNoteDialog(context, dayIndex, isAfterSchool: true),
                child: Container(
                  margin: const EdgeInsets.all(0.5),
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor, width: 0.5),
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
                        fontFamily: 'misaki',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimetableBodyContent() {
    List<Widget> rows = [];
    for (int periodIdx = 0; periodIdx < 2; periodIdx++) {
      rows.add(_buildClassPeriodRow(periodIdx));
    }
    rows.add(_buildLunchRow());
    for (int periodIdx = 2; periodIdx < _academicPeriods; periodIdx++) {
      rows.add(_buildClassPeriodRow(periodIdx));
    }
    rows.add(_buildAfterSchoolRow());
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  // ★★★ 変更点：時間割の背景に「すりガラス効果」を適用 ★★★
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background_plaza.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
                    child: _buildTimetableHeader(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ★★★ ここからが変更箇所です ★★★
                          // 角を丸くするために ClipRRect で囲む
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 12.0,
                                sigmaY: 12.0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.2,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _buildTimetableBodyContent(),
                                ),
                              ),
                            ),
                          ),

                          // ★★★ ここまでが変更箇所です ★★★
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 30,
              left: 40,
              right: 40,
              child: CommonBottomNavigation(
                currentPage: AppPage.timetable,
                parkIconAsset: 'assets/button_park.png',
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
