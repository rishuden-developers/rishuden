import 'package:flutter/material.dart';
import 'character_decide_page.dart';

class CharacterQuestionPage extends StatefulWidget {
  @override
  _CharacterQuestionPageState createState() => _CharacterQuestionPageState();
}

// 各質問の選択肢を定義 (ドロップダウン用)
// キーは質問インデックス、値は選択肢のリスト
final Map<int, List<String>> questionOptions = {
  9: [
    // 未知の体験への態度
    '(A) 強い不安を感じ、できるだけ避けたい',
    '(B) 少し不安はあるが、面白そうなら挑戦してみたい',
    '(C) ワクワクする！むしろ積極的に挑戦したい',
    '(D) まずは誰かが成功するのを見てから判断したい',
  ],
  10: [
    // 計画と実行のスタイル
    '(A) 完璧な計画を立てるまで行動に移せない',
    '(B) 大まかな計画を立て、あとは状況に合わせて進める',
    '(C) 思い立ったら即行動！計画は後から考えるか、なくてもOK',
    '(D) 誰かに計画を立ててもらうか、指示に従うことが多い',
  ],
  11: [
    // 興味関心の深さ/広さ
    '(A) 一つのことを深く掘り下げていくのが好き',
    '(B) 広く浅く、色々なことに触れてみたい',
    '(C) 実用的なことや結果に繋がりやすいものに興味が湧く',
    '(D) あまり物事に強い興味を持つことは少ない',
  ],
  12: [
    // 困難への対処法
    '(A) とにかく気合と根性で正面から突破しようと試みる',
    '(B) 状況を分析し、計画を立て直したり、別の方法を探したりする',
    '(C) 友人や信頼できる人に相談してアドバイスを求める、または協力を仰ぐ',
    '(D) 時間を置く、諦める、または他のことに意識を向ける',
  ],
  13: [
    // あなたが最も活動的になる時間帯は？
    '(A) 早朝～午前中',
    '(B) 日中（午前～夕方）',
    '(C) 夕方～夜にかけて',
    '(D) 深夜～明け方',
    '(E) 特に決まっていない／日によって大きく変動する',
  ],
  14: [
    // 授業の代筆を友人に頼んだことは、おおよそ何回くらいありますか？
    '(A) 0回（頼んだことはない）',
    '(B) 1〜2回程度',
    '(C) 3〜5回程度',
    '(D) 6回以上',
    '(E) 頼む相手がいない／頼むという発想がなかった',
  ],
};

class _CharacterQuestionPageState extends State<CharacterQuestionPage> {
  // 質問リスト (全15問)
  final List<String> questions = [
    // --- 既存の質問 (スライダー形式) ---
    '週に何コマ授業を履修していますか？（0〜25）', // index 0
    'その中で、1限に入っているコマ数は何回ですか？（0〜5）', // index 1
    '週に何回バイトをしていますか？（0〜6）', // index 2
    '週に何回サークルや部活に参加していますか？（0〜5）', // index 3 (以前は5以上だったので0-5に明確化)
    '週に空きコマは何コマありますか？（0〜10）', // index 4
    '集中力には自信がありますか？（1＝すぐ気が散る、10＝超集中型）', // index 5
    'ストレス耐性はどれくらいありますか？（1＝すぐ病む、10＝鋼メンタル）', // index 6
    '学業・活動へのモチベーションは？（1＝やる気なし、10＝燃えている）', // index 7
    '自分の生活がどれくらい忙しいと感じますか？（1＝余裕、10＝超多忙）', // index 8
    // --- 新しい質問 (ドロップダウン形式) ---
    '未知の体験への態度を選んでください。', // index 9
    '何か新しいことを始めようとするとき、あなたのスタイルは？', // index 10
    '新しいことや興味のあることに対して、あなたはどちらに近いですか？', // index 11
    '解決が難しい問題や大きな壁に直面した時、あなたはまずどうしますか？', // index 12
    'あなたが最も活動的になったり、集中できたりする時間帯はいつ頃ですか？', // index 13
    '（この一週間で）授業の代筆を友人に頼んだことは、おおよそ何回くらいありますか？', // index 14
  ];

