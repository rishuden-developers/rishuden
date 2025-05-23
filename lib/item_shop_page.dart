import 'package:flutter/material.dart';

class ItemShopPage extends StatelessWidget {
  const ItemShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shop Page')),
      body: Center(child: Text('ここが遷移先のページです！')),
    );
  }
}
