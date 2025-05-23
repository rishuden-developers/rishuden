import 'package:flutter/material.dart';

class RankingVotePage extends StatelessWidget {
  const RankingVotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('News Page')),
      body: Center(child: Text('ここが遷移先のページです！')),
    );
  }
}
