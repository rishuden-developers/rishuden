import 'package:flutter/material.dart';
import 'dart:math'; // For max/min
import 'package:cloud_firestore/cloud_firestore.dart';
import 'character_decide_page.dart';

// 各質問の選択肢を定義 (ドロップダウン用 - インデックス11から16)
final Map<int, List<String>> questionOptions = {
  11: [
    '(A) 強い不安を感じ、できるだけ避けたい',
    '(B) 少し不安はあるが、面白そうなら挑戦してみたい',
    '(C) ワクワクする！むしろ積極的に挑戦したい',
    '(D) まずは誰かが成功するのを見てから判断したい',
  ],
  12: [
    '(A) 完璧な計画を立てるまで行動に移せない',
    '(B) 大まかな計画を立て、あとは状況に合わせて進める',
    '(C) 思い立ったら即行動！計画は後から考えるか、なくてもOK',
    '(D) 誰かに計画を立ててもらうか、指示に従うことが多い',
  ],
  13: [
    '(A) 一つのことを深く掘り下げていくのが好き',
    '(B) 広く浅く、色々なことに触れてみたい',
    '(C) 実用的なことや結果に繋がりやすいものに興味が湧く',
    '(D) あまり物事に強い興味を持つことは少ない',
  ],
  14: [
    '(A) とにかく気合と根性で正面から突破しようと試みる',
    '(B) 状況を分析し、計画を立て直したり、別の方法を探したりする',
    '(C) 友人や信頼できる人に相談してアドバイスを求める、または協力を仰ぐ',
    '(D) 時間を置く、諦める、または他のことに意識を向ける',
  ],
  15: [
    '(A) 早朝～午前中',
    '(B) 日中（午前～夕方）',
    '(C) 夕方～夜にかけて',
    '(D) 深夜～明け方',
    '(E) 特に決まっていない／日によって大きく変動する',
  ],
  16: [
    '(A) 一応授業を聞いている',
    '(B) スマートフォンやPCでゲームをする',
    '(C) 他の授業の課題や作業を進める',
    '(D) 寝る',
  ],
};

class CharacterQuestionPage extends StatefulWidget {
  @override
  _CharacterQuestionPageState createState() => _CharacterQuestionPageState();
}

class _CharacterQuestionPageState extends State<CharacterQuestionPage> {
  // 質問リスト (全17問 - ユーザー指定の最終順序)
  final List<String> questions = [
    'Q1: 週に何コマ授業あるの？（0〜25コマ）',
    'Q2: 1限は何コマ埋まってる？（0〜5回）',
    'Q3: 週に何コマ飛んでる？（0〜25コマ）',
    'Q4: 週に何回くらい代筆頼んでる？（0〜25回）',
    'Q5: 週に何日バイトをしてる？（0〜6回）',
    'Q6: 週に何日サークルや部活に参加してる？（0〜5回）',
    'Q7: 週に空きコマは何コマある？（0〜10コマ）',
    'Q8: 集中力には自信がある？（1:すぐ気が散る 〜 10:超集中型）',
    'Q9: ストレス耐性はどれくらいある？（1:すぐ病む 〜 10:鋼メンタル）',
    'Q10: 学業・活動へのモチベーションは？（1:やる気なし 〜 10:燃えている）',
    'Q11: 自分の生活がどれくらい忙しいと思う？（1:余裕 〜 10:超多忙）',
    'Q12: 未知の体験への態度を選んでね。',
    'Q13: 何か新しいことを始めようとするとき、あなたのスタイルは？',
    'Q14: 新しいことや興味のあることに対して、あなたはどちらに近い？',
    'Q15: 解決が難しい問題や大きな壁に直面した時、あなたはまずどうする？',
    'Q16: あなたが最も活動的になったり、集中できたりする時間帯はいつ？',
    'Q17: ゆるい授業中（楽単など）は何をして過ごすことが多い？',
  ];

