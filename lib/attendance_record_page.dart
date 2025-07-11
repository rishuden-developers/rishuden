import 'package:flutter/material.dart';

class AttendanceRecordPage extends StatelessWidget {
  final String subjectName;
  final String period;
  final String date;

  const AttendanceRecordPage({
    Key? key,
    required this.subjectName,
    required this.period,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('出席記録'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('授業名: $subjectName'),
            Text('時限: $period'),
            Text('日付: $date'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 出席を記録するロジック
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('出席を記録しました！')),
                );
                Navigator.pop(context);
              },
              child: const Text('出席'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // 欠席を記録するロジック
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('欠席を記録しました。')),
                );
                Navigator.pop(context);
              },
              child: const Text('欠席'),
            ),
          ],
        ),
      ),
    );
  }
}
