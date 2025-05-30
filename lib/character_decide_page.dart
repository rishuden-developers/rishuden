import 'package:flutter/material.dart';
import 'park_page.dart'; // 広場画面へ遷移するために必要

class CharacterDecidePage extends StatelessWidget {
  final List<int> answers;
  const CharacterDecidePage({super.key, required this.answers});

  // 各質問の最大値 (CharacterQuestionPageと同期)
  final List<int> _questionMaxValues = const [
    25,
    5,
    6,
    3,
    5,
    10,
    10,
    10,
    10,
    10,
    10,
  ];

  // 回答を0-5点のスケールに正規化する関数
  double _normalizeAnswer(int questionIndex, int rawAnswer) {
    double normalizedScore;
    switch (questionIndex) {
      case 0: // 週に何コマ授業を履修していますか？（0〜25）
        if (rawAnswer >= 20)
          normalizedScore = 5.0;
        else if (rawAnswer >= 15)
          normalizedScore = 4.0;
        else if (rawAnswer >= 10)
          normalizedScore = 3.0;
        else if (rawAnswer >= 5)
          normalizedScore = 2.0;
        else
          normalizedScore = 1.0;
        break;
      case 1: // 1限に入っているコマ数（0〜5）
        if (rawAnswer >= 4)
          normalizedScore = 5.0;
        else if (rawAnswer == 3)
          normalizedScore = 4.0;
        else if (rawAnswer == 2)
          normalizedScore = 3.0;
        else if (rawAnswer == 1)
          normalizedScore = 2.0;
        else
          normalizedScore = 1.0;
        break;
      case 2: // 週に何回バイトをしていますか？（0〜6）
        if (rawAnswer == 0)
          normalizedScore = 3.0;
        else if (rawAnswer <= 2)
          normalizedScore = 4.0;
        else if (rawAnswer <= 4)
          normalizedScore = 5.0;
        else
          normalizedScore = 4.0;
        break;
      case 3: // バイトは何箇所掛け持ちしていますか？（1〜3以上）
        if (rawAnswer >= 3)
          normalizedScore = 5.0;
        else if (rawAnswer == 2)
          normalizedScore = 4.0;
        else
          normalizedScore = 3.0;
        break;
      case 4: // 週に何回サークルや部活に参加していますか？（0〜5以上）
        if (rawAnswer >= 3)
          normalizedScore = 5.0;
        else if (rawAnswer >= 1)
          normalizedScore = 3.0;
        else
          normalizedScore = 1.0;
        break;
      case 5: // 週に空きコマは何コマありますか？（0〜10）
        if (rawAnswer <= 2)
          normalizedScore = 5.0; // 空きコマ少ない＝履修詰まってる
        else if (rawAnswer <= 5)
          normalizedScore = 3.0;
        else
          normalizedScore = 1.0;
        break;
      default: // 集中力、ストレス耐性、計画性、モチベーション、忙しさ (1-10スケール)
        normalizedScore = (rawAnswer / 10.0) * 5.0; // 1-10を0-5に変換 (10が5、1が0.5)
        break;
    }
    return normalizedScore;
  }

  // 逆転スコア（低いほどキャラに寄る場合）
  double _normalizeInverse(int questionIndex, int rawAnswer) {
    double normalizedScore = _normalizeAnswer(questionIndex, rawAnswer);
    return 5.0 - normalizedScore + 1.0; // 5点なら1点、1点なら5点になるように調整
  }

