import 'package:flutter/material.dart';

class CreditSeniorPage extends StatelessWidget {
  const CreditSeniorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('News Page')),
      body: Center(child: Text('ここが遷移先のページです！')),
    );
  }
}
