import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timetable_entry.dart';
import 'timetable.dart';
import 'utils/course_pattern_detector.dart';
import 'utils/course_color_generator.dart';
import 'course_pattern.dart';
import 'providers/timetable_provider.dart';
import 'providers/global_course_mapping_provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuestCreationWidget extends ConsumerStatefulWidget {
  final void Function() onCancel;
  final void Function(
    Map<String, dynamic> selectedClass,
    String taskType,
    DateTime deadline,
    String description,
  )
  onCreate;

  const QuestCreationWidget({
    Key? key,
    required this.onCancel,
    required this.onCreate,
  }) : super(key: key);

  @override
  ConsumerState<QuestCreationWidget> createState() =>
      _QuestCreationWidgetState();
}

class _QuestCreationWidgetState extends ConsumerState<QuestCreationWidget> {
  List<TimetableEntry> _weeklyClasses = [];
  TimetableEntry? _selectedClass;
  String? _selectedTaskType;
  DateTime? _selectedDeadline;
  String _description = '';
  bool _isLoading = true;
  Map<String, Color> _courseColors = {};
  bool _hasShownDialog = false; // ダイアログ表示フラグ
  bool _isDataLoaded = false; // データ読み込みフラグ
  bool _firestoreLoaded = false;

  final List<String> taskTypes = ['レポート', '発表', 'その他'];

  // Provider経由でデータを取得
  Map<String, dynamic>? get selectedClass =>
      ref.watch(timetableProvider)['questSelectedClass'];
  String? get selectedTaskType => ref.watch(timetableProvider)['questTaskType'];
  DateTime? get selectedDeadline {
    final deadlineString = ref.watch(timetableProvider)['questDeadline'];
    return deadlineString != null ? DateTime.parse(deadlineString) : null;
  }

  String get description =>
      ref.watch(timetableProvider)['questDescription'] ?? '';

  @override
  void initState() {
    super.initState();
    print('Quest Create - initState called');
    _firestoreLoaded = false;
    _initializeData();
    _loadWeeklyClasses();
  }

  Future<void> _initializeData() async {
    print('Quest Create - Starting _initializeData');
    try {
      await ref.read(timetableProvider.notifier).loadFromFirestore();
      print('Quest Create - Firestore data loaded successfully');
      if (mounted) {
        setState(() {
          _firestoreLoaded = true;
        });
      }
    } catch (e) {
      print('Quest Create - Error loading Firestore data: $e');
      if (mounted) {
        setState(() {
          _firestoreLoaded = true; // エラーでもtrueにしてUIを表示
        });
      }
    }
  }

  Future<void> _loadWeeklyClasses() async {
    try {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));

      List<TimetableEntry> timeTableEntries = await getWeeklyTimetableEntries(
        monday,
      );

      // ★★★ courseIdを設定 ★★★
      for (var entry in timeTableEntries) {
        // 保存されたcourseIdを確認
        final savedCourseIds = ref.read(timetableProvider)['courseIds'] ?? {};
        String courseId;

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
      }

      // 授業判別と色分け
      List<CoursePattern> patterns = await CoursePatternDetector.detectPatterns(
        timeTableEntries,
      );
      Map<String, Color> courseColors = {};
      for (var pattern in patterns) {
        courseColors[pattern.courseId] =
            CourseColorGenerator.generateColorFromPattern(pattern.courseId);
      }

