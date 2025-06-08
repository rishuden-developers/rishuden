import 'package:flutter/material.dart';
import 'dart:async'; // Timer.periodic のために必要
import 'dart:math'; // Randomのために必要
import 'package:intl/intl.dart'; // DateFormat のために必要
import 'package:provider/provider.dart'; // ★★★ Providerをインポート ★★★
import 'character_provider.dart'; // ★★★ CharacterProviderをインポート ★★★

// 共通フッターと遷移先ページのインポート
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

  // メインキャラクター情報はProviderから取得するため、ローカルStateでは初期値のみ
  String _mainCharacterName = 'キャラクター';
  String _mainCharacterImagePath = 'assets/character_unknown.png';

  List<List<TimetableEntry?>> _timetableGrid = [];
  Map<String, String> _cellNotes = {};
  final String _lunchPeriodKeyPrefix = "L_";
  final String _academicCellKeyPrefix = "C_";

  List<Map<String, String>> _displayedCharacters = [];

  final List<String> _otherCharacterImagePaths = [
    'assets/character_wizard.png',
    'assets/character_merchant.png',
    'assets/character_gorilla.png',
    'assets/character_swordman.png',
    'assets/character_takuji.png', // ★ カンマ修正
    'assets/character_god.png',
    'assets/character_adventurer.png',
  ];

  String _weekDateRange = "";
  final double _periodRowHeight = 75.0;
  final double _lunchRowHeight = 50.0;

  final List<String> _periodTimes = [
    "8:50\n10:20",
    "10:30\n12:00",
    "13:30\n15:00",
    "15:10\n16:40",
    "16:50\n18:20",
    "18:30\n20:00",
  ];

  @override
  void initState() {
    super.initState();
    _initializeTimetableGrid();
    _calculateWeekDateRange();
    // didChangeDependencies で Provider からキャラクター情報を読み込み、配置
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ★★★ Providerからキャラクター情報を取得 ★★★
    final characterProvider = Provider.of<CharacterProvider>(context);
    bool characterInfoChanged = false;

    if (_mainCharacterName != characterProvider.characterName ||
        _mainCharacterImagePath != characterProvider.characterImage) {
      _mainCharacterName = characterProvider.characterName;
      _mainCharacterImagePath = characterProvider.characterImage;
      characterInfoChanged = true;
    }

    // 初回またはキャラクター情報が変更された場合にキャラクターを配置
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

  // dispose メソッドは変更なし
  @override
  void dispose() {
    super.dispose();
  }

  void _calculateWeekDateRange() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 4));
    try {
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

  void _placeCharactersRandomly() {
    List<Map<String, String>> newCharacterList = []; // ★ ローカルリストで構築
    List<Map<String, int>> availableEmptyCells = [];

    if (_timetableGrid.isEmpty && mockTimetable.isNotEmpty) {
      _initializeTimetableGrid();
    }

    for (int day = 0; day < _days.length; day++) {
      for (int period = 0; period < _academicPeriods; period++) {
        String academicCellNoteKey = "$_academicCellKeyPrefix${day}_$period";
        if (_timetableGrid[day][period] == null &&
            (_cellNotes[academicCellNoteKey] == null ||
                _cellNotes[academicCellNoteKey]!.isEmpty)) {
          availableEmptyCells.add({'day': day, 'period': period});
        }
      }
    }

    availableEmptyCells.shuffle();
    final random = Random();

    // 1. メインキャラクターの配置
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

    // 2. 追加キャラクター2体の配置
    List<String> additionalCharacterPool = List<String>.from(
      _otherCharacterImagePaths,
    );
    additionalCharacterPool.remove(_mainCharacterImagePath); // メインキャラを候補から削除
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
    // ★★★ State変数を更新 (setStateは呼び出し元で行われる) ★★★
    _displayedCharacters = newCharacterList;
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
    bool? noteWasSaved = await showDialog<bool>(
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
              fontFamily: 'misaki',
              fontSize: 16,
              color: Colors.brown[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Container(
            width: double.maxFinite,
            child: TextField(
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
              onPressed: () {
                // setStateをダイアログ内ではなく、ダイアログが閉じた後に行う
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (noteWasSaved == true) {
      setState(() {
        // ★★★ setStateをここに移動 ★★★
        if (noteController.text.trim().isEmpty) {
          _cellNotes.remove(noteKey);
        } else {
          _cellNotes[noteKey] = noteController.text.trim();
        }
        _placeCharactersRandomly();
      });
    }
  }

  Widget _buildTimetableHeader() {
    return Container(
      height: 40,
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
          for (String day in _days)
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'misaki',
                    color: Colors.brown[800],
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
    String noteKey = "$_academicCellKeyPrefix${dayIndex}_$periodIndex";
    String noteText = _cellNotes[noteKey] ?? '';
    Map<String, String?>? characterToDisplay; // null許容に
    for (var charInfo in _displayedCharacters) {
      if (charInfo['day'] == dayIndex.toString() &&
          charInfo['period'] == periodIndex.toString()) {
        characterToDisplay = charInfo;
        break;
      }
    }
    Widget cellContent;
    if (characterToDisplay != null && entry == null && noteText.isEmpty) {
      cellContent = Padding(
        padding: const EdgeInsets.all(3.0),
        child: Image.asset(characterToDisplay['path']!, fit: BoxFit.contain),
      );
    } else if (entry != null) {
      cellContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
          if (entry.teacherName.isNotEmpty) const SizedBox(height: 1),
          if (entry.teacherName.isNotEmpty)
            Flexible(
              child: Text(
                entry.teacherName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 7,
                  color: Colors.black.withOpacity(0.5),
                  fontFamily: 'misaki',
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
              ? (noteText.length > 10
                  ? '${noteText.substring(0, 8)}…'
                  : noteText)
              : '',
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
    }
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
              child: Center(
                child: Text(
                  '${periodIndex + 1}\n${_periodTimes[periodIndex]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'misaki',
                    color: Colors.brown[800],
                    height: 1.2,
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
          ),
          ...List.generate(_days.length, (dayIndex) {
            String noteKey = "$_lunchPeriodKeyPrefix$dayIndex";
            String noteText = _cellNotes[noteKey] ?? '';
            return Expanded(
              flex: 1,
              child: InkWell(
                onTap: () {
                  _showNoteDialog(context, dayIndex);
                },
                child: Container(
                  margin: const EdgeInsets.all(0.5),
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen[100]?.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.green[300]!.withOpacity(0.6),
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

  Widget _buildTimetableBodyContent() {
    List<Widget> rows = [];
    for (int periodIdx = 0; periodIdx < 2; periodIdx++) {
      rows.add(_buildClassPeriodRow(periodIdx));
    }
    rows.add(_buildLunchRow());
    for (int periodIdx = 2; periodIdx < _academicPeriods; periodIdx++) {
      rows.add(_buildClassPeriodRow(periodIdx));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _buildDailyMemoSection() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 10.0,
        left: 4.0,
        right: 4.0,
        bottom: 6.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "今日のタスク / メモ 📝",
            style: TextStyle(
              fontSize: 15,
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
          SizedBox(height: 5),
          Container(
            height: 65,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.brown[300]!),
            ),
            child: TextField(
              maxLines: null,
              expands: true,
              style: TextStyle(
                fontFamily: 'misaki',
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

  // ★★★ TimeSchedulePageのbuildメソッド全体をこちらに置き換えてください ★★★
  @override
  Widget build(BuildContext context) {
    // CommonBottomNavigationの高さに合わせて調整
    final double bottomNavBarHeight = 95.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _weekDateRange.isEmpty
              ? _mainCharacterName
              : "$_mainCharacterName ($_weekDateRange)",
          style: const TextStyle(
            fontFamily: 'misaki',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
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

      // ★★★ 1. ここにあった bottomNavigationBar プロパティは削除します ★★★
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/question_background_image.png"),
            fit: BoxFit.cover,
          ),
        ),
        // ★★★ 2. Containerの子をStackにして、コンテンツとナビゲーションバーを重ねます ★★★
        child: Stack(
          children: [
            // --- レイヤー1: 元々のページコンテンツ ---
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
                          Container(
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
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: _buildTimetableBodyContent(),
                          ),
                          _buildDailyMemoSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ★★★ 3. レイヤー2: フローティングナビゲーションバー ★★★
            Positioned(
              bottom: 30,
              left: 40,
              right: 40,
              child: CommonBottomNavigation(
                currentPage: AppPage.timetable, // このページの種別を指定
                // --- アイコンのパスを指定 ---
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

                // --- タップ時の処理 ---
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
