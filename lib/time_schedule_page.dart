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
    this.initialPolicy = AttendancePolicy.flexible,
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
    color: Colors.cyanAccent,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '2',
    subjectName: "プログラミング基礎",
    classroom: "B-203",
    dayOfWeek: 0,
    period: 2,
    color: Colors.lightGreenAccent,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '3',
    subjectName: "文学史",
    classroom: "共通C301",
    dayOfWeek: 0,
    period: 4,
    color: Colors.amberAccent,
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
    color: Colors.orangeAccent,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '5',
    subjectName: "英語コミュニケーション",
    classroom: "C-301",
    dayOfWeek: 1,
    period: 3,
    color: Colors.purpleAccent,
  ),
  TimetableEntry(
    id: '6',
    subjectName: "経済学原論",
    classroom: "D-105",
    dayOfWeek: 2,
    period: 2,
    color: Colors.redAccent,
    initialPolicy: AttendancePolicy.flexible,
  ),
  TimetableEntry(
    id: '7',
    subjectName: "健康科学",
    classroom: "体育館",
    dayOfWeek: 2,
    period: 4,
    color: Colors.limeAccent,
    initialPolicy: AttendancePolicy.skip,
  ),
  TimetableEntry(
    id: '8',
    subjectName: "実験物理学",
    classroom: "E-Lab1",
    dayOfWeek: 3,
    period: 3,
    color: Colors.tealAccent,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '9',
    subjectName: "実験物理学",
    classroom: "E-Lab1",
    dayOfWeek: 3,
    period: 4,
    color: Colors.tealAccent,
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
    color: Colors.pinkAccent,
    initialPolicy: AttendancePolicy.flexible,
  ),
  TimetableEntry(
    id: '11',
    subjectName: "第二外国語(独)",
    classroom: "F-202",
    dayOfWeek: 4,
    period: 2,
    color: Colors.indigoAccent,
    initialPolicy: AttendancePolicy.skip,
  ),
  TimetableEntry(
    id: '14',
    subjectName: "統計学",
    classroom: "Z-101",
    dayOfWeek: 1,
    period: 2,
    color: Colors.cyanAccent,
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
  Map<String, AttendanceStatus> _attendanceStatus = {};
  Map<String, int> _absenceCount = {};
  Map<String, int> _lateCount = {};
  late DateTime _displayedMonday;
  List<String> _dayDates = [];
  String _weekDateRange = "";
  List<Map<String, dynamic>> _sundayEvents = [];
  Map<int, List<Map<String, dynamic>>> _weekdayEvents = {};
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

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
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

  void _goToPreviousWeek() {
    setState(() {
      _displayedMonday = _displayedMonday.subtract(const Duration(days: 7));
      _updateWeekDates();
    });
  }

  void _goToNextWeek() {
    setState(() {
      _displayedMonday = _displayedMonday.add(const Duration(days: 7));
      _updateWeekDates();
    });
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
    final oneTimeNoteKey =
        "C_${dayIndex}_${periodIndex}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
    final weeklyNoteKey = "W_C_${dayIndex}_$periodIndex";
    return _cellNotes[oneTimeNoteKey] ?? _weeklyNotes[weeklyNoteKey] ?? '';
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

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Color _getNeonWarningColor(Color baseColor, String entryId) {
    final int absenceCount = _absenceCount[entryId] ?? 0;
    final int lateCount = _lateCount[entryId] ?? 0;
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

    // 8つの行の、1行あたりの高さを計算
    final double rowHeight = totalHeight / 8.0;

    for (
      int periodIndex = 0;
      periodIndex < _timetableGrid[dayIndex].length;
      periodIndex++
    ) {
      final entry = _timetableGrid[dayIndex][periodIndex];
      if (entry == null) continue;

      // --- ★★★ ここからが新しい位置計算ロジックです ★★★ ---
      // 授業が何限目かによって、表示する行のインデックス（0〜7）を決定する
      int visualRowIndex;
      final int period = entry.period; // periodは1〜6

      if (period <= 2) {
        // 1, 2限は、そのまま行インデックス0, 1に対応
        visualRowIndex = period - 1;
      } else {
        // 3, 4, 5, 6限は、昼休みの行(インデックス2)を挟むため、1つ下にズレる
        visualRowIndex = period;
      }

      final double top = visualRowIndex * rowHeight;
      final double height = rowHeight;
      // --- ★★★ 新しい位置計算ロジックはここまで ★★★ ---

      // 以下、ウィジェットの見た目を定義する部分は変更ありません
      final uniqueKey =
          "${entry.id}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
      final policy = _attendancePolicies[entry.id] ?? AttendancePolicy.none;
      Color textColor = Colors.white;
      BoxDecoration decoration;

      switch (policy) {
        case AttendancePolicy.mandatory:
          final neonColor = _getNeonWarningColor(entry.color, entry.id);
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
        case AttendancePolicy.none:
          textColor = Colors.white;
          decoration = BoxDecoration(
            color: entry.color.withOpacity(0.1),
            border: Border.all(color: entry.color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(6),
          );
          break;
      }

      final int absenceCount = _absenceCount[entry.id] ?? 0;
      final int lateCount = _lateCount[entry.id] ?? 0;
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
                    fontSize: 11,
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
                    _buildAttendancePopupMenu(uniqueKey, entry),
                  ],
                ),
              ],
            ),
            if (policy == AttendancePolicy.mandatory && hasCount)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "欠$absenceCount 遅$lateCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontFamily: 'misaki',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

      positionedWidgets.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: InkWell(
            onTap:
                () => _showNoteDialog(
                  context,
                  dayIndex,
                  academicPeriodIndex: periodIndex,
                ),
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
    final events = _weekdayEvents[dayIndex] ?? [];
    const double timetableStartInMinutes = 8 * 60 + 50;
    const double totalMinutesInTimetable = (20 * 60) - timetableStartInMinutes;

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final TimeOfDay startTime = event['start'];
      final TimeOfDay endTime = event['end'];
      final String title = event['title'];

      final startMinutes =
          (startTime.hour * 60 + startTime.minute) - timetableStartInMinutes;
      final endMinutes =
          (endTime.hour * 60 + endTime.minute) - timetableStartInMinutes;
      final top = (startMinutes / totalMinutesInTimetable) * totalHeight;
      final height =
          ((endMinutes - startMinutes) / totalMinutesInTimetable) * totalHeight;
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
              _showEditWeekdayEventDialog(dayIndex, i);
            },
            child: eventWidget,
          ),
        ),
      );
    }
    return positionedWidgets;
  }
  // ★★★ このメソッドをクラス内に丸ごと追加してください ★★★

  Future<void> _showEditWeekdayEventDialog(int dayIndex, int eventIndex) async {
    final eventToEdit = _weekdayEvents[dayIndex]![eventIndex];

    final TextEditingController titleController = TextEditingController(
      text: eventToEdit['title'],
    );
    TimeOfDay startTime = eventToEdit['start'];
    TimeOfDay endTime = eventToEdit['end'];
    bool isWeekly = eventToEdit['isWeekly'];

    final String? action = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
                side: BorderSide(color: Colors.amberAccent.withOpacity(0.5)),
              ),
              title: Text(
                '${_days[dayIndex]}曜日の予定を編集',
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
                          if (picked != null)
                            setDialogState(() => startTime = picked);
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
                          if (picked != null)
                            setDialogState(() => endTime = picked);
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
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        (endTime.hour * 60 + endTime.minute) >
                            (startTime.hour * 60 + startTime.minute)) {
                      Navigator.of(context).pop('update');
                    }
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
      },
    );

    if (action == 'update') {
      setState(() {
        _weekdayEvents[dayIndex]![eventIndex] = {
          'title': titleController.text,
          'start': startTime,
          'end': endTime,
          'isWeekly': isWeekly,
          'date': eventToEdit['date'],
        };
        _weekdayEvents[dayIndex]!.sort(
          (a, b) => (a['start'] as TimeOfDay).hour.compareTo(
            (b['start'] as TimeOfDay).hour,
          ),
        );
      });
    } else if (action == 'delete') {
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
    if (dayIndex == 6) {
      final double totalHeight = periodHeight * 8;
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
    return Expanded(
      flex: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          return Stack(
            children: [
              _buildTimetableBackgroundCells(dayIndex),
              ..._buildClassEntriesAsPositioned(dayIndex, totalHeight),
              ..._buildWeekdayEventsAsPositioned(dayIndex, totalHeight),
            ],
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
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white70),
                  ),
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
                  child: const Text(
                    '保存',
                    style: TextStyle(color: Colors.tealAccent),
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
                          if (picked != null)
                            setDialogState(() => startTime = picked);
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
                          if (picked != null)
                            setDialogState(() => endTime = picked);
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

    final String oneTimeNoteKey =
        "C_${dayIndex}_${academicPeriodIndex}_${DateFormat('yyyyMMdd').format(_displayedMonday.add(Duration(days: dayIndex)))}";
    final String weeklyNoteKey = "W_C_${dayIndex}_$academicPeriodIndex";

    final String initialText =
        _cellNotes[oneTimeNoteKey] ?? _weeklyNotes[weeklyNoteKey] ?? '';
    final bool isInitiallyWeekly =
        _weeklyNotes.containsKey(weeklyNoteKey) &&
        !_cellNotes.containsKey(oneTimeNoteKey);
    final AttendancePolicy initialPolicy =
        (_attendancePolicies[entry!.id] ?? AttendancePolicy.flexible);

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
                "${_days[dayIndex]}曜 ${academicPeriodIndex! + 1}限",
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
                        hintText: '授業のメモをどうぞ...',
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
                      onSelectionChanged: (Set<AttendancePolicy> newSelection) {
                        setDialogState(
                          () => selectedPolicy = newSelection.first,
                        );
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Colors.brown[100],
                        selectedBackgroundColor: Colors.orange[300],
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
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
      final currentEntry = entry;
      if (currentEntry != null) {
        setState(() {
          _attendancePolicies[currentEntry.id] = selectedPolicy;
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
        });
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
    if ((_attendancePolicies[entry.id] ?? AttendancePolicy.none) !=
        AttendancePolicy.mandatory) {
      return const SizedBox.shrink();
    }
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: PopupMenuButton<AttendanceStatus>(
        child: _buildAttendanceStatusIcon(
          _attendanceStatus[uniqueKey] ?? AttendanceStatus.none,
        ),
        tooltip: '出欠を記録',
        onSelected:
            (AttendanceStatus newStatus) =>
                _setAttendanceStatus(uniqueKey, entry.id, newStatus),
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

  Widget _buildNewTimetableHeader() {
    return Row(
      children: [
        const SizedBox(width: 65),
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

  // ★★★ このメソッドを、以下の完成版に丸ごと置き換えてください ★★★

  // ★★★ このメソッドを、以下の完成版に丸ごと置き換えてください ★★★
  Widget _buildNewContinuousTimeColumn({
    required double periodRowHeight,
    required double lunchRowHeight,
  }) {
    final double totalColumnHeight = periodRowHeight * 8;
    final List<double> rowHeights = List.generate(8, (_) => periodRowHeight);
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

    // 罫線を絶対位置で描画するためのウィジェットリストをここで生成
    List<Widget> dividers = [];
    double accumulatedHeight = 0;
    // 最後のコマの下には線は不要なため、7回繰り返す
    for (int i = 0; i < 7; i++) {
      accumulatedHeight += rowHeights[i];
      dividers.add(
        Positioned(
          top: accumulatedHeight - 1, // 各コマの下端に配置
          left: 0,
          right: 0,
          child: Container(
            height: 1.0, // 線の太さ
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      );
    }

    return Container(
      width: 65,
      // ★★★ 修正点：オーバーフローを確実に防ぐため、高さを1ピクセル減らす ★★★
      height:
          totalColumnHeight > 1 ? totalColumnHeight - 1.0 : totalColumnHeight,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.grey[700]!, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: ClipRRect(
        // はみ出しを確実に防ぐ
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                height: totalColumnHeight * _timeGaugeProgress,
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
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        134,
                        19,
                        159,
                      ).withOpacity(0.3),
                      blurRadius: 20.0,
                      spreadRadius: 8.0,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 40.0,
                      spreadRadius: 20.0,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: List.generate(rowHeights.length, (index) {
                final bool isClassPeriod =
                    (index < 2 || (index > 2 && index < 7));
                int? timeIndex;
                if (index < 2)
                  timeIndex = index;
                else if (index > 2 && index < 7)
                  timeIndex = index - 1;
                return SizedBox(
                  height: rowHeights[index],
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
            ...dividers,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double bottomPaddingForNavBar = 100.0;
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
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/background_plaza.png",
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: bottomPaddingForNavBar),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      _buildNewTimetableHeader(),
                      Expanded(
                        child: Padding(
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
                onParkTap:
                    () => Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const ParkPage(),
                        transitionDuration: Duration.zero,
                      ),
                    ),
                onCreditReviewTap:
                    () => Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const CreditReviewPage(),
                        transitionDuration: Duration.zero,
                      ),
                    ),
                onRankingTap:
                    () => Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const RankingPage(),
                        transitionDuration: Duration.zero,
                      ),
                    ),
                onItemTap:
                    () => Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const ItemPage(),
                        transitionDuration: Duration.zero,
                      ),
                    ),
                onTimetableTap: () {},
              ),
            ),
          ],
        ),
      ),
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
