import 'package:flutter/material.dart';
import 'time_schdule_add_page.dart'; // Adjust the import according to your file structure

class TimeSchdulePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child: Column(
          children: [
            Text('ここが遷移先のページです！'),
            ElevatedButton(
              child: Text('ホーム画面に設定'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TimeSchduleAddPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
