import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math'; // Random のために必要
import 'dart:ui';
import 'package:intl/intl.dart'; // DateFormat のために必要
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
  final int dayOfWeek; // 月曜日を1, 日曜日を7とする
  final int period; // 時限
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
    dayOfWeek: 1, // 月曜日
    period: 1,
    color: Colors.blue[300]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '2',
    subjectName: "プログラミング演習",
    classroom: "PC室3",
    dayOfWeek: 1, // 月曜日
    period: 2,
    color: Colors.green[300]!,
    initialPolicy: AttendancePolicy.flexible,
  ),
  TimetableEntry(
    id: '3',
    subjectName: "線形代数学",
    classroom: "B-205",
    dayOfWeek: 2, // 火曜日
    period: 3,
    color: Colors.red[300]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '4',
    subjectName: "基礎物理学",
    classroom: "C-102",
    dayOfWeek: 3, // 水曜日
    period: 4,
    color: Colors.purple[300]!,
    initialPolicy: AttendancePolicy.flexible,
  ),
  TimetableEntry(
    id: '5',
    subjectName: "英語コミュニケーション",
    classroom: "D-301",
    dayOfWeek: 4, // 木曜日
    period: 5,
    color: Colors.orange[300]!,
    initialPolicy: AttendancePolicy.skip,
  ),
  TimetableEntry(
    id: '6',
    subjectName: "スポーツ科学",
    classroom: "体育館",
    dayOfWeek: 5, // 金曜日
    period: 1,
    color: Colors.lightBlue[300]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
  TimetableEntry(
    id: '7',
    subjectName: "現代経済学",
    classroom: "E-101",
    dayOfWeek: 2, // 火曜日
    period: 1,
    color: Colors.teal[300]!,
    initialPolicy: AttendancePolicy.mandatory,
  ),
];

class TimeSchedulePage extends StatefulWidget {
  const TimeSchedulePage({super.key});

  @override
  State<TimeSchedulePage> createState() => _TimeSchedulePageState();
}

class _TimeSchedulePageState extends State<TimeSchedulePage> {
  final List<String> _daysOfWeek = ['月', '火', '水', '木', '金']; // 表示する曜日
  final int _maxPeriods = 6; // 1日の最大時限数

  // 出席状況を保持するMap<entryId, status>
  final Map<String, AttendanceStatus> _attendanceStatus = {};
  // 各時限の出欠入力状況を追跡するMap<String: 'day_period', bool: isFilled>
  // 例: {'1_1': true} // 月曜1時限目が入力済み
  final Map<String, bool> _attendanceFilled = {};

  // CharacterProviderのインスタンスを保持
  late CharacterProvider _characterProvider;

  @override
  void initState() {
    super.initState();
    // モックデータに基づいて初期の出欠状況を設定
    for (var entry in mockTimetable) {
      _attendanceStatus[entry.id] = AttendanceStatus.none;
      _attendanceFilled['${entry.dayOfWeek}_${entry.period}'] = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Providerのインスタンスをここで取得
    _characterProvider = Provider.of<CharacterProvider>(context, listen: false);
  }

  // 出席状況を更新し、経験値を付与する関数
  void _updateAttendanceStatus(
      TimetableEntry entry, AttendanceStatus newStatus) {
    setState(() {
      _attendanceStatus[entry.id] = newStatus;
      // 入力済みマークを更新 (実際のアプリでは日付情報も考慮するべき)
      _attendanceFilled['${entry.dayOfWeek}_${entry.period}'] = true;

      // 経験値付与ロジック
      double experienceGained = 0;
      switch (newStatus) {
        case AttendanceStatus.present:
          experienceGained = 10.0; // 出席で10経験値
          break;
        case AttendanceStatus.late:
          experienceGained = 5.0; // 遅刻で5経験値
          break;
        case AttendanceStatus.absent:
          experienceGained = 0.0; // 欠席では経験値なし
          break;
        case AttendanceStatus.none:
          break; // 未選択では経験値なし
      }
      if (experienceGained > 0) {
        _characterProvider.addExperience(experienceGained as int);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${experienceGained.toInt()} 経験値を獲得！')),
        );
      }
    });
  }

