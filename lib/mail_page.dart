import 'package:flutter/material.dart';

class MailPage extends StatelessWidget {
  const MailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mail Page')),
      body: Center(child: Text('ここが遷移先のページです！')),
    );
  }
}
