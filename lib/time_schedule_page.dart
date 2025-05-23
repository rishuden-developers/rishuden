import 'package:flutter/material.dart';
import 'time_schedule_add_page.dart';

class TimeSchedulePage extends StatelessWidget {
  const TimeSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Time Schedule Page')),
      body: Center(
        child: Column(
          children: [
            Text('ここが遷移先のページです！'),
            ElevatedButton(
              child: Text('ホーム画面に設定'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimeScheduleAddPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
