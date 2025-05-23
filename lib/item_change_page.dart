import 'package:flutter/material.dart';

class ItemChangePage extends StatelessWidget {
  const ItemChangePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Formchange Page')),
      body: Center(child: Text('ここが遷移先のページです！')),
    );
  }
}