      setState(() {
        _weeklyClasses = timeTableEntries;
        _courseColors = courseColors;
        _isLoading = false;
      });
    } catch (e) {
      print('授業データの読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getCourseColor(TimetableEntry entry) {
    // time_schedule_page.dartと同じロジックで色を決定
    final List<Color> neonColors = [
      Colors.cyanAccent,
      Colors.greenAccent[400]!,
      Colors.yellowAccent,
      Colors.purpleAccent[100]!,
      Colors.white,
      Colors.lightBlueAccent,
      Colors.limeAccent[400]!,
    ];

    // courseIdがあればそれを使い、なければsubjectName+classroomの組み合わせ
    final String colorKey =
        entry.courseId ?? '${entry.subjectName}|${entry.classroom}';
    final int colorIndex = colorKey.hashCode % neonColors.length;
    return neonColors[colorIndex];
  }

  Future<void> _pickDateTime() async {
    DateTime selectedDateTime = _selectedDeadline ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDeadline = selectedDateTime;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('完了'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  use24hFormat: true,
                  initialDateTime: selectedDateTime,
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedDateTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTaskDetailsDialog() {
    if (selectedClass == null) return;

    // ダイアログ内での状態管理用の変数（既存データを初期値として使用）
    String? tempTaskType = selectedTaskType;
    DateTime? tempDeadline = selectedDeadline;
    String tempDescription = description;

    // TextEditingControllerを適切に管理
    final TextEditingController descriptionController = TextEditingController(
      text: tempDescription,
    );

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> pickDateTime() async {
                DateTime selectedDateTime = tempDeadline ?? DateTime.now();

                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return Container(
                      height: 300,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      tempDeadline = selectedDateTime;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('完了'),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.dateAndTime,
                              use24hFormat: true,
                              initialDateTime: selectedDateTime,
                              onDateTimeChanged: (DateTime newDateTime) {
                                selectedDateTime = newDateTime;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              return AlertDialog(
                title: const Text('課題の詳細'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('選択された授業: ${selectedClass!['subjectName']}'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "タスクの種類"),
                      value: tempTaskType,
                      items:
                          taskTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          tempTaskType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "課題の詳細 (任意)",
                        hintText: "(例) A4一枚、手書き、表紙必須",
                      ),
                      maxLines: 3,
                      controller: descriptionController,
                      onChanged: (value) {
                        setDialogState(() {
                          tempDescription = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tempDeadline != null
                                ? "${tempDeadline!.toLocal()}".split('.')[0]
                                : "締切日時を選択",
                          ),
                        ),
                        TextButton(
                          onPressed: pickDateTime,
                          child: const Text("選択"),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // キャンセル時にもデータをリセットしない（保持する）
                      _hasShownDialog = false; // フラグをリセット
                      Navigator.of(context).pop();
                    },
                    child: const Text("キャンセル"),
                  ),
                  ElevatedButton(
                    onPressed:
                        (tempTaskType != null && tempDeadline != null)
                            ? () async {
                              print('DEBUG: クエスト作成ボタンが押されました');

                              // 週のクエスト作成回数をチェック
                              final courseId =
                                  selectedClass!['courseId'] as String?;
                              if (courseId != null) {
                                final weeklyCount = await _getWeeklyQuestCount(
                                  courseId,
                                );
                                if (weeklyCount >= 2) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'この授業の今週のクエスト作成上限（2回）に達しています',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                  return;
                                }
                              }

                              print('DEBUG: クエスト作成を開始します');

                              // ★★★ 直接stateを更新するように修正 ★★★
                              final currentState = ref.read(timetableProvider);
                              ref.read(timetableProvider.notifier).state = {
                                ...currentState,
                                'questTaskType': tempTaskType,
                                'questDeadline': tempDeadline,
                                'questDescription': tempDescription,
                              };

                              print('DEBUG: widget.onCreateを呼び出します');
                              widget.onCreate(
                                selectedClass!,
                                tempTaskType!,
                                tempDeadline!,
                                tempDescription,
                              );

                              print('DEBUG: クエスト作成完了後、データをリセットします');
                              // クエスト作成完了後、データをリセット
                              ref
                                  .read(timetableProvider.notifier)
                                  .resetQuestData();
                              _hasShownDialog = false; // フラグをリセット

                              print('DEBUG: ダイアログを閉じます');
                              if (mounted) {
                                Navigator.of(context).pop();
                              }

                              print('DEBUG: クエスト作成処理完了');
                            }
                            : null,
                    child: const Text("作成"),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timetableData = ref.watch(timetableProvider);

    // 授業データの読み込みが終わるまでローディング
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // デバッグ用ログ出力
    print('Quest Create - Provider Data: $timetableData');
    print('Quest Create - selectedClass: $selectedClass');
    print('Quest Create - selectedTaskType: $selectedTaskType');
    print('Quest Create - selectedDeadline: $selectedDeadline');
    print('Quest Create - description: $description');
    print('Quest Create - _hasShownDialog: $_hasShownDialog');
    print('Quest Create - _firestoreLoaded: $_firestoreLoaded');

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "クエスト作成",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "課題を作成する授業を選択してください",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 既存データがある場合は情報を表示
            if (selectedClass != null &&
                selectedTaskType != null &&
                selectedDeadline != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '前回の入力内容:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '授業: ${selectedClass!['subjectName']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'タスク: $selectedTaskType',  
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '締切: ${selectedDeadline!.toLocal().toString().split('.')[0]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        '詳細: $description',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),

            // 一週間の授業コマ表示（時間割表形式）
            Container(
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ヘッダー行（曜日）
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: const Text(
                            '時限',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...List.generate(
                          5,
                          (dayIndex) => Expanded(
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: Text(
                                _getDayName(dayIndex),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 時限行
                    ...List.generate(
                      6,
                      (periodIndex) => Row(
                        children: [
                          // 時限番号
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: Text(
                              '${periodIndex + 1}限',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // 各曜日の授業
                          ...List.generate(5, (dayIndex) {
                            TimetableEntry? entry;
                            try {
                              entry = _weeklyClasses.firstWhere(
                                (e) =>
                                    e.dayOfWeek == dayIndex &&
                                    e.period == periodIndex + 1,
                              );
                            } catch (e) {
                              entry = null;
                            }

                            if (entry == null || entry.subjectName.isEmpty) {
                              return Expanded(
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final courseColor = _getCourseColor(entry);
                            final isSelected =
                                selectedClass?['id'] == entry.id ||
                                (selectedClass != null &&
                                    selectedTaskType != null &&
                                    selectedDeadline != null);

                            return Expanded(
                              child: InkWell(
                                onTap: () async {
                                  // 授業情報を更新
                                  // ★★★ 直接stateを更新するように修正 ★★★
                                  final currentState = ref.read(
                                    timetableProvider,
                                  );
                                  ref.read(timetableProvider.notifier).state = {
                                    ...currentState,
                                    'questSelectedClass': selectedClass,
                                  };

                                  print(
                                    'DEBUG: 授業タップ - ${entry?.subjectName}, courseId: ${entry?.courseId}',
                                  );

                                  // 最新クエストを検索（courseIdがnullの場合は従来の手動入力）
                                  if (entry?.courseId != null) {
                                    print('DEBUG: courseIdがあるため、過去のクエストを検索します');
                                    final latestQuests =
                                        await _getLatestQuestsForCourse(
                                          entry!.courseId!,
                                        );

                                    print(
                                      'DEBUG: 検索結果 - latestQuests: $latestQuests',
                                    );

                                    if (latestQuests.isNotEmpty) {
                                      print(
                                        'DEBUG: 過去のクエストが見つかりました。今週版作成ダイアログを表示します',
                                      );
                                      // 複数のクエストがある場合は選択ダイアログを表示
                                      if (latestQuests.length > 1) {
                                        _showQuestSelectionDialog(latestQuests);
                                      } else {
                                        // 単一のクエストの場合は今週版作成の確認ダイアログを表示
                                        _showWeeklyQuestConfirmationDialog(
                                          latestQuests.first,
                                        );
                                      }
                                    } else {
                                      print(
                                        'DEBUG: 過去のクエストが見つかりませんでした。手動入力画面を表示します',
                                      );
                                      // 最新クエストがない場合は従来の手動入力画面
                                      if (selectedTaskType != null &&
                                          selectedDeadline != null) {
                                        print(
                                          'Quest Create - Showing dialog with existing data for ${entry?.subjectName}',
                                        );
                                      } else {
                                        print(
                                          'Quest Create - Showing dialog for new quest for ${entry?.subjectName}',
                                        );
                                      }
                                      _showTaskDetailsDialog();
                                    }
                                  } else {
                                    print(
                                      'DEBUG: courseIdがnullのため、手動入力画面を表示します',
                                    );
                                    // courseIdがnullの場合は従来の手動入力画面
                                    if (selectedTaskType != null &&
                                        selectedDeadline != null) {
                                      print(
                                        'Quest Create - Showing dialog with existing data for ${entry?.subjectName}',
                                      );
                                    } else {
                                      print(
                                        'Quest Create - Showing dialog for new quest for ${entry?.subjectName}',
                                      );
                                    }
                                    _showTaskDetailsDialog();
                                  }
                                },
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          entry.subjectName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // クエスト作成画面を完全に閉じる時のみデータをリセット
                    ref.read(timetableProvider.notifier).resetQuestData();
                    _hasShownDialog = false; // フラグをリセット
                    widget.onCancel();
                  },
                  child: const Text("キャンセル"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = ['月', '火', '水', '木', '金', '土', '日'];
    return days[dayOfWeek];
  }

  // クエストの保存
  Future<void> _addGlobalQuest(
    String courseId,
    Map<String, dynamic> questData,
  ) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('quests')
        .add(questData);
  }

  // クエストの取得
  Future<List<Map<String, dynamic>>> _getGlobalQuests(String courseId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .collection('quests')
            .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // 最新クエストを取得（締切時間でグループ化して最大2つまで）
  Future<List<Map<String, dynamic>>> _getLatestQuestsForCourse(
    String courseId,
  ) async {
    try {
      print('DEBUG: _getLatestQuestsForCourse - courseId: $courseId');

      // まず、そのcourseIdでクエストが存在するかチェック
      final allQuestsSnapshot =
          await FirebaseFirestore.instance.collection('quests').get();

      print('DEBUG: 全クエスト数: ${allQuestsSnapshot.docs.length}');

      // 全クエストのcourseIdを確認
      for (var doc in allQuestsSnapshot.docs) {
        final questData = doc.data();
        final questCourseId = questData['courseId'] as String?;
        final questName = questData['name'] as String?;
        print('DEBUG: クエスト「$questName」のcourseId: $questCourseId');
      }

      // インデックスエラーを回避するため、orderByを削除してクライアント側でソート
      final snapshot =
          await FirebaseFirestore.instance
              .collection('quests')
              .where('courseId', isEqualTo: courseId)
              .get();

      print('DEBUG: クエスト検索結果 - ドキュメント数: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        // クライアント側でcreatedAtでソート
        final sortedDocs =
            snapshot.docs.toList()..sort((a, b) {
              final aCreatedAt = a.data()['createdAt'] as Timestamp?;
              final bCreatedAt = b.data()['createdAt'] as Timestamp?;
              if (aCreatedAt == null && bCreatedAt == null) return 0;
              if (aCreatedAt == null) return 1;
              if (bCreatedAt == null) return -1;
              return bCreatedAt.compareTo(aCreatedAt); // 降順（最新が先頭）
            });

        // 締切時間でグループ化
        final Map<String, Map<String, dynamic>> timeGroupedQuests = {};

        for (var doc in sortedDocs) {
          final questData = doc.data();
          final deadline = questData['deadline'] as Timestamp?;

          if (deadline != null) {
            final deadlineDate = deadline.toDate();
            // 締切時間をキーとして使用（時:分の形式）
            final timeKey =
                '${deadlineDate.hour.toString().padLeft(2, '0')}:${deadlineDate.minute.toString().padLeft(2, '0')}';

            // 同じ時間のクエストがまだない場合のみ追加
            if (!timeGroupedQuests.containsKey(timeKey)) {
              timeGroupedQuests[timeKey] = {'id': doc.id, ...questData};
              print('DEBUG: 時間グループ「$timeKey」にクエストを追加: ${questData['name']}');
            }
          }
        }

        // 最大2つまで返す
        final result = timeGroupedQuests.values.take(2).toList();
        print('DEBUG: 時間グループ化後のクエスト数: ${result.length}');

        return result;
      } else {
        print('DEBUG: 該当するクエストが見つかりませんでした');
      }
      return [];
    } catch (e) {
      print('Error getting latest quests: $e');
      return [];
    }
  }

  // 複数のクエスト履歴から選択するダイアログ
  void _showQuestSelectionDialog(List<Map<String, dynamic>> quests) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('今週版クエスト作成'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '過去のクエスト履歴から選択してください：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...quests.map((quest) {
                  final subjectName = quest['name'] as String? ?? '不明な授業';
                  final taskType = quest['taskType'] as String? ?? '課題';
                  final description = quest['description'] as String? ?? '';
                  final deadline = quest['deadline'] as Timestamp?;

                  String deadlineText = '期限なし';
                  if (deadline != null) {
                    final deadlineDate = deadline.toDate();
                    deadlineText =
                        '${deadlineDate.hour.toString().padLeft(2, '0')}:${deadlineDate.minute.toString().padLeft(2, '0')}締切';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(subjectName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('種類: $taskType'),
                          Text('期限: $deadlineText'),
                          if (description.isNotEmpty)
                            Text(
                              '詳細: $description',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showWeeklyQuestConfirmationDialog(quest);
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // キャンセル時は従来の手動入力画面を表示
                  _showTaskDetailsDialog();
                },
                child: const Text('キャンセル'),
              ),
            ],
          ),
    );
  }

  // 今週版クエスト作成の確認ダイアログ
  void _showWeeklyQuestConfirmationDialog(Map<String, dynamic> latestQuest) {
    final subjectName = latestQuest['name'] as String? ?? '不明な授業';
    final taskType = latestQuest['taskType'] as String? ?? '課題';
    final description = latestQuest['description'] as String? ?? '';
    final deadline = latestQuest['deadline'] as Timestamp?;

    print('DEBUG: 今週版クエスト作成ダイアログ - 元の期限: $deadline');

    // 来週の期限を計算するヘルパーメソッド
    DateTime newDeadline = _calculateNextWeekDeadline(deadline);

    print('DEBUG: 今週版クエスト作成ダイアログ - 新しい期限: $newDeadline');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('今週版クエスト作成'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('授業: $subjectName'),
                const SizedBox(height: 8),
                Text('課題種類: $taskType'),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('詳細: $description'),
                ],
                const SizedBox(height: 8),
                Text('期限: ${DateFormat('MM/dd HH:mm').format(newDeadline)}'),
                const SizedBox(height: 16),
                const Text(
                  'この課題の今週版を作成しますか？\n（期限を7日後に設定）',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // キャンセル時は従来の手動入力画面を表示
                  _showTaskDetailsDialog();
                },
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 今週版クエストを作成
                  _createWeeklyQuest(latestQuest, newDeadline);
                },
                child: const Text('作成'),
              ),
            ],
          ),
    );
  }

  // 来週の期限を計算するヘルパーメソッド
  DateTime _calculateNextWeekDeadline(Timestamp? originalDeadline) {
    final now = DateTime.now();
    print('DEBUG: 期限計算開始 - 現在時刻: $now');

    if (originalDeadline != null) {
      final originalDate = originalDeadline.toDate();
      print('DEBUG: 元の期限: $originalDate');

      // 元の期限の時刻（時・分）を保持
      final originalHour = originalDate.hour;
      final originalMinute = originalDate.minute;
      print('DEBUG: 元の期限の時刻 - ${originalHour}:${originalMinute}');

      // 元の期限から7日後を計算
      final nextWeekDate = originalDate.add(const Duration(days: 7));
      final calculatedDeadline = DateTime(
        nextWeekDate.year,
        nextWeekDate.month,
        nextWeekDate.day,
        originalHour,
        originalMinute,
      );

      print('DEBUG: 計算された期限: $calculatedDeadline');
      print(
        'DEBUG: 元の期限からの差: ${calculatedDeadline.difference(originalDate).inDays}日',
      );
      print('DEBUG: 現在時刻からの差: ${calculatedDeadline.difference(now).inDays}日');

      return calculatedDeadline;
    } else {
      // 元の期限がない場合は、現在時刻から7日後
      final fallbackDeadline = now.add(const Duration(days: 7));
      print('DEBUG: 元の期限なし - フォールバック期限: $fallbackDeadline');
      return fallbackDeadline;
    }
  }

  // 今週版クエストを作成
  Future<void> _createWeeklyQuest(
    Map<String, dynamic> baseQuest,
    DateTime newDeadline,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final courseId = baseQuest['courseId'] as String?;
      if (courseId == null) return;

      // 週のクエスト作成回数をチェック
      final weeklyCount = await _getWeeklyQuestCount(courseId);
      if (weeklyCount >= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('この授業の今週のクエスト作成上限（2回）に達しています'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // その授業を取っているユーザーIDを取得
      final enrolledUsersSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('timetable.entries', arrayContains: {'courseId': courseId})
              .get();

      final enrolledUserIds =
          enrolledUsersSnapshot.docs.map((doc) => doc.id).toList();

      // 今週版クエストを作成
      await FirebaseFirestore.instance.collection('quests').add({
        'name': baseQuest['name'],
        'courseId': courseId,
        'taskType': baseQuest['taskType'],
        'deadline': Timestamp.fromDate(newDeadline),
        'description': baseQuest['description'],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'completedUserIds': [],
        'enrolledUserIds': enrolledUserIds,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('今週版クエスト「${baseQuest['name']}」を作成しました！'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // クエスト作成完了後、画面を閉じる
      widget.onCancel();
    } catch (e) {
      print('Error creating weekly quest: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('クエストの作成に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 今週のクエスト作成回数を取得
  Future<int> _getWeeklyQuestCount(String courseId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now
          .subtract(Duration(days: now.weekday - 1))
          .copyWith(
            hour: 0,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          );
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final snapshot =
          await FirebaseFirestore.instance
              .collection('quests')
              .where('courseId', isEqualTo: courseId)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
              )
              .where('createdAt', isLessThan: Timestamp.fromDate(endOfWeek))
              .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting weekly quest count: $e');
      return 0;
    }
  }
}
