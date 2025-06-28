import 'package:flutter/material.dart';
import 'mail_page.dart';
import 'player_log_page.dart';
import 'setting_page/setting_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu Page')),
      body: Center(
        child: Column(
          children: [
            Text('ここが遷移先のページです！'),
            ElevatedButton(
              child: Text('お問い合わせ'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MailPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('プレイヤー記録'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlayerLogPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('設定'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
