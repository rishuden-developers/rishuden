import 'package:flutter/material.dart';
import 'park_page.dart';

class CharacterDecidePage extends StatelessWidget {
  final String character = "履修剣士";
  final String personality = "努力タイプ、朝が強い、1限多め";
  final List<String> skills = ["必修スラッシュ", "オンデマンドブースト"];
  final List<String> items = ["GPAの刃", "タイムマネジメントの書"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(title: Text('診断結果'), backgroundColor: Colors.brown),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "🎓 あなたの履修タイプは…！",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // キャラクター画像（assets/swordsman.png を用意し、pubspec.yaml に登録する）
            CircleAvatar(
              radius: 150,
              backgroundImage: AssetImage('assets/swordsman.jpg'),
            ),
            SizedBox(height: 20),

            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "👤 $character",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text("性格: $personality"),
                    SizedBox(height: 10),
                    Text("スキル: ${skills.join(", ")}"),
                    SizedBox(height: 10),
                    Text("アイテム: ${items.join(", ")}"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                // 再診断（仮：popして戻る）
                Navigator.pop(context);
              },
              icon: Icon(Icons.refresh),
              label: Text("再診断する"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => Scaffold(
                          appBar: AppBar(title: Text("冒険画面")),
                          body: Center(child: Text("ここに冒険スタート画面を作ってね！")),
                        ),
                  ),
                );
              },
              icon: Icon(Icons.directions_walk),
              label: Text("仮の冒険画面へ"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            SizedBox(height: 10),

            // 本物の冒険画面へ
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ParkPage()),
                );
              },
              icon: Icon(Icons.map),
              label: Text("冒険を始める"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