  final List<int> maxValues = [
    25,
    5,
    25,
    25,
    6,
    5,
    10,
    10,
    10,
    10,
    10,
    (questionOptions[11]?.length ?? 1) - 1,
    (questionOptions[12]?.length ?? 1) - 1,
    (questionOptions[13]?.length ?? 1) - 1,
    (questionOptions[14]?.length ?? 1) - 1,
    (questionOptions[15]?.length ?? 1) - 1,
    (questionOptions[16]?.length ?? 1) - 1,
  ];

  late List<int> answers;

  @override
  void initState() {
    super.initState();
    answers = List.generate(questions.length, (index) {
      if (index >= 7 && index <= 10) {
        // Q8-Q11 (1-10スケール)
        return 1;
      }
      return 0;
    });
  }

  Future<void> _saveDiagnosisToFirestore(
    List<int> userAnswers,
    String diagnosedCharacter,
  ) async {
    print('--- Firestoreへの保存処理を開始します (QuestionPageから) ---');
    try {
      await FirebaseFirestore.instance.collection('diagnostics').add({
        'answers': userAnswers,
        'character': diagnosedCharacter,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('診断結果をFirestoreに保存しました。');
    } catch (e) {
      print('Firestoreへの保存に失敗しました: $e');
    }
  }

  double _normalizeAnswer(int questionIndex, int rawAnswer) {
    double normalizedScore = 3.0;
    switch (questionIndex) {
      case 0: // Q1 履修コマ数
        if (rawAnswer >= 22)
          normalizedScore = 5.0;
        else if (rawAnswer >= 18)
          normalizedScore = 4.0;
        else if (rawAnswer >= 14)
          normalizedScore = 3.0;
        else if (rawAnswer >= 10)
          normalizedScore = 2.0;
        else
          normalizedScore = 1.0;
        break;
      case 1: // Q2 1限コマ数
        if (rawAnswer >= 5)
          normalizedScore = 5.0;
        else if (rawAnswer == 4)
          normalizedScore = 4.5;
        else if (rawAnswer == 3)
          normalizedScore = 3.5;
        else if (rawAnswer == 2)
          normalizedScore = 2.5;
        else if (rawAnswer == 1)
          normalizedScore = 1.5;
        else
          normalizedScore = 1.0;
        break;
      case 2: // Q3 週に休んだコマ数 (0-25 スライダー)
        if (rawAnswer == 0)
          normalizedScore = 5.0;
        else if (rawAnswer <= 2)
          normalizedScore = 4.0;
        else if (rawAnswer <= 4)
          normalizedScore = 3.0;
        else if (rawAnswer <= 7)
          normalizedScore = 2.0;
        else
          normalizedScore = 1.0;
        break;
      case 3: // Q4 代筆を頼んだ回数 (0-25 スライダー)
        if (rawAnswer == 0)
          normalizedScore = 5.0;
        else if (rawAnswer == 1)
          normalizedScore = 3.5;
        else if (rawAnswer == 2)
          normalizedScore = 2.0;
        else if (rawAnswer == 3)
          normalizedScore = 1.0;
        else
          normalizedScore = 0.5;
        break;
      case 4: // Q5 バイト回数
        if (rawAnswer >= 5)
          normalizedScore = 5.0;
        else if (rawAnswer >= 3)
          normalizedScore = 4.0;
        else if (rawAnswer >= 1)
          normalizedScore = 3.0;
        else
          normalizedScore = 1.5;
        break;
      case 5: // Q6 サークル参加回数
        if (rawAnswer >= 4)
          normalizedScore = 5.0;
        else if (rawAnswer >= 2)
          normalizedScore = 3.5;
        else if (rawAnswer == 1)
          normalizedScore = 2.0;
        else
          normalizedScore = 1.0;
        break;
      case 6: // Q7 空きコマ数
        if (rawAnswer <= 1)
          normalizedScore = 5.0;
        else if (rawAnswer <= 3)
          normalizedScore = 4.0;
        else if (rawAnswer <= 6)
          normalizedScore = 3.0;
        else if (rawAnswer <= 8)
          normalizedScore = 2.0;
        else
          normalizedScore = 1.0;
        break;
      case 7:
      case 8:
      case 9:
      case 10: // Q8-Q11 スライダー (1-10)
        normalizedScore = ((rawAnswer - 1) / 9.0) * 4.0 + 1.0;
        break;
      case 11: // Q12 未知の体験
        const scores_q12 = [1.0, 3.5, 5.0, 1.5];
        normalizedScore = scores_q12[rawAnswer];
        break;
      case 12: // Q13 計画と実行
        const scores_q13 = [5.0, 3.5, 4.5, 1.0];
        normalizedScore = scores_q13[rawAnswer];
        break;
      case 13: // Q14 興味関心
        const scores_q14 = [5.0, 4.5, 4.0, 1.0];
        normalizedScore = scores_q14[rawAnswer];
        break;
      case 14: // Q15 困難への対処
        const scores_q15 = [4.5, 4.0, 3.5, 1.0];
        normalizedScore = scores_q15[rawAnswer];
        break;
      case 15: // Q16 活動時間帯
        const scores_q16 = [4.5, 3.0, 3.5, 5.0, 3.5];
        normalizedScore = scores_q16[rawAnswer];
        break;
      case 16: // Q17 ゆるい授業中の過ごし方
        const scores_q17 = [4.0, 1.5, 3.5, 1.0];
        normalizedScore = scores_q17[rawAnswer];
        break;
    }
    return max(0.5, min(5.0, normalizedScore));
  }

  double _normalizeInverse(int questionIndex, int rawAnswer) {
    double normalizedScore = _normalizeAnswer(questionIndex, rawAnswer);
    return 6.0 - normalizedScore;
  }

  String _diagnoseCharacter(List<int> currentAnswers) {
    if (currentAnswers.length != 17) {
      return "エラー：回答数が不足しています";
    }
    List<double> norm = List.generate(
      currentAnswers.length,
      (i) => _normalizeAnswer(i, currentAnswers[i]),
    );

    double totalClasses = currentAnswers[0].toDouble();
    double skippedClassesRaw = currentAnswers[2].toDouble(); // Q3の生の値
    double skippedPercentage =
        (totalClasses > 0)
            ? (skippedClassesRaw / totalClasses)
            : (skippedClassesRaw > 0 ? 1.0 : 0.0);

    double normalizedSkippedRateScore;
    if (skippedPercentage == 0)
      normalizedSkippedRateScore = 5.0;
    else if (skippedPercentage <= 0.1)
      normalizedSkippedRateScore = 4.0;
    else if (skippedPercentage <= 0.25)
      normalizedSkippedRateScore = 3.0;
    else if (skippedPercentage <= 0.50)
      normalizedSkippedRateScore = 2.0;
    else
      normalizedSkippedRateScore = 1.0;

    // --- 各キャラクタースコア計算 (最新のバランス調整版) ---
    double knightScore = 0;
    double baseKnightFactor = 1.0;
    if (norm[9] < 2.5 || norm[7] < 2.5) {
      // Q10モチベかQ8集中力が低い場合
      baseKnightFactor = 0.3;
    }
    knightScore += norm[1] * 0.5 * baseKnightFactor;
    knightScore += norm[5] * 0.8 * baseKnightFactor;
    knightScore += norm[7] * 0.8 * baseKnightFactor;
    knightScore += norm[8] * 0.7 * baseKnightFactor;
    knightScore += norm[9] * 1.0; // モチベは直接評価
    knightScore += norm[6] * 0.5 * baseKnightFactor;
    if (currentAnswers[12] == 0 && norm[9] >= 3.5)
      knightScore += norm[12] * 1.8; // Q13計画(A)
    else if (currentAnswers[12] == 1 && norm[9] >= 3.0)
      knightScore += norm[12] * 1.4; // Q13計画(B)
    if (currentAnswers[14] == 1 && norm[9] >= 3.0)
      knightScore += norm[14] * 1.6; // Q15困難(B)
    double knightDiligenceScore = 0;
    knightDiligenceScore += normalizedSkippedRateScore * 1.0;
    knightDiligenceScore += norm[3] * 1.0;
    if (currentAnswers[16] == 0) knightDiligenceScore += norm[16] * 1.0;
    knightScore += knightDiligenceScore * baseKnightFactor;

    double witchScore = 0;
    witchScore += norm[7] * 2.5;
    if (currentAnswers[13] == 0) witchScore += norm[13] * 2.0;
    if (currentAnswers[15] == 3) witchScore += norm[15] * 2.0;
    if (norm[1] <= 2.0) witchScore += (6.0 - norm[1]) * 0.8;
    witchScore += norm[9] * 1.0;
    if (norm[5] <= 2.0) witchScore += (6.0 - norm[5]) * 0.5;
    if (norm[4] <= 2.0) witchScore += (6.0 - norm[4]) * 0.3;
    if (currentAnswers[16] == 2)
      witchScore += norm[16] * 0.8;
    else if (currentAnswers[16] == 0)
      witchScore += norm[16] * 0.4;

    double merchantScore = 0;
    merchantScore += norm[4] * 1.8;
    merchantScore += _normalizeInverse(6, currentAnswers[6]) * 1.2;
    if (currentAnswers[13] == 2) merchantScore += norm[13] * 1.8;
    merchantScore += norm[10] * 1.0;
    if (currentAnswers[14] == 2) merchantScore += norm[14] * 1.5;
    if (currentAnswers[12] == 1) merchantScore += norm[12] * 1.0;
    if (currentAnswers[16] == 2) merchantScore += norm[16] * 2.0;

    double gorillaScore = 0;
    if (currentAnswers[15] == 0) gorillaScore += norm[15] * 1.3;
    gorillaScore += norm[1] * 0.8;
    gorillaScore += norm[8] * 1.2;
    gorillaScore += norm[9] * 1.0;
    gorillaScore += norm[5] * 0.9;
    if (currentAnswers[14] == 0) gorillaScore += norm[14] * 2.0;
    gorillaScore += normalizedSkippedRateScore * 0.6;
    if (currentAnswers[16] == 3)
      gorillaScore -= 0.5;
    else if (currentAnswers[16] == 0)
      gorillaScore += 0.6;

    double adventurerScore = 0;
    if (currentAnswers[11] == 2)
      adventurerScore += norm[11] * 3.2;
    else if (currentAnswers[11] == 1)
      adventurerScore += norm[11] * 2.2;
    if (currentAnswers[12] == 2)
      adventurerScore += norm[12] * 3.0;
    else if (currentAnswers[12] == 1)
      adventurerScore += norm[12] * 1.5;
    if (currentAnswers[13] == 1) adventurerScore += norm[13] * 2.8;
    adventurerScore += _normalizeInverse(6, currentAnswers[6]) * 2.8;
    if (currentAnswers[12] == 0) adventurerScore -= 2.0;
    if (currentAnswers[15] == 4) adventurerScore += norm[15] * 2.8;
    if (currentAnswers[16] == 1)
      adventurerScore += norm[16] * 1.8;
    else if (currentAnswers[16] == 2 && currentAnswers[13] == 1)
      adventurerScore += norm[16] * 0.7;
    if (normalizedSkippedRateScore <= 2.0 && normalizedSkippedRateScore > 1.0)
      adventurerScore -= 0.8;
    else if (normalizedSkippedRateScore <= 1.0)
      adventurerScore -= 2.0;

    double godScoreSum = 0;
    List<int> godCriteriaIndices = [1, 5, 7, 8, 9]; // Q2, Q6, Q8, Q9, Q10
    for (int idx in godCriteriaIndices) {
      godScoreSum += norm[idx];
    }
    if (currentAnswers[12] == 0) godScoreSum += norm[12]; // Q13計画(A)
    if (currentAnswers[14] == 1) godScoreSum += norm[14]; // Q15困難(B)
    godScoreSum += normalizedSkippedRateScore;
    godScoreSum += norm[3]; // Q4代筆しない
    if (currentAnswers[16] == 0) godScoreSum += norm[16]; // Q17ゆる授業(A:聞く)
    if (godScoreSum >= 42.0 && norm[3] >= 4.5) {
      return "神";
    }

    bool isDefinitelyLoserByDaipitsu = norm[3] <= 2.0; // Q4代筆2回以上
    double reCalclulatedLoserScore = 0;
    reCalclulatedLoserScore += _normalizeInverse(1, currentAnswers[1]);
    reCalclulatedLoserScore += (6.0 - normalizedSkippedRateScore) * 3.0;
    reCalclulatedLoserScore += (6.0 - norm[3]) * 3.5;
    reCalclulatedLoserScore += _normalizeInverse(6, currentAnswers[6]) * 1.5;
    reCalclulatedLoserScore += _normalizeInverse(7, currentAnswers[7]) * 1.2;
    reCalclulatedLoserScore += _normalizeInverse(8, currentAnswers[8]);
    reCalclulatedLoserScore +=
        (currentAnswers[12] == 3 ? 5.0 : (norm[12] <= 2.0 ? 3.0 : 1.0));
    reCalclulatedLoserScore += _normalizeInverse(9, currentAnswers[9]) * 1.5;
    reCalclulatedLoserScore +=
        (currentAnswers[14] == 3 ? 5.0 : (norm[14] <= 2.0 ? 3.0 : 1.0));
    if (currentAnswers[16] == 1)
      reCalclulatedLoserScore += 5.0;
    else if (currentAnswers[16] == 3)
      reCalclulatedLoserScore += 4.5;
    if (reCalclulatedLoserScore >= 45.0 ||
        (isDefinitelyLoserByDaipitsu && reCalclulatedLoserScore >= 40.0) ||
        ((6.0 - normalizedSkippedRateScore) >= 4.5 && (6.0 - norm[3]) >= 4.0)) {
      return "カス大学生";
    }

    Map<String, double> scores = {
      "剣士": knightScore,
      "魔女": witchScore,
      "商人": merchantScore,
      "ゴリラ": gorillaScore,
      "冒険家": adventurerScore,
    };

    String finalCharacter = "剣士";
    double maxScore = -double.infinity;
    scores.forEach((character, score) {
      double effectiveScore = max(0, score);
      if (effectiveScore > maxScore) {
        maxScore = effectiveScore;
        finalCharacter = character;
      }
    });
    return finalCharacter;
  }

  Widget _buildQuestionWidget(int index) {
    if (index <= 10) {
      // スライダーはインデックス0から10 (Q1からQ11)
      bool isOneBased = (index >= 7 && index <= 10);
      double minVal = isOneBased ? 1.0 : 0.0;
      if (index == 2 || index == 3) {
        minVal = 0.0;
        isOneBased = false;
      }
      int divisionsVal = maxValues[index] - (isOneBased ? 1 : 0);
      if (index == 2 || index == 3) {
        divisionsVal = maxValues[index];
      }
      if (divisionsVal <= 0) divisionsVal = 1;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questions[index],
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Slider(
            value: answers[index].toDouble(),
            min: minVal,
            max: maxValues[index].toDouble(),
            divisions: divisionsVal,
            label: answers[index].toString(),
            activeColor: Colors.orange[700],
            inactiveColor: Colors.orange[200]?.withOpacity(0.7),
            onChanged: (value) {
              setState(() {
                answers[index] = value.toInt();
              });
            },
          ),
        ],
      );
    } else {
      // ドロップダウンはインデックス11から16 (Q12からQ17)
      final options = questionOptions[index] ?? [];
      int currentValue = answers[index];
      if (currentValue >= options.length) {
        currentValue = 0;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questions[index],
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<int>(
            style: TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: Colors.brown[700],
            value: currentValue,
            isExpanded: true,
            items:
                options.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
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
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('キャラ診断 ver4.0'),
        backgroundColor: Colors.brown,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/question_background_image.png', // ★背景画像パス
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < questions.length; i++) ...[
                  _buildQuestionWidget(i),
                  SizedBox(height: 24),
                ],
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.psychology, color: Colors.white),
                  label: Text(
                    '診断結果を見る',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: () async {
                    final String characterName = _diagnoseCharacter(answers);
                    if (characterName != "エラー：回答数が不足しています") {
                      await _saveDiagnosisToFirestore(answers, characterName);
                    } else {
                      print("診断エラーのため、Firestoreへの保存はスキップされました。");
                    }
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CharacterDecidePage(
                                answers: answers,
                                // ★ CharacterDecidePageに診断済みのキャラ名を渡す
                                diagnosedCharacterName: characterName,
                              ),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
