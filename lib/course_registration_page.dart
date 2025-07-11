import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'timetable_entry.dart';

class CourseRegistrationPage extends StatefulWidget {
  const CourseRegistrationPage({super.key});

  @override
  State<CourseRegistrationPage> createState() => _CourseRegistrationPageState();
}

class _CourseRegistrationPageState extends State<CourseRegistrationPage> {
  final List<String> _days = const ['月', '火', '水', '木', '金', '土', '日'];
  final int _academicPeriods = 6;

  // 学部リスト
  final List<String> _facultyList = [
    '文学部',
    '教育学部',
    '法学部',
    '経済学部',
    '理学部',
    '医学部',
    '歯学部',
    '薬学部',
    '工学部',
    '農学部',
    '獣医学部',
    '水産学部',
    '芸術学部',
    'スポーツ科学部',
    '国際教養学部',
    '情報科学部',
    '環境学部',
    '看護学部',
    '福祉学部',
    'その他',
  ];

  // 分散協力型データベース用: 全ユーザーの講義データ（オートコンプリート用）
  List<Map<String, dynamic>> _globalCourseData = [];

  // ユーザーの登録済み講義
  List<TimetableEntry> _userCourses = [];

  // ローディング状態
  bool _isLoading = true;
  bool _isSaving = false;

  // 講義登録用コントローラー
  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _classroomController = TextEditingController();
  String _selectedFaculty = '';
  int _selectedDay = 0;
  int _selectedPeriod = 1;

