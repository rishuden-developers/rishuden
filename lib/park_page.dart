import 'package:flutter/material.dart';
import 'menu_page.dart';
import 'credit_review_page.dart';
import 'item_page.dart';
import 'ranking_page.dart';
import 'time_schdule_page.dart';

class ParkPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Park Page')),
      body: Center(
        child: Column(
          children: [
            Text('ここが遷移先のページです！'),
            ElevatedButton(
              child: Text('メニュー'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MenuPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('単位レビュー'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreditReviewPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('アイテム'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('ランキング'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RankingPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('時間割'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TimeSchdulePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
