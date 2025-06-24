import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class TimeScheduleAddPage extends StatefulWidget {
  final DateTime selectedDate;

  const TimeScheduleAddPage({super.key, required this.selectedDate});

  @override
  State<TimeScheduleAddPage> createState() => _TimeScheduleAddPageState();
}

class _TimeScheduleAddPageState extends State<TimeScheduleAddPage> {
  DateTime? _startTime;
  DateTime? _endTime;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // デフォルトの開始時間を設定（選択された日の9:00）
    _startTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      9,
      0,
    );
    // デフォルトの終了時間を設定（開始時間から1時間後）
    _endTime = _startTime!.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    DateTime selectedDateTime = _startTime ?? DateTime.now();

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
                          _startTime = selectedDateTime;
                          // 終了時間が開始時間より前の場合は調整
                          if (_endTime != null &&
                              _endTime!.isBefore(selectedDateTime)) {
                            _endTime = selectedDateTime.add(
                              const Duration(hours: 1),
                            );
                          }
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

  Future<void> _selectEndTime() async {
    if (_startTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先に開始時間を選択してください')));
      return;
    }

    DateTime selectedDateTime =
        _endTime ?? _startTime!.add(const Duration(hours: 1));

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
                          _endTime = selectedDateTime;
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

  void _saveEvent() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('タイトルを入力してください')));
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('開始時間と終了時間を選択してください')));
      return;
    }

    // TODO: イベントを保存する処理を実装
    print('イベントを保存: ${_titleController.text}');
    print('開始時間: $_startTime');
    print('終了時間: $_endTime');
    print('説明: ${_descriptionController.text}');

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予定を追加'),
        actions: [TextButton(onPressed: _saveEvent, child: const Text('保存'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '日付: ${DateFormat('yyyy年MM月dd日').format(widget.selectedDate)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('開始時間'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectStartTime,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 8),
                              Text(
                                _startTime != null
                                    ? DateFormat(
                                      'MM/dd HH:mm',
                                    ).format(_startTime!)
                                    : '開始時間を選択',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('終了時間'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectEndTime,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 8),
                              Text(
                                _endTime != null
                                    ? DateFormat(
                                      'MM/dd HH:mm',
                                    ).format(_endTime!)
                                    : '終了時間を選択',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
