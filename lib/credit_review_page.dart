import 'package:flutter/material.dart';
import 'credit_explore_page.dart';
import 'credit_input_page.dart';
import 'credit_senior_page.dart';

class CreditReviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Credit Page')),
      body: Center(
        child: Column(
          children: [
            Text('ここが遷移先のページです！'),
            ElevatedButton(
              child: Text('検索'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreditExplorePage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('先輩検索'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreditSeniorPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('レビューを書く'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreditInputPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
