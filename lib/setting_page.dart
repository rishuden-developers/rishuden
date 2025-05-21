import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setting Page')),
      body: Center(child: Text('ここが遷移先のページです！')),
    );
  }
}
