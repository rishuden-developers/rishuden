import 'package:flutter/material.dart';
import 'character_decide_page.dart';

class CharacterQuestionPage extends StatefulWidget {
  @override
  _CharacterQuestionPageState createState() => _CharacterQuestionPageState();
}

class _CharacterQuestionPageState extends State<CharacterQuestionPage> {
  // 質問リスト
  final List<String> questions = [
    '週に何コマ授業を履修していますか？（0〜25）',
    'その中で、1限に入っているコマ数は何回ですか？（0〜5）',
    '週に何回バイトをしていますか？（0〜6）',
    'バイトは何箇所掛け持ちしていますか？（1〜3以上）',
    '週に何回サークルや部活に参加していますか？（0〜5以上）',
    '週に空きコマは何コマありますか？（0〜10）',
    '集中力には自信がありますか？（1＝すぐ気が散る、10＝超集中型）',
    'ストレス耐性はどれくらいありますか？（1＝すぐ病む、10＝鋼メンタル）',
    '計画的に行動できるタイプですか？（1＝ノープラン、10＝完璧主義）',
    '学業・活動へのモチベーションは？（1＝やる気なし、10＝燃えている）',
    '自分の生活がどれくらい忙しいと感じますか？（1＝余裕、10＝超多忙）',
  ];

  // 各質問の最大値
  final List<int> maxValues = [25, 5, 6, 3, 5, 10, 10, 10, 10, 10, 10];

  // 各質問の現在の値
  List<int> answers = [];

  @override
  void initState() {
    super.initState();
    answers = List.generate(questions.length, (index) {
      // 質問6以降はスライダーの最小値が1
      return (index >= 6) ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('キャラ診断')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < questions.length; i++) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Q${i + 1}. ${questions[i]}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Slider(
                value: answers[i].toDouble(),
                min: (i >= 6) ? 1 : 0,
                max: maxValues[i].toDouble(),
                divisions: maxValues[i] - ((i >= 6) ? 1 : 0),
                label: answers[i].toString(),
                onChanged: (value) {
                  setState(() {
                    answers[i] = value.toInt();
                  });
                },
              ),
              SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              icon: Icon(Icons.check),
              label: Text('診断結果を見る'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterDecidePage(answers: answers),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
