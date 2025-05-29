import 'package:flutter/material.dart';
import 'park_page.dart';

class CharacterDecidePage extends StatelessWidget {
  final List<int> answers;

  CharacterDecidePage({required this.answers});

  // 仮の診断ロジック（answersに応じて条件分岐で変更可）
  String getCharacter() {
    if (answers[1] >= 3 && answers[0] >= 15) {
      return "履修剣士";
    } else if (answers[2] >= 4) {
      return "バイト戦士";
    } else {
      return "気ままな旅人";
    }
  }

  String getPersonality(String character) {
    switch (character) {
      case "履修剣士":
        return "努力タイプ、朝が強い、1限多め";
      case "バイト戦士":
        return "実践派、時間管理が鍵、金欠とは無縁";
      case "気ままな旅人":
        return "自由人、マイペースに生きるタイプ";
      default:
        return "";
    }
  }

  List<String> getSkills(String character) {
    switch (character) {
      case "履修剣士":
        return ["必修スラッシュ", "オンデマンドブースト"];
      case "バイト戦士":
        return ["深夜テンション", "時間分身術"];
      case "気ままな旅人":
        return ["遅刻無効", "リラックスオーラ"];
      default:
        return [];
    }
  }

  List<String> getItems(String character) {
    switch (character) {
      case "履修剣士":
        return ["GPAの刃", "タイムマネジメントの書"];
      case "バイト戦士":
        return ["バイトシフト表", "エナジードリンク"];
      case "気ままな旅人":
        return ["気分転換の杖", "自由な時間"];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final String character = getCharacter();
    final String personality = getPersonality(character);
    final List<String> skills = getSkills(character);
    final List<String> items = getItems(character);

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

            CircleAvatar(
              radius: 150,
              backgroundImage: AssetImage('assets/swordsman.jpg'), // 仮画像（キャラごとに切り替えたい場合は条件追加）
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