  // 各質問の最大値 (スライダー用) または選択肢の数 (ドロップダウン用)
  // ドロップダウンの場合、answersには選択肢のインデックス(0始まり)を格納するため、
  // このmaxValuesはスライダーのmax値としてのみ利用。ドロップダウンの選択肢数はquestionOptionsから取得。
  final List<int> maxValues = [
    25, // Q1
    5, // Q2
    6, // Q3
    5, // Q4 (0-5回と仮定)
    10, // Q5
    10, // Q6
    10, // Q7
    10, // Q8
    10, // Q9
    // 以下のドロップダウン質問のmaxValuesは直接UIには使わないが、
    // answersの初期化やバリデーションの参考にできる。
    // 選択肢の数は questionOptions[index].length で取得する。
    (questionOptions[9]?.length ?? 1) - 1, // Q10 未知の体験 (インデックスなのでlength-1)
    (questionOptions[10]?.length ?? 1) - 1, // Q11 計画と実行
    (questionOptions[11]?.length ?? 1) - 1, // Q12 興味関心
    (questionOptions[12]?.length ?? 1) - 1, // Q13 困難への対処
    (questionOptions[13]?.length ?? 1) - 1, // Q14 活動時間帯
    (questionOptions[14]?.length ?? 1) - 1, // Q15 代筆
  ];

  // 各質問の現在の値 (スライダーの値 or ドロップダウンで選択された選択肢のインデックス)
  late List<int> answers;

  @override
  void initState() {
    super.initState();
    answers = List.generate(questions.length, (index) {
      // 質問6から9 (インデックス5から8) はスライダーの最小値が1
      if (index >= 5 && index <= 8) {
        return 1;
      }
      // ドロップダウンの質問(インデックス9以降)は最初の選択肢(インデックス0)を初期値とする
      // スライダーで0始まりの質問も初期値0
      return 0;
    });
  }

  Widget _buildQuestionWidget(int index) {
    // インデックス9以降はドロップダウン形式
    if (index >= 9) {
      final options = questionOptions[index] ?? [];
      // answers[index] が options の範囲外にならないようにチェック
      int currentValue = answers[index];
      if (currentValue >= options.length) {
        currentValue = 0; //範囲外ならデフォルトで最初の選択肢
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${index + 1}. ${questions[index]}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<int>(
            style: TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: currentValue,
            isExpanded: true,
            dropdownColor: Colors.brown[700],
            items:
                options.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key, // 選択肢のインデックスを値とする
                    child: Text(
                      entry.value,
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                answers[index] = value ?? 0;
              });
            },
            // validator: (value) => value == null ? '選択してください' : null, // 必要に応じて
          ),
        ],
      );
    } else {
      // それ以外はスライダー形式
      bool isOneBased = (index >= 5 && index <= 8); // 1から始まるスライダーか
      double minVal = isOneBased ? 1.0 : 0.0;
      int divisionsVal = maxValues[index] - (isOneBased ? 1 : 0);
      if (divisionsVal <= 0) divisionsVal = 1; // divisionsは1以上である必要がある

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${index + 1}. ${questions[index]}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Slider(
            value: answers[index].toDouble(),
            min: minVal,
            max: maxValues[index].toDouble(),
            divisions: divisionsVal,
            label: answers[index].toString(),
            onChanged: (value) {
              setState(() {
                answers[index] = value.toInt();
              });
            },
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('キャラ診断'),
        backgroundColor: Colors.brown,
        titleTextStyle: TextStyle(
          // <--- この行を追加/修正
          color: Colors.white,
          fontSize: 20, // 必要に応じてフォントサイズなども調整
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.brown[50], // 背景色
      body: Stack(
        // Stackウィジェットで囲む
        children: <Widget>[
          // 背景画像
          Positioned.fill(
            // 画像を画面全体に広げる
            child: Image.asset(
              'assets/question_background_image.png', // ★あなたの背景画像パスに置き換えてください
              fit: BoxFit.cover, // 画像を画面に合わせて調整
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < questions.length; i++) ...[
                  _buildQuestionWidget(i),
                  SizedBox(height: 24), // 各質問間のスペースを少し広めに
                ],
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.psychology, color: Colors.white), // アイコン変更
                  label: Text(
                    '診断結果を見る',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700], // ボタンの色変更
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0), // ボタンの角を丸く
                    ),
                  ),
                  onPressed: () {
                    // 全ての質問に回答したかチェック (ドロップダウンは初期値があるので実質常に回答済み)
                    // 必要であればここでバリデーションを追加
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CharacterDecidePage(answers: answers),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20), // ボタン下のスペース
              ],
            ),
          ),
        ],
      ),
    );
  }
}
