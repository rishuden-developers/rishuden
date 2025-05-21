import 'package:flutter/material.dart';
import 'ranking_trending_page.dart';
import 'ranking_explore_page.dart';
import 'ranking_vote_page.dart';

class RankingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child: Column(
          children: [
            Text('ここが遷移先のページです！'),
            ElevatedButton(
              child: Text('急上昇ランキング'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RankingTrendingPage(),
                  ),
                );
              },
            ),
            ElevatedButton(
              child: Text('検索'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RankingExplorePage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('投票'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RankingVotePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
