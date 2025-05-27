import 'package:flutter/material.dart';
import 'park_page.dart';

class CharacterDecidePage extends StatelessWidget {
  final List<int> answers;

  CharacterDecidePage({Key? key, required this.answers}) : super(key: key);

  late final String character;
  late final String personality;
  late final List<String> skills;
  late final List<String> items;

  void decideCharacter() {
    // 仮のロジック：今は常に「履修剣士」
    character = "履修剣士";
    personality = "努力タイプ、朝が強い、1限多め";
    skills = ["必修スラッシュ", "オンデマンドブースト"];
    items = ["GPAの刃", "タイムマネジメントの書"];

    // 将来は answers を使って判定するように追加できます
    // 例：
    // if (answers[0] >= 20 && answers[6] >= 8) {
    //   character = "神（全能型）";
    //   personality = "...";
    //   skills = [...];
    //   items = [...];
    // }
  }

  CharacterDecidePage({super.key});

  @override
  Widget build(BuildContext context) {
    decideCharacter(); // キャラクター情報を決定

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

            // キャラクター画像（assets/swordsman.jpg を使う前提）
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
                    builder: (context) => Scaffold(
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