  // 検索フィルター
  String _searchQuery = '';
  String _selectedFacultyFilter = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  // データ読み込み
  Future<void> _loadData() async {
    print('_loadData開始');
    setState(() {
      _isLoading = true;
    });

    try {
      print('Firebase接続テスト開始');
      await Future.wait([_loadGlobalCourseData(), _loadUserCourses()]);
      print('_loadData完了');
    } catch (e, stackTrace) {
      print('データ読み込みエラー: $e');
      print('スタックトレース: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 分散協力型データベースから講義データを読み込み
  Future<void> _loadGlobalCourseData() async {
    try {
      print('グローバルデータ読み込み開始');
      final snap =
          await FirebaseFirestore.instance.collection('globalCourses').get();

      if (mounted) {
        setState(() {
          _globalCourseData = snap.docs.map((doc) => doc.data()).toList();
        });
      }

      print('グローバル講義データ読み込み完了: ${_globalCourseData.length}件');
    } catch (e, stackTrace) {
      print('グローバルデータ読み込みエラー: $e');
      print('スタックトレース: $stackTrace');
      // エラーが発生しても空のリストで初期化
      if (mounted) {
        setState(() {
          _globalCourseData = [];
        });
      }
    }
  }

  // ユーザーの登録済み講義を読み込み
  Future<void> _loadUserCourses() async {
    print('ユーザーデータ読み込み開始');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('ユーザーがログインしていません');
      return;
    }

    try {
      print('ユーザーID: ${user.uid}');
      final docRef = FirebaseFirestore.instance
          .collection('universities')
          .doc('other')
          .collection('courses')
          .doc(user.uid);

      final snapshot = await docRef.get();
      print('ドキュメント存在: ${snapshot.exists}');

      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!.containsKey('courses')) {
        final List<dynamic> data = snapshot.data()!['courses'];
        print('取得したデータ数: ${data.length}');
        final List<TimetableEntry> courses = [];

        for (int i = 0; i < data.length; i++) {
          final item = data[i];
          try {
            print('データ${i}を変換中: $item');
            final course = TimetableEntry.fromMap(
              Map<String, dynamic>.from(item),
            );
            courses.add(course);
            print('データ${i}変換成功');
          } catch (e, stackTrace) {
            print('講義データ${i}の変換エラー: $e');
            print('スタックトレース: $stackTrace');
            print('問題のデータ: $item');
            // エラーが発生した講義はスキップ
            continue;
          }
        }

        if (mounted) {
          setState(() {
            _userCourses = courses;
          });
        }
      } else {
        print('データが存在しないか、coursesフィールドがありません');
        if (mounted) {
          setState(() {
            _userCourses = [];
          });
        }
      }

      print('ユーザー講義データ読み込み完了: ${_userCourses.length}件');
    } catch (e, stackTrace) {
      print('ユーザーデータ読み込みエラー: $e');
      print('スタックトレース: $stackTrace');
      if (mounted) {
        setState(() {
          _userCourses = [];
        });
      }
    }
  }

  // 講義名の標準化
  String _normalizeSubjectName(String subjectName) {
    String normalized = subjectName.trim().toLowerCase();
    normalized = normalized
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('　', ' ')
        .replaceAll('  ', ' ');
    return normalized;
  }

  // オートコンプリート候補を取得
  List<String> _getAutocompleteSuggestions(String query) {
    if (query.isEmpty) return [];

    final normalizedQuery = _normalizeSubjectName(query);
    final suggestions = <String>[];

    for (final course in _globalCourseData) {
      final subjectName = course['subjectName'] ?? '';
      final normalizedName = course['normalizedName'] ?? '';

      if (normalizedName.contains(normalizedQuery) ||
          subjectName.toLowerCase().contains(normalizedQuery)) {
        suggestions.add(subjectName);
      }
    }

    // 使用回数でソート（人気順）
    suggestions.sort((a, b) {
      final aCourse = _globalCourseData.firstWhere(
        (course) => course['subjectName'] == a,
        orElse: () => {'usageCount': 0},
      );
      final bCourse = _globalCourseData.firstWhere(
        (course) => course['subjectName'] == b,
        orElse: () => {'usageCount': 0},
      );
      return (bCourse['usageCount'] ?? 0).compareTo(aCourse['usageCount'] ?? 0);
    });

    return suggestions.take(10).toList();
  }

  // ランダムな色を生成
  Color _getRandomColor() {
    final colors = [
      const Color(0xFF00E5FF), // cyanAccent
      const Color(0xFF69F0AE), // greenAccent[400]
      const Color(0xFFFFFF00), // yellowAccent
      const Color(0xFFE1BEE7), // purpleAccent[100]
      const Color(0xFFFFFFFF), // white
      const Color(0xFF40C4FF), // lightBlueAccent
      const Color(0xFF76FF03), // limeAccent[400]
    ];
    return colors[Random().nextInt(colors.length)];
  }

  // 分散協力型データベースに保存
  Future<void> _saveToGlobalDatabase(Map<String, dynamic> courseData) async {
    try {
      final normalizedName = _normalizeSubjectName(
        courseData['subjectName'] ?? '',
      );
      final globalDocRef = FirebaseFirestore.instance
          .collection('globalCourses')
          .doc(normalizedName);

      await globalDocRef.set({
        'subjectName': courseData['subjectName'],
        'normalizedName': normalizedName,
        'teacherName': courseData['originalLocation'], // 教員名フィールドを修正
        'faculty': courseData['faculty'],
        'classroom': courseData['classroom'],
        'lastUpdated': DateTime.now().toIso8601String(),
        'usageCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      print('グローバルデータベースに保存完了');
    } catch (e) {
      print('グローバルデータベース保存エラー: $e');
      rethrow; // エラーを再スロー
    }
  }

  // 講義を登録（分散協力型データベースにも保存）
  Future<void> _addCourse() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('授業名を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      final courseId = DateTime.now().millisecondsSinceEpoch.toString();

      // 分散協力型データベース用の拡張データを作成
      final extendedData = {
        'id': courseId,
        'subjectName': _subjectController.text.trim(),
        'classroom': _classroomController.text.trim(),
        'originalLocation':
            _teacherController.text.trim(), // TimetableEntryの期待するフィールド名
        'faculty': _selectedFaculty,
        'dayOfWeek': _selectedDay,
        'period': _selectedPeriod,
        'date': '',
        'color': _getRandomColor().value,
        'isCancelled': false,
        'initialPolicy': 1, // AttendancePolicy.flexible
        'attendanceCount': 0,
        'attitude': 0, // AttendanceAttitude.everytime
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      print('保存するデータ: $extendedData');

      // ユーザー固有のコースデータを保存
      final docRef = FirebaseFirestore.instance
          .collection('universities')
          .doc('other')
          .collection('courses')
          .doc(user.uid);

      final snapshot = await docRef.get();
      List<dynamic> courses = [];
      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!.containsKey('courses')) {
        courses = List.from(snapshot.data()!['courses']);
      }

      courses.add(extendedData);
      await docRef.set({'courses': courses}, SetOptions(merge: true));

      print('Firestoreに保存完了');

      // 分散協力型データベースに拡張データを保存
      try {
        await _saveToGlobalDatabase(extendedData);
        print('グローバルデータベースに保存完了');
      } catch (e) {
        print('グローバルデータベース保存エラー（無視）: $e');
      }

      // データを再読み込み
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('講義を登録しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('講義登録エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('講義の登録に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 選択した曜日・コマに既に講義が登録されているかをチェック
  bool _isCourseRegisteredAtTime(int dayOfWeek, int period) {
    return _userCourses.any(
      (course) => course.dayOfWeek == dayOfWeek && course.period == period,
    );
  }

  // 既存の講義をカレンダーに追加（必要に応じて講義登録も行う）
  Future<void> _addExistingCourse(TimetableEntry course) async {
    try {
      // 曜日・時限選択ダイアログを表示
      int selectedDay = course.dayOfWeek;
      int selectedPeriod = course.period;

      final result = await showDialog<Map<String, int>>(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: Text(
                    '「${course.subjectName}」をカレンダーに追加',
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 曜日選択
                      DropdownButtonFormField<int>(
                        value: selectedDay,
                        items: List.generate(7, (index) {
                          return DropdownMenuItem(
                            value: index,
                            child: Text(
                              _days[index],
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDay = value!;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: '曜日',
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue[400]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800]!.withOpacity(0.5),
                        ),
                        dropdownColor: Colors.grey[900],
                      ),
                      const SizedBox(height: 16),
                      // 時限選択
                      DropdownButtonFormField<int>(
                        value: selectedPeriod,
                        items: List.generate(6, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              '${index + 1}限',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPeriod = value!;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: '時限',
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue[400]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800]!.withOpacity(0.5),
                        ),
                        dropdownColor: Colors.grey[900],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop({'day': selectedDay, 'period': selectedPeriod});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                      ),
                      child: const Text('カレンダーに追加'),
                    ),
                  ],
                );
              },
            ),
      );

      if (result != null) {
        final selectedDay = result['day']!;
        final selectedPeriod = result['period']!;

        // 選択した曜日・コマに既に講義が登録されているかをチェック
        final isAlreadyRegistered = _isCourseRegisteredAtTime(
          selectedDay,
          selectedPeriod,
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('ユーザーがログインしていません');

        final courseId = DateTime.now().millisecondsSinceEpoch.toString();

        if (isAlreadyRegistered) {
          // 既に講義が登録されている場合は、カレンダーにのみ追加
          print('選択した曜日・コマには既に講義が登録されています。カレンダーにのみ追加します。');

          // カレンダー用の講義データを作成
          final calendarCourseData = {
            'id': courseId,
            'subjectName': course.subjectName,
            'classroom': course.classroom,
            'originalLocation': course.originalLocation,
            'faculty': course.faculty ?? '',
            'dayOfWeek': selectedDay,
            'period': selectedPeriod,
            'date': '',
            'color': _getRandomColor().value,
            'isCancelled': false,
            'initialPolicy': 1,
            'attendanceCount': 0,
            'attitude': 0,
            'lastUpdated': DateTime.now().toIso8601String(),
            'isCalendarOnly': true,
          };

          // カレンダー専用のコレクションに保存
          final calendarDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('calendar')
              .doc('courses');

          final calendarSnapshot = await calendarDocRef.get();
          List<dynamic> calendarCourses = [];
          if (calendarSnapshot.exists &&
              calendarSnapshot.data() != null &&
              calendarSnapshot.data()!.containsKey('courses')) {
            calendarCourses = List.from(calendarSnapshot.data()!['courses']);
          }

          calendarCourses.add(calendarCourseData);
          await calendarDocRef.set({
            'courses': calendarCourses,
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '「${course.subjectName}」をカレンダーの${_days[selectedDay]}曜${selectedPeriod}限に追加しました',
              ),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          // 講義が登録されていない場合は、講義登録も行う
          print('選択した曜日・コマには講義が登録されていません。講義登録も行います。');

          // 講義登録用のデータを作成
          final courseData = {
            'id': courseId,
            'subjectName': course.subjectName,
            'classroom': course.classroom,
            'originalLocation': course.originalLocation,
            'faculty': course.faculty ?? '',
            'dayOfWeek': selectedDay,
            'period': selectedPeriod,
            'date': '',
            'color': _getRandomColor().value,
            'isCancelled': false,
            'initialPolicy': 1,
            'attendanceCount': 0,
            'attitude': 0,
            'lastUpdated': DateTime.now().toIso8601String(),
          };

          // 講義登録用のコレクションに保存
          final docRef = FirebaseFirestore.instance
              .collection('universities')
              .doc('other')
              .collection('courses')
              .doc(user.uid);

          final snapshot = await docRef.get();
          List<dynamic> courses = [];
          if (snapshot.exists &&
              snapshot.data() != null &&
              snapshot.data()!.containsKey('courses')) {
            courses = List.from(snapshot.data()!['courses']);
          }

          courses.add(courseData);
          await docRef.set({'courses': courses}, SetOptions(merge: true));

          // 分散協力型データベースにも保存
          try {
            await _saveToGlobalDatabase(courseData);
            print('分散協力型データベースにも保存完了');
          } catch (e) {
            print('分散協力型データベース保存エラー（無視）: $e');
          }

          // カレンダーにも追加
          final calendarCourseData = {
            'id': courseId,
            'subjectName': course.subjectName,
            'classroom': course.classroom,
            'originalLocation': course.originalLocation,
            'faculty': course.faculty ?? '',
            'dayOfWeek': selectedDay,
            'period': selectedPeriod,
            'date': '',
            'color': _getRandomColor().value,
            'isCancelled': false,
            'initialPolicy': 1,
            'attendanceCount': 0,
            'attitude': 0,
            'lastUpdated': DateTime.now().toIso8601String(),
            'isCalendarOnly': true,
          };

          final calendarDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('calendar')
              .doc('courses');

          final calendarSnapshot = await calendarDocRef.get();
          List<dynamic> calendarCourses = [];
          if (calendarSnapshot.exists &&
              calendarSnapshot.data() != null &&
              calendarSnapshot.data()!.containsKey('courses')) {
            calendarCourses = List.from(calendarSnapshot.data()!['courses']);
          }

          calendarCourses.add(calendarCourseData);
          await calendarDocRef.set({
            'courses': calendarCourses,
          }, SetOptions(merge: true));

          // データを再読み込み
          await _loadData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '「${course.subjectName}」を講義登録し、カレンダーの${_days[selectedDay]}曜${selectedPeriod}限に追加しました',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('カレンダー追加エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('カレンダーへの追加に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 講義の詳細を表示し、単位レビューへのナビゲーションを提供
  void _showCourseDetail(TimetableEntry course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[700]!, width: 2),
            ),
            child: Column(
              children: [
                // ヘッダー
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[600]!.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    '講義詳細',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Noto Sans JP',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // コンテンツ
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 講義名
                        _buildDetailRow(
                          '講義名',
                          course.subjectName,
                          Icons.school,
                        ),
                        const SizedBox(height: 16),
                        // 教員名
                        _buildDetailRow(
                          '教員名',
                          course.originalLocation.isNotEmpty
                              ? course.originalLocation
                              : '未設定',
                          Icons.person,
                        ),
                        const SizedBox(height: 16),
                        // 教室
                        _buildDetailRow(
                          '教室',
                          course.classroom.isNotEmpty
                              ? course.classroom
                              : '未設定',
                          Icons.room,
                        ),
                        const SizedBox(height: 16),
                        // 曜日・時限
                        _buildDetailRow(
                          '曜日・時限',
                          '${_days[course.dayOfWeek]}曜 ${course.period}限',
                          Icons.schedule,
                        ),
                        const SizedBox(height: 16),
                        // 学部
                        if (course.faculty != null &&
                            course.faculty!.isNotEmpty)
                          _buildDetailRow(
                            '学部',
                            course.faculty!,
                            Icons.business,
                          ),
                        if (course.faculty != null &&
                            course.faculty!.isNotEmpty)
                          const SizedBox(height: 16),
                        // 単位レビュー情報へのリンク
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[600]!.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue[400]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.rate_review,
                                    color: Colors.blue[400],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '単位レビュー情報',
                                    style: TextStyle(
                                      color: Colors.blue[400],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'この講義の単位取得難易度、評価方法、先輩からのアドバイスなどを確認できます。',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ボタン
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            '閉じる',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Noto Sans JP',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _navigateToUnitReview(course);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            '単位レビューを見る',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Noto Sans JP',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 詳細行を構築
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange[400], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 単位レビューページにナビゲート
  void _navigateToUnitReview(TimetableEntry course) {
    // 単位レビューページに遷移
    // ここで適切なページに遷移するロジックを実装
    Navigator.pushNamed(
      context,
      '/unit-review',
      arguments: {
        'courseName': course.subjectName,
        'teacherName': course.originalLocation,
        'faculty': course.faculty,
      },
    );
  }

  // 講義を削除
  Future<void> _deleteCourse(String courseId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      final docRef = FirebaseFirestore.instance
          .collection('universities')
          .doc('other')
          .collection('courses')
          .doc(user.uid);

      final snapshot = await docRef.get();
      List<dynamic> courses = [];
      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!.containsKey('courses')) {
        courses = List.from(snapshot.data()!['courses']);
      }

      courses.removeWhere((e) => e['id'] == courseId);
      await docRef.set({'courses': courses}, SetOptions(merge: true));

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('講義を削除しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('講義削除エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('講義の削除に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // フィルタリングされた講義リストを取得
  List<TimetableEntry> get _filteredCourses {
    return _userCourses.where((course) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          course.subjectName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          course.originalLocation.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          course.classroom.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFaculty =
          _selectedFacultyFilter.isEmpty ||
          course.faculty == _selectedFacultyFilter;

      return matchesSearch && matchesFaculty;
    }).toList();
  }

  // 講義登録ダイアログを表示
  Future<void> _showAddCourseDialog() async {
    // コントローラーをリセット
    _subjectController.clear();
    _teacherController.clear();
    _classroomController.clear();
    _selectedFaculty = '';
    _selectedDay = 0;
    _selectedPeriod = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[700]!, width: 2),
                ),
                child: Column(
                  children: [
                    // ヘッダー
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[600]!.withOpacity(0.8),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: const Text(
                        '講義を登録',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Sans JP',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // コンテンツ
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // 授業名（分散協力型オートコンプリート）
                            Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              child: Autocomplete<String>(
                                optionsBuilder: (text) {
                                  if (text.text.isEmpty) return [];
                                  return _getAutocompleteSuggestions(text.text);
                                },
                                onSelected: (v) => _subjectController.text = v,
                                fieldViewBuilder: (
                                  context,
                                  controller,
                                  focus,
                                  onFieldSubmitted,
                                ) {
                                  return TextField(
                                    controller: _subjectController,
                                    focusNode: focus,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: '授業名（全国のユーザーと共有）',
                                      labelStyle: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                      hintText: '既存の講義名が候補として表示されます',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: Colors.grey[600]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: Colors.blue[400]!,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[800]!.withOpacity(
                                        0.5,
                                      ),
                                      suffixIcon: Icon(
                                        Icons.people,
                                        color: Colors.blue[400],
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // 教員名
                            Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              child: TextField(
                                controller: _teacherController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: '教員名',
                                  labelStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey[600]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.blue[400]!,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[800]!.withOpacity(0.5),
                                ),
                              ),
                            ),
                            // 学部選択
                            Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              child: DropdownButtonFormField<String>(
                                value:
                                    _selectedFaculty.isNotEmpty
                                        ? _selectedFaculty
                                        : null,
                                items:
                                    _facultyList.map((faculty) {
                                      return DropdownMenuItem(
                                        value: faculty,
                                        child: Text(
                                          faculty,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedFaculty = value ?? '';
                                  });
                                },
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: '学部',
                                  labelStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey[600]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.blue[400]!,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[800]!.withOpacity(0.5),
                                ),
                                dropdownColor: Colors.grey[900],
                              ),
                            ),
                            // 教室
                            Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              child: TextField(
                                controller: _classroomController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: '教室',
                                  labelStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey[600]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.blue[400]!,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[800]!.withOpacity(0.5),
                                ),
                              ),
                            ),
                            // 曜日・時限選択
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 15,
                                      right: 8,
                                    ),
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedDay,
                                      items:
                                          _days.asMap().entries.map((entry) {
                                            return DropdownMenuItem(
                                              value: entry.key,
                                              child: Text(
                                                '${entry.value}曜',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          _selectedDay = value ?? 0;
                                        });
                                      },
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: '曜日',
                                        labelStyle: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[600]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.blue[400]!,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[800]!
                                            .withOpacity(0.5),
                                      ),
                                      dropdownColor: Colors.grey[900],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 15,
                                      left: 8,
                                    ),
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedPeriod,
                                      items: List.generate(_academicPeriods, (
                                        i,
                                      ) {
                                        return DropdownMenuItem(
                                          value: i + 1,
                                          child: Text(
                                            '${i + 1}限',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          _selectedPeriod = value ?? 1;
                                        });
                                      },
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: '時限',
                                        labelStyle: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[600]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.blue[400]!,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[800]!
                                            .withOpacity(0.5),
                                      ),
                                      dropdownColor: Colors.grey[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ボタン
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'キャンセル',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Noto Sans JP',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isSaving
                                      ? null
                                      : () async {
                                        await _addCourse();
                                        Navigator.of(context).pop();
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        '登録',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Noto Sans JP',
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('CourseRegistrationPage build開始');
    try {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          title: const Text(
            '講義登録',
            style: TextStyle(color: Colors.white, fontFamily: 'Noto Sans JP'),
          ),
          backgroundColor: Colors.blue[600],
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                try {
                  _loadData();
                } catch (e) {
                  print('リフレッシュエラー: $e');
                }
              },
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
                : Column(
                  children: [
                    // 検索・フィルター
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 検索バー
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '講義名、教員名、教室で検索',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[600]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.blue[400]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[800]!.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // 学部フィルター
                          DropdownButtonFormField<String>(
                            value:
                                _selectedFacultyFilter.isEmpty
                                    ? null
                                    : _selectedFacultyFilter,
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text(
                                  '全学部',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              ..._facultyList.map((faculty) {
                                return DropdownMenuItem(
                                  value: faculty,
                                  child: Text(
                                    faculty,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedFacultyFilter = value ?? '';
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: '学部で絞り込み',
                              labelStyle: const TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[600]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.blue[400]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[800]!.withOpacity(0.5),
                            ),
                            dropdownColor: Colors.grey[900],
                          ),
                        ],
                      ),
                    ),
                    // 講義リスト
                    Expanded(
                      child:
                          _filteredCourses.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: 64,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isNotEmpty ||
                                              _selectedFacultyFilter.isNotEmpty
                                          ? '条件に一致する講義が見つかりません'
                                          : '登録された講義がありません',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '下のボタンから講義を登録してください',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _filteredCourses.length,
                                itemBuilder: (context, index) {
                                  final course = _filteredCourses[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    color: Colors.grey[850],
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        course.subjectName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                color: Colors.grey[400],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                course
                                                        .originalLocation
                                                        .isNotEmpty
                                                    ? course.originalLocation
                                                    : '教員名未設定',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.room,
                                                color: Colors.grey[400],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                course.classroom.isNotEmpty
                                                    ? course.classroom
                                                    : '教室未設定',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                color: Colors.grey[400],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_days[course.dayOfWeek]}曜 ${course.period}限',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (course.faculty != null &&
                                              course.faculty!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.school,
                                                  color: Colors.grey[400],
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  course.faculty!,
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 詳細を見るボタン
                                          IconButton(
                                            icon: const Icon(
                                              Icons.info_outline,
                                              color: Colors.orange,
                                            ),
                                            onPressed: () {
                                              _showCourseDetail(course);
                                            },
                                            tooltip: '詳細を見る',
                                          ),
                                          const SizedBox(width: 4),
                                          // カレンダーに追加するボタン
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              _addExistingCourse(course);
                                            },
                                            icon: const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'カレンダーに追加',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Noto Sans JP',
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[600],
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // 削除ボタン
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      backgroundColor:
                                                          Colors.grey[900],
                                                      title: const Text(
                                                        '講義を削除',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      content: Text(
                                                        '「${course.subjectName}」を削除しますか？',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                          child: const Text(
                                                            'キャンセル',
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                            _deleteCourse(
                                                              course.id,
                                                            );
                                                          },
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                          child: const Text(
                                                            '削除',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            try {
              _showAddCourseDialog();
            } catch (e) {
              print('ダイアログ表示エラー: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('エラーが発生しました: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          backgroundColor: Colors.blue[600],
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            '講義を登録',
            style: TextStyle(color: Colors.white, fontFamily: 'Noto Sans JP'),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('CourseRegistrationPage build エラー: $e');
      print('スタックトレース: $stackTrace');
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          title: const Text(
            '講義登録',
            style: TextStyle(color: Colors.white, fontFamily: 'Noto Sans JP'),
          ),
          backgroundColor: Colors.blue[600],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            'エラーが発生しました。アプリを再起動してください。',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}