  String _diagnoseCharacter(List<int> rawAnswers) {
    // 1. 回答を正規化 (0-5点スケール)
    List<double> normalizedAnswers = List.generate(
      rawAnswers.length,
      (i) => _normalizeAnswer(i, rawAnswers[i]),
    );

    // 2. 各キャラタイプの適性スコアを計算 (合計点ベース)
    double knightScore =
        (normalizedAnswers[0] * 1.5 + // 履修コマ数 (高履修)
            normalizedAnswers[1] * 1.5 + // 1限コマ数 (朝型、規則正しい)
            normalizedAnswers[4] * 1.0 + // サークル参加 (活動的)
            normalizedAnswers[6] * 1.2 + // 集中力
            normalizedAnswers[7] * 1.0 + // ストレス耐性
            normalizedAnswers[8] * 1.5 + // 計画性 (重要)
            normalizedAnswers[9] * 1.2 + // モチベーション
            _normalizeInverse(5, rawAnswers[5]) *
                1.0 // 空きコマ少ない (履修詰まってる)
                );

    double witchScore =
        (normalizedAnswers[0] * 0.8 + // 履修コマ数 (偏りあり)
            normalizedAnswers[6] * 2.5 + // 集中力 (魔女の最重要項目)
            _normalizeInverse(4, rawAnswers[4]) * 1.0 + // サークル参加少なめがプラス
            _normalizeInverse(2, rawAnswers[2]) * 0.8 + // バイト少なめがプラス
            normalizedAnswers[8] * 0.8 + // 計画性
            normalizedAnswers[9] * 1.2 + // モチベーション (探求心)
            _normalizeInverse(10, rawAnswers[10]) *
                0.5 // 忙しさ (余裕があると探求)
                );

    double merchantScore =
        (normalizedAnswers[2] * 2.0 + // バイト回数 (商人最重要)
            normalizedAnswers[3] * 2.0 + // バイト掛け持ち (商人最重要)
            normalizedAnswers[5] * 1.5 + // 空きコマ数 (効率重視)
            normalizedAnswers[8] * 1.2 + // 計画性
            normalizedAnswers[10] *
                1.5 // 忙しさ (多忙だがうまく回す)
                );

    // 新たに「ゴリラ」スコアを追加
    double gorillaScore =
        (normalizedAnswers[1] * 2.0 + // 1限コマ数 (朝型、ゴリラ最重要)
            normalizedAnswers[6] * 1.5 + // 集中力 (脳筋で集中)
            normalizedAnswers[7] * 1.8 + // ストレス耐性 (鋼メンタル)
            normalizedAnswers[9] * 1.5 + // モチベーション (頑張る)
            normalizedAnswers[0] * 1.0 + // 履修コマ数 (頑張って詰める)
            normalizedAnswers[4] * 1.2 + // サークル参加 (体育会系活動)
            normalizedAnswers[10] *
                1.0 // 忙しさ (忙しいけど頑張る)
                );

    double loserScore =
        (_normalizeInverse(0, rawAnswers[0]) * 1.5 + // 履修コマ数 (少ないほどプラス)
            _normalizeInverse(1, rawAnswers[1]) * 1.5 + // 1限コマ数 (少ないほどプラス)
            normalizedAnswers[2] * 0.5 + // バイト回数 (多すぎると疲弊)
            _normalizeInverse(4, rawAnswers[4]) * 1.0 + // サークル参加 (少ないほどプラス)
            normalizedAnswers[5] * 2.0 + // 空きコマ数 (多すぎるのが特徴)
            _normalizeInverse(6, rawAnswers[6]) * 1.5 + // 集中力 (低いほどプラス)
            _normalizeInverse(7, rawAnswers[7]) * 1.5 + // ストレス耐性 (低いほどプラス)
            _normalizeInverse(8, rawAnswers[8]) * 2.0 + // 計画性 (低いほどプラス、最重要)
            _normalizeInverse(9, rawAnswers[9]) * 1.5 + // モチベーション (低いほどプラス)
            normalizedAnswers[10] *
                1.0 // 忙しさ (多忙なのに何もできてない)
                );

    // 3. レアキャラの判定（優先度高）
    // 神の判定: 主要なポジティブ項目が非常に高い
    double godCriteria =
        (normalizedAnswers[0] +
            normalizedAnswers[1] +
            normalizedAnswers[6] +
            normalizedAnswers[8] +
            normalizedAnswers[9]);
    if (godCriteria >= 20.0) {
      // 5項目合計最大25点中20点以上（平均4点以上）
      return "神";
    }

    // カス大学生の判定: 主要なネガティブ項目が非常に高い（逆転スコアで）
    double loserCriteria =
        (_normalizeInverse(0, rawAnswers[0]) +
            _normalizeInverse(1, rawAnswers[1]) +
            _normalizeInverse(6, rawAnswers[6]) +
            _normalizeInverse(8, rawAnswers[8]) +
            _normalizeInverse(9, rawAnswers[9]) +
            normalizedAnswers[5] // 空きコマ数はそのまま高いとカス
            );
    if (loserCriteria >= 25.0) {
      // 6項目合計最大30点中25点以上（平均4.16点以上）
      return "カス大学生";
    }

    // 4. 通常キャラの判定 (最もスコアが高いキャラ)
    Map<String, double> scores = {
      "剣士": knightScore,
      "魔女": witchScore,
      "商人": merchantScore,
      "ゴリラ": gorillaScore, // ★ゴリラを追加★
    };

    String finalCharacter = "剣士"; // デフォルトのキャラ
    double maxScore = -1.0; // 最小値で初期化

    // スコアが同点の場合の優先順位（任意）
    // 例えば、剣士 > 魔女 > 商人 > ゴリラ
    if (knightScore > maxScore) {
      maxScore = knightScore;
      finalCharacter = "剣士";
    }
    if (witchScore > maxScore) {
      maxScore = witchScore;
      finalCharacter = "魔女";
    }
    if (merchantScore > maxScore) {
      maxScore = merchantScore;
      finalCharacter = "商人";
    }
    if (gorillaScore > maxScore) {
      // ★ゴリラの判定を追加★
      maxScore = gorillaScore;
      finalCharacter = "ゴリラ";
    }

    return finalCharacter;
  }

