import 'package:flutter/material.dart';
import 'item_change_page.dart';
import 'item_shop_page.dart';

class ItemPage extends StatelessWidget {
  const ItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child: Column(
          children: [
            Text('ここが遷移先のページです！'),
            ElevatedButton(
              child: Text('着せ替え'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemChangePage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('アイテム交換所'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemShopPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