  // 出席状況の選択肢を返す
  List<Widget> _buildAttendanceOptions(
      TimetableEntry entry, AttendanceStatus currentStatus) {
    return AttendanceStatus.values
        .where((status) => status != AttendanceStatus.none) // 'None'は選択肢に表示しない
        .map((status) => GestureDetector(
              onTap: () {
                _updateAttendanceStatus(entry, status);
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: currentStatus == status ? Colors.blue[100] : Colors.white,
                alignment: Alignment.center,
                child: Text(
                  _getAttendanceStatusText(status),
                  style: TextStyle(
                    color: currentStatus == status ? Colors.blue[900] : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ))
        .toList();
  }

  String _getAttendanceStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return '出席';
      case AttendanceStatus.absent:
        return '欠席';
      case AttendanceStatus.late:
        return '遅刻';
      case AttendanceStatus.none:
      default:
        return '未選択';
    }
  }

  // 時限ボックスの背景色を決定するヘルパー関数
  Color _getPeriodBoxColor(int day, int period) {
    final bool isFilled = _attendanceFilled['${day}_$period'] ?? false;
    return isFilled ? Colors.lightGreen[100]! : Colors.white; // 入力済みなら薄い緑、そうでなければ白
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // AppBarの背景をBodyコンテンツに拡張
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBarの背景を透明に
        elevation: 0, // 影をなくす
        title: const Text(
          '時間割',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/timetable_bg.png'), // あなたの背景画像パス
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            color: Colors.black.withOpacity(0.2), // ぼかしの強度を調整
            child: Column(
              children: <Widget>[
                const SizedBox(height: kToolbarHeight + 20), // AppBarの高さ分スペースを確保
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // 横スクロール可能にする
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 曜日ヘッダー
                        Row(
                          children: [
                            Container(
                              width: 60, // 時限数表示のためのスペース
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8),
                              child: const Text(
                                '',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            ..._daysOfWeek.map((day) => Container(
                                  width: 150, // 曜日カラムの幅
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    day,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 18),
                                  ),
                                )),
                          ],
                        ),
                        // 時間割コンテンツ
                        Expanded(
                          child: Row(
                            children: [
                              // 時限数表示
                              Column(
                                children: List.generate(_maxPeriods, (periodIndex) {
                                  return Container(
                                    height: 100, // 時限ボックスの高さ
                                    width: 60,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[400]!),
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    child: Text(
                                      '${periodIndex + 1}', // 1時限から表示
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  );
                                }),
                              ),
                              // 各曜日の時限
                              Flexible(
                                child: Row(
                                  children: _daysOfWeek.asMap().entries.map((entry) {
                                    final dayIndex = entry.key + 1; // 月曜日を1とする
                                    return SizedBox(
                                      width: 150, // 曜日カラムの幅に合わせる
                                      child: Column(
                                        children: List.generate(_maxPeriods, (periodIndex) {
                                          final period = periodIndex + 1; // 1時限から
                                          final List<TimetableEntry> entries =
                                              mockTimetable
                                                  .where((e) =>
                                                      e.dayOfWeek == dayIndex &&
                                                      e.period == period)
                                                  .toList();
                                          return _buildPeriodCell(
                                              entries.isNotEmpty ? entries.first : null);
                                        }),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 共通フッター
                Align(
                  alignment: Alignment.bottomCenter,
                  child: CommonBottomNavigation(
                    currentPage: AppPage.timetable,
                    parkIconAsset: 'assets/icons/park_icon.png',
                    parkIconActiveAsset: 'assets/icons/park_icon_active.png',
                    timetableIconAsset: 'assets/icons/timetable_icon.png',
                    timetableIconActiveAsset:
                        'assets/icons/timetable_icon_active.png',
                    creditReviewIconAsset: 'assets/icons/credit_review_icon.png',
                    creditReviewActiveAsset:
                        'assets/icons/credit_review_icon_active.png',
                    rankingIconAsset: 'assets/icons/ranking_icon.png',
                    rankingIconActiveAsset: 'assets/icons/ranking_icon_active.png',
                    itemIconAsset: 'assets/icons/item_icon.png',
                    itemIconActiveAsset: 'assets/icons/item_icon_active.png',
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
                          pageBuilder: (_, __, ___) => const CreditReviewPage(
                            lectureName: 'ダミー講義名',
                            teacherName: 'ダミー教員名', // 追加
                          ),
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
        ),
      ),
    );
  }

  // 時限ごとのセルを構築するウィジェット
  Widget _buildPeriodCell(TimetableEntry? entry) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: entry?.color.withOpacity(0.9) ?? Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blueAccent[100]!, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: entry != null
                ? () {
                    _showLectureDetailDialog(context, entry);
                  }
                : null, // 授業がない場合はタップ不可
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  entry?.subjectName ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: entry != null ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLectureDetailDialog(BuildContext context, TimetableEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currentStatus = _attendanceStatus[entry.id] ?? AttendanceStatus.none;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.blueAccent[100]!, width: 2),
          ),
          backgroundColor: Colors.white.withOpacity(0.95),
          title: Text(
            entry.subjectName,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('教室: ${entry.classroom}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(
                '出席ポリシー: ${_getAttendancePolicyText(entry.initialPolicy)}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text('出席状況を選択:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              Column(
                children: _buildAttendanceOptions(entry, currentStatus),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('閉じる', style: TextStyle(color: Colors.blue, fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getAttendancePolicyText(AttendancePolicy policy) {
    switch (policy) {
      case AttendancePolicy.mandatory:
        return '必須';
      case AttendancePolicy.flexible:
        return '柔軟';
      case AttendancePolicy.skip:
        return 'スキップ可能';
      case AttendancePolicy.none:
      default:
        return '不明';
    }
  }
}

// SlantedClipper クラス（変更なし）
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
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}