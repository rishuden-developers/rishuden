import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timetable_entry.dart';
import 'timetable.dart';
import 'utils/course_pattern_detector.dart';
import 'utils/course_color_generator.dart';
import 'course_pattern.dart';
import 'providers/timetable_provider.dart';
import 'providers/global_course_mapping_provider.dart';
import 'package:intl/intl.dart';

class QuestCreationWidget extends ConsumerStatefulWidget {
  final void Function() onCancel;
  final void Function(
    String selectedClass,
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

  final List<String> taskTypes = ['レポート', '出席', '発表', '試験', 'その他'];

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

      // 授業判別と色分け
      List<CoursePattern> patterns = CoursePatternDetector.detectPatterns(
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
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDeadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
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
                final date = await showDatePicker(
                  context: context,
                  initialDate: tempDeadline ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date == null) return;

                final time = await showTimePicker(
                  context: context,
                  initialTime:
                      tempDeadline != null
                          ? TimeOfDay.fromDateTime(tempDeadline!)
                          : TimeOfDay.now(),
                );
                if (time == null) return;

                setDialogState(() {
                  tempDeadline = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
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
                            ? () {
                              ref
                                  .read(timetableProvider.notifier)
                                  .updateQuestTaskType(tempTaskType);
                              ref
                                  .read(timetableProvider.notifier)
                                  .updateQuestDeadline(tempDeadline);
                              ref
                                  .read(timetableProvider.notifier)
                                  .updateQuestDescription(tempDescription);
                              widget.onCreate(
                                selectedClass!['subjectName'],
                                tempTaskType!,
                                tempDeadline!,
                                tempDescription,
                              );
                              // クエスト作成完了後、データをリセット
                              ref
                                  .read(timetableProvider.notifier)
                                  .resetQuestData();
                              _hasShownDialog = false; // フラグをリセット
                              Navigator.of(context).pop();
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
                                onTap: () {
                                  ref
                                      .read(timetableProvider.notifier)
                                      .updateQuestSelectedClass({
                                        'id': entry!.id,
                                        'subjectName': entry.subjectName,
                                        'classroom': entry.classroom,
                                        'dayOfWeek': entry.dayOfWeek,
                                        'period': entry.period,
                                        'date': entry.date,
                                        'courseId': entry.courseId,
                                      });

                                  if (selectedTaskType != null &&
                                      selectedDeadline != null) {
                                    print(
                                      'Quest Create - Showing dialog with existing data for ${entry.subjectName}',
                                    );
                                  } else {
                                    print(
                                      'Quest Create - Showing dialog for new quest for ${entry.subjectName}',
                                    );
                                  }
                                  _showTaskDetailsDialog();
                                },
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? courseColor.withOpacity(0.3)
                                            : courseColor.withOpacity(0.1),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? courseColor
                                              : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
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
                                            color: courseColor,
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
}
