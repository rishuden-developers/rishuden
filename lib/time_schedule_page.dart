import 'package:flutter/material.dart';
import 'dart:math'; // Randomのために必要
import 'package:intl/intl.dart'; // 日付フォーマットのために必要

// 共通フッターと遷移先ページのインポート (パスは実際の構成に合わせてください)
import 'common_bottom_navigation.dart';
import 'park_page.dart';
import 'credit_review_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';

// --- モックデータと関連クラス ---
class TimetableEntry {
  final String id;
  final String subjectName;
  final String classroom;
  final String teacherName;
  final int dayOfWeek; // 0=月, 1=火, ..., 4=金
  final int period; // 1, 2, ..., 6
  final Color color;

  TimetableEntry({
    required this.id,
    required this.subjectName,
    required this.classroom,
    this.teacherName = '',
    required this.dayOfWeek,
    required this.period,
    this.color = Colors.white,
  });
}

final List<TimetableEntry> mockTimetable = [
  TimetableEntry(
    id: '1',
    subjectName: "微分積分学I",
    classroom: "A-101",
    teacherName: "山田先生",
    dayOfWeek: 0,
    period: 1,
    color: Colors.lightBlue[100]!,
  ),
  TimetableEntry(
    id: '2',
    subjectName: "プログラミング基礎",
    classroom: "B-203",
    teacherName: "佐藤先生",
    dayOfWeek: 0,
    period: 2,
    color: Colors.greenAccent[100]!,
  ),
  TimetableEntry(
    id: '3',
    subjectName: "文学史",
    classroom: "共通C301",
    teacherName: "木村先生",
    dayOfWeek: 0,
    period: 4,
    color: Colors.amber[200]!,
  ),
  TimetableEntry(
    id: '12',
    subjectName: "特別講義X",
    classroom: "大講義室",
    teacherName: "外部講師",
    dayOfWeek: 0,
    period: 6,
    color: Colors.grey[300]!,
  ),
  TimetableEntry(
    id: '4',
    subjectName: "線形代数学",
    classroom: "A-102",
    teacherName: "田中先生",
    dayOfWeek: 1,
    period: 1,
    color: Colors.orangeAccent[100]!,
  ),
  TimetableEntry(
    id: '5',
    subjectName: "英語コミュニケーション",
    classroom: "C-301",
    teacherName: "Smith先生",
    dayOfWeek: 1,
    period: 3,
    color: Colors.purpleAccent[100]!,
  ),
  TimetableEntry(
    id: '6',
    subjectName: "経済学原論",
    classroom: "D-105",
    teacherName: "鈴木先生",
    dayOfWeek: 2,
    period: 2,
    color: Colors.redAccent[100]!,
  ),
  TimetableEntry(
    id: '7',
    subjectName: "健康科学",
    classroom: "体育館",
    teacherName: "伊藤先生",
    dayOfWeek: 2,
    period: 4,
    color: Colors.lime[200]!,
  ),
  TimetableEntry(
    id: '8',
    subjectName: "実験物理学",
    classroom: "E-Lab1",
    teacherName: "高橋先生",
    dayOfWeek: 3,
    period: 3,
    color: Colors.tealAccent[100]!,
  ),
  TimetableEntry(
    id: '9',
    subjectName: "実験物理学",
    classroom: "E-Lab1",
    teacherName: "高橋先生",
    dayOfWeek: 3,
    period: 4,
    color: Colors.tealAccent[100]!,
  ),
  TimetableEntry(
    id: '13',
    subjectName: "ゼミ準備",
    classroom: "研究室A",
    teacherName: "各自",
    dayOfWeek: 3,
    period: 6,
    color: Colors.brown[100]!,
  ),
  TimetableEntry(
    id: '10',
    subjectName: "キャリアデザイン",
    classroom: "講堂",
    teacherName: "キャリアセンター",
    dayOfWeek: 4,
    period: 5,
    color: Colors.pinkAccent[100]!,
  ),
  TimetableEntry(
    id: '11',
    subjectName: "第二外国語(独)",
    classroom: "F-202",
    teacherName: "Schmidt先生",
    dayOfWeek: 4,
    period: 2,
    color: Colors.indigo[100]!,
  ),
];
// --- ここまでモックデータ ---