  @override
  Widget build(BuildContext context) {
    // ここで診断を実行
    String characterName = _diagnoseCharacter(answers);

    // キャラクターの特性データを取得
    Map<String, dynamic> characterData = {
      "剣士": {
        "image": 'assets/character_swordman.png',
        "personality": "文武両道、行動力がある、学業も遊びも手を抜かない。",
        "skills": ["必修スラッシュ", "単位獲得ブースト"],
        "items": ["GPAの剣", "時間管理の盾"],
      },
      "魔女": {
        "image": 'assets/character_wizard.png',
        "personality": "好奇心旺盛、特定の分野を深く探求、たまに変わり者。",
        "skills": ["専門知識探求", "集中力アップ"],
        "items": ["論文の杖", "コーヒーポット"],
      },
      "商人": {
        "image": 'assets/character_merchant.png',
        "personality": "コスパ重視、情報収集力、人脈形成、バイトマスター。",
        "skills": ["楽単サーチ", "交渉術"],
        "items": ["楽単リスト", "電卓"],
      },
      "神": {
        "image": 'assets/character_god.png',
        "personality": "すべてを兼ね備える完璧超人。何でもそつなくこなす。",
        "skills": ["全能の知識", "無双履修"],
        "items": ["神のノート", "光のペン"],
      },
      "ゴリラ": {
        // ★ゴリラを追加★
        "image": 'assets/character_gorilla.png', // ゴリラの画像パス
        "personality": "朝型脳筋、努力と根性で乗り切る。時々、野生が顔を出す。",
        "skills": ["1限フル出場", "気合いの徹夜", "筋トレ"],
        "items": ["プロテイン", "バナナ", "分厚い参考書"],
      },
      "カス大学生": {
        "image": 'assets/character_takuji.png', // カス大学生の画像パス（ゴリラから変更）
        "personality": "ギリギリで生きている、綱渡り状態、常に睡眠不足。",
        "skills": ["奇跡の出席", "期末一夜漬け"],
        "items": ["過去問の切れ端", "栄養ドリンク"],
      },
    };

    // 診断されたキャラクターのデータを取得
    final displayCharacterData =
        characterData[characterName] ?? characterData["カス大学生"]; // デフォルトフォールバック

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(title: const Text('診断結果'), backgroundColor: Colors.brown),
      body: SingleChildScrollView(
        // スクロール可能にする
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "🎓 あなたの履修タイプは…！",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // キャラクター画像
            CircleAvatar(
              radius: 150,
              backgroundImage: AssetImage(displayCharacterData["image"]),
            ),
            const SizedBox(height: 20),

            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // テキストを左寄せ
                  children: [
                    Text(
                      "👤 ${displayCharacterData["name"] ?? characterName}", // キャラ名を表示。データにnameがあればそれを使う
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text("性格: ${displayCharacterData["personality"]}"),
                    const SizedBox(height: 10),
                    Text("スキル: ${displayCharacterData["skills"].join(", ")}"),
                    const SizedBox(height: 10),
                    Text("アイテム: ${displayCharacterData["items"].join(", ")}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // 質問画面に戻る
              },
              icon: const Icon(Icons.refresh),
              label: const Text("再診断する"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                // 冒険に出るボタン。main.dartのMyHomePageに戻る
                // runApp()がMyAppを再構築するため、Navigator.pushReplacementを使うと
                // MaterialApp自体が再構築される可能性があるため、
                // Navigator.popUntilで最上位に戻るのが安全な場合が多い。
                // あるいは、pushReplacementでParkPageへ遷移
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ParkPage()),
                );
              },
              icon: const Icon(Icons.directions_walk),
              label: const Text("冒険に出る"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
