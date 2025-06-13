import 'package:flutter/material.dart';

class QuestCreationWidget extends StatefulWidget {
  final List<String> classes;
  final void Function() onCancel;

  // 作成時の引数に「一言コメント」を追加
  final void Function(
    String selectedClass,
    String taskType,
    DateTime deadline,
    String comment,
  )
  onCreate;

  const QuestCreationWidget({
    Key? key,
    required this.classes,
    required this.onCancel,
    required this.onCreate,
  }) : super(key: key);

  @override
  _QuestCreationWidgetState createState() => _QuestCreationWidgetState();
}

class _QuestCreationWidgetState extends State<QuestCreationWidget> {
  String? selectedClass;
  String? selectedTaskType;
  DateTime? selectedDeadline;
  String creatorComment = ''; // ← 追加: 一言コメント

  final List<String> taskTypes = ['レポート', '出席', '発表', '試験', 'その他'];

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
      selectedDeadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "クエスト作成",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // 授業選択
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "授業を選択"),
                items:
                    widget.classes.map((className) {
                      return DropdownMenuItem(
                        value: className,
                        child: Text(className),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClass = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              // タスク種類選択
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "タスクの種類"),
                items:
                    taskTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTaskType = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              // 締切日時選択
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDeadline != null
                          ? "${selectedDeadline!.toLocal()}".split('.')[0]
                          : "締切日時を選択",
                    ),
                  ),
                  TextButton(onPressed: _pickDateTime, child: Text("選択")),
                ],
              ),

              const SizedBox(height: 12),

              // 一言入力
              TextFormField(
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: "作成者からの一言（任意）",
                  hintText: "例：みんなで頑張ろう！",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    creatorComment = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // ボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: widget.onCancel,
                    child: Text("キャンセル"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        (selectedClass != null &&
                                selectedTaskType != null &&
                                selectedDeadline != null)
                            ? () {
                              widget.onCreate(
                                selectedClass!,
                                selectedTaskType!,
                                selectedDeadline!,
                                creatorComment, // ← 一言も渡す
                              );
                            }
                            : null,
                    child: Text("作成"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
