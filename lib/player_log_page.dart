import 'package:flutter/material.dart';

class PlayerLogPage extends StatelessWidget {
  const PlayerLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log Page')),
      body: Center(child: Text('ここが遷移先のページです！')),
    );
  }
}