class TimeSchedulePage extends StatefulWidget {
  const TimeSchedulePage({super.key});

  @override
  State<TimeSchedulePage> createState() => _TimeSchedulePageState();
}

class _TimeSchedulePageState extends State<TimeSchedulePage> {
  final List<String> _days = const ['月', '火', '水', '木', '金'];
  final int _academicPeriods = 6;

  String _characterName = 'キャラクター';
  String _characterImagePath = 'assets/character_unknown.png';
  List<List<TimetableEntry?>> _timetableGrid = [];
  Map<String, String> _cellNotes = {};
  final String _lunchPeriodKeyPrefix = "L_";
  final String _academicCellKeyPrefix = "C_";

  int _characterDisplayDay = -1;
  int _characterDisplayPeriod = -1;

  String _weekDateRange = "";

  @override
  void initState() {
    super.initState();
    _initializeTimetableGrid();
    _calculateWeekDateRange();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    bool needsUpdate = false;
    String newName = arguments?['characterName'] ?? 'キャラクター';
    String newImagePath =
        arguments?['characterImage'] ?? 'assets/character_unknown.png';

    if (_characterName != newName ||
        _characterImagePath != newImagePath ||
        _characterDisplayDay == -1) {
      needsUpdate = true;
      _characterName = newName;
      _characterImagePath = newImagePath;
    }

    if (needsUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _placeCharacterRandomly();
          });
        }
      });
    }
  }

  void _calculateWeekDateRange() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 4));
    try {
      // main.dart で initializeDateFormatting('ja_JP', null); が実行されていること
      setState(() {
        _weekDateRange =
            "${DateFormat.Md('ja').format(startOfWeek)} 〜 ${DateFormat.Md('ja').format(endOfWeek)}";
      });
    } catch (e) {
      print("日付フォーマットエラー (main.dartでの初期化を確認): $e");
      setState(() {
        _weekDateRange = "日付エラー";
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
      }
    }
  }

  void _placeCharacterRandomly() {
    List<Map<String, int>> emptyCellsForCharacter = [];
    if (_timetableGrid.isEmpty && mockTimetable.isNotEmpty)
      _initializeTimetableGrid();

    for (int day = 0; day < _days.length; day++) {
      for (int period = 0; period < _academicPeriods; period++) {
        String academicCellNoteKey = "$_academicCellKeyPrefix${day}_$period";
        if (_timetableGrid[day][period] == null &&
            (_cellNotes[academicCellNoteKey] == null ||
                _cellNotes[academicCellNoteKey]!.isEmpty)) {
          emptyCellsForCharacter.add({'day': day, 'period': period});
        }
      }
    }

    if (emptyCellsForCharacter.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(emptyCellsForCharacter.length);
      _characterDisplayDay = emptyCellsForCharacter[randomIndex]['day']!;
      _characterDisplayPeriod = emptyCellsForCharacter[randomIndex]['period']!;
    } else {
      _characterDisplayDay = -1;
      _characterDisplayPeriod = -1;
    }
  }

  Future<void> _showNoteDialog(
    BuildContext context,
    int dayIndex, {
    int? academicPeriodIndex,
  }) async {
    String noteKey;
    String dialogTitle;

    if (academicPeriodIndex != null) {
      noteKey = "$_academicCellKeyPrefix${dayIndex}_$academicPeriodIndex";
      dialogTitle = "${_days[dayIndex]}曜 ${academicPeriodIndex + 1}限 メモ";
    } else {
      noteKey = "$_lunchPeriodKeyPrefix$dayIndex";
      dialogTitle = "${_days[dayIndex]}曜日 昼休みメモ";
    }

    TextEditingController noteController = TextEditingController(
      text: _cellNotes[noteKey] ?? '',
    );
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.brown[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            dialogTitle,
            style: TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: 16,
              color: Colors.brown[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: EdgeInsets.all(20),
          content: Container(
            width: double.maxFinite,
            child: TextField(
              controller: noteController,
              maxLines: 5,
              minLines: 3,
              style: TextStyle(
                fontFamily: 'NotoSansJP',
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
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'キャンセル',
                style: TextStyle(
                  fontFamily: 'NotoSansJP',
                  color: Colors.brown[600],
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
              child: Text(
                '保存',
                style: TextStyle(fontFamily: 'NotoSansJP', color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  if (noteController.text.trim().isEmpty) {
                    _cellNotes.remove(noteKey);
                  } else {
                    _cellNotes[noteKey] = noteController.text.trim();
                  }
                });
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  setState(() {
                    _placeCharacterRandomly();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimetableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[100]?.withOpacity(0.8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border.all(color: Colors.brown[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  '時限',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'NotoSansJP',
                    color: Colors.brown[800],
                  ),
                ),
              ),
            ),
          ),
          for (String day in _days)
            Expanded(
              flex: 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'NotoSansJP',
                      color: Colors.brown[800],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassPeriodCell(int dayIndex, int periodIndex) {
    final entry =
        (_timetableGrid.isNotEmpty &&
                dayIndex < _timetableGrid.length &&
                periodIndex < _timetableGrid[dayIndex].length)
            ? _timetableGrid[dayIndex][periodIndex]
            : null;
    bool isCharacterCell =
        (dayIndex == _characterDisplayDay &&
            periodIndex == _characterDisplayPeriod);
    String noteKey = "$_academicCellKeyPrefix${dayIndex}_$periodIndex";
    String noteText = _cellNotes[noteKey] ?? '';
    Widget cellContent;

    if (isCharacterCell && entry == null && noteText.isEmpty) {
      cellContent = Padding(
        padding: const EdgeInsets.all(3.0),
        child: Image.asset(_characterImagePath, fit: BoxFit.contain),
      );
    } else if (entry != null) {
      cellContent = Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              entry.subjectName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                fontFamily: 'NotoSansJP',
                color: Colors.black.withOpacity(0.85),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if (entry.classroom.isNotEmpty)
            Flexible(
              child: Text(
                entry.classroom,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.black.withOpacity(0.6),
                  fontFamily: 'NotoSansJP',
                ),
              ),
            ),
          if (entry.teacherName.isNotEmpty)
            Flexible(
              child: Text(
                entry.teacherName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 7,
                  color: Colors.black.withOpacity(0.5),
                  fontFamily: 'NotoSansJP',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      );
    } else {
      cellContent = Center(
        child: Text(
          noteText.isNotEmpty
              ? (noteText.length > 12
                  ? '${noteText.substring(0, 10)}…'
                  : noteText)
              : '',
          style: TextStyle(
            fontSize: 9,
            color: Colors.brown[700],
            fontStyle: FontStyle.italic,
            fontFamily: 'NotoSansJP',
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      );
    }
    return Expanded(
      flex: 3,
      child: InkWell(
        onTap:
            entry == null
                ? () => _showNoteDialog(
                  context,
                  dayIndex,
                  academicPeriodIndex: periodIndex,
                )
                : null,
        child: Container(
          margin: EdgeInsets.all(0.5),
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: entry?.color ?? Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (entry?.color ?? Colors.grey[300]!).withOpacity(0.5),
              width: 0.5,
            ),
          ),
          child: cellContent,
        ),
      ),
    );
  }

  // ★★★ _buildClassPeriodRow (エラーが出ていたメソッド) の修正 ★★★
  Widget _buildClassPeriodRow(int periodIndex) {
    return Expanded(
      // ★ childプロパティを追加
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.brown[50]?.withOpacity(0.7),
                border: Border(
                  right: BorderSide(color: Colors.brown[200]!),
                  bottom: BorderSide(color: Colors.brown[200]!),
                ),
              ),
              child: Center(
                child: Text(
                  '${periodIndex + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansJP',
                    color: Colors.brown[700],
                  ),
                ),
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

  // ★★★ _buildLunchRow (エラーが出ていたメソッド) の修正 ★★★
  Widget _buildLunchRow() {
    return Expanded(
      // ★ childプロパティを追加
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.lightGreen[300]?.withOpacity(0.8),
                border: Border(
                  right: BorderSide(color: Colors.brown[200]!),
                  bottom: BorderSide(color: Colors.brown[200]!),
                ),
              ),
              child: Center(
                child: Text(
                  '昼',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansJP',
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
          ),
          ...List.generate(_days.length, (dayIndex) {
            String noteKey = "$_lunchPeriodKeyPrefix$dayIndex";
            String noteText = _cellNotes[noteKey] ?? '';
            return Expanded(
              flex: 3,
              child: InkWell(
                onTap: () {
                  _showNoteDialog(context, dayIndex); // academicPeriodIndexなし
                },
                child: Container(
                  margin: EdgeInsets.all(0.5),
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen[100]?.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.green[300]!.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      noteText.isNotEmpty
                          ? (noteText.length > 12
                              ? '${noteText.substring(0, 10)}…'
                              : noteText)
                          : '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green[900],
                        fontStyle: FontStyle.italic,
                        fontFamily: 'NotoSansJP',
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
    // ★ Column の children は List<Widget> であり、各要素が Expanded である必要はない。
    // ★ 各行の高さは Expanded で囲まれた Row の中で解決される。
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 各行を均等に配置
      children:
          rows
              .map((row) => Flexible(flex: 1, child: row))
              .toList(), // 各行をFlexibleで包む
    );
  }

  // ★★★ _buildDailyMemoSection (エラーが出ていたメソッド) の修正 ★★★
  Widget _buildDailyMemoSection() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 12.0,
        left: 4.0,
        right: 4.0,
        bottom: 8.0,
      ), // ★ paddingプロパティを正しく指定
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "今日のタスク / メモ 📝",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansJP',
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
          SizedBox(height: 6),
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.brown[200]!),
            ),
            child: TextField(
              maxLines: null,
              expands: true,
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontSize: 13,
                color: Colors.brown[900],
              ),
              decoration: InputDecoration(
                hintText: '今日の目標やメモを書き込もう！',
                hintStyle: TextStyle(color: Colors.brown[400]),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomNavBarHeight = 75.0;
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _weekDateRange.isEmpty ? 'My Schedule' : _weekDateRange,
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt, color: Colors.white),
            tooltip: '壁紙として保存',
            onPressed: () {
              /* TODO: Implement wallpaper saving */
            },
          ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavigation(
        currentPage: AppPage.timetable,
        parkIconAsset: 'assets/button_park_icon.png',
        timetableIconAsset: 'assets/button_timetable_active.png',
        creditReviewIconAsset: 'assets/button_unit_review.png',
        rankingIconAsset: 'assets/button_ranking.png',
        itemIconAsset: 'assets/button_dressup.png',
        onParkTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => const ParkPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              // ParkPageが引数を期待している場合は settings を設定
              // settings: RouteSettings(arguments: { ... }),
            ),
          );
        },
        onTimetableTap: () {
          /* Current page */
        },
        onCreditReviewTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const CreditReviewPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              // ParkPageが引数を期待している場合は settings を設定
              // settings: RouteSettings(arguments: { ... }),
            ),
          );
        },
        onRankingTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const RankingPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              // ParkPageが引数を期待している場合は settings を設定
              // settings: RouteSettings(arguments: { ... }),
            ),
          );
        },
        onItemTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => const ItemPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              // ParkPageが引数を期待している場合は settings を設定
              // settings: RouteSettings(arguments: { ... }),
            ),
          );
        },
      ),
      body: Container(
        width: double.infinity, // Ensure the background covers the whole screen
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/ranking_guild_background.png"), // 背景画像
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
                child: _buildTimetableHeader(),
              ),
              Expanded(
                // ★ 時間割本体とメモ欄のエリアをExpandedで確保
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.brown[200]!.withOpacity(0.7),
                              ),
                              right: BorderSide(
                                color: Colors.brown[200]!.withOpacity(0.7),
                              ),
                              bottom: BorderSide(
                                color: Colors.brown[200]!.withOpacity(0.7),
                              ),
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: _buildTimetableBodyContent(),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildDailyMemoSection()),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: bottomNavBarHeight + 10,
                        ), // フッターに隠れないための余白を少し増やす
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
