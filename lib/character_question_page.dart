import 'package:flutter/material.dart';
import 'dart:math'; // For max/min
import 'package:cloud_firestore/cloud_firestore.dart';

import 'character_decide_page.dart';
import 'character_data.dart' show characterFullDataGlobal;

// characterFullDataGlobal を使用するため
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_page.dart';

// 各質問の選択肢を定義 (ドロップダウン用 - 新しいインデックス10から19)
final Map<int, List<String>> questionOptions = {
  10: [
    '(A) 強い不安を感じ、できるだけ避けたい',
    '(B) 少し不安はあるが、面白そうなら挑戦してみたい',
    '(C) ワクワクする！むしろ積極的に挑戦したい',
    '(D) まずは誰かが成功するのを見てから判断したい',
  ],
  11: [
    '(A) 完璧な計画を立てるまで行動に移せない',
    '(B) 大まかな計画を立て、あとは状況に合わせて進める',
    '(C) 思い立ったら即行動！計画は後から考えるか、なくてもOK',
    '(D) 誰かに計画を立ててもらうか、指示に従うことが多い',
  ],
  12: [
    '(A) 一つのことを深く掘り下げていくのが好き',
    '(B) 広く浅く、色々なことに触れてみたい',
    '(C) 実用的なことや結果に繋がりやすいものに興味が湧く',
    '(D) あまり物事に強い興味を持つことは少ない',
  ],
  13: [
    '(A) とにかく気合と根性で正面から突破しようと試みる',
    '(B) 状況を分析し、計画を立て直したり、別の方法を探したりする',
    '(C) 友人や信頼できる人に相談してアドバイスを求める、または協力を仰ぐ',
    '(D) 時間を置く、諦める、または他のことに意識を向ける',
  ],
  14: [
    '(A) 早朝～午前中',
    '(B) 日中（午前～夕方）',
    '(C) 夕方～夜にかけて',
    '(D) 深夜～明け方',
    '(E) 特に決まっていない／日によって大きく変動する',
  ],
  15: [
    '(A) 一応授業を聞いている',
    '(B) スマートフォンやPCでゲームをする',
    '(C) 他の授業の課題や作業を進める',
    '(D) 寝る',
  ],
  16: [
    '(A) 安定と秩序、計画通りの達成感',
    '(B) 知的好奇心の充足、新しい知識や真理の探求',
    '(C) 実利的な成果、効率的な成功や利益',
    '(D) 新しい経験、スリルと自由、予測不可能な楽しさ',
    '(E) 困難を乗り越えること、自分自身への挑戦と成長',
    '(F) できるだけ心穏やかに、ストレスなく過ごすこと',
  ],
  17: [
    '(A) リスクはあっても、挑戦しがいがあるので積極的に引き受ける',
    '(B) 成功の確証が持てないなら、堅実にこなせる他の役割を選ぶ',
    '(C) 他のメンバーの様子を見て、安全そうであれば検討する',
    '(D) 面倒なことや責任が重いことは極力避けたい',
  ],
  18: [
    '(A) 一人で静かに過ごし、自分の趣味や好きなことに没頭する',
    '(B) 気の合う仲間と集まってワイワイ騒いだり、おしゃべりしたりする',
    '(C) とにかくたくさん寝る',
    '(D) 新しい場所に出かけたり、気分転換になるような活動をする',
  ],
  19: [
    '(A) 普段できないような壮大な計画（長期旅行、スキル習得など）を実行する',
    '(B) 自分の興味のある分野の研究や創作活動に完全に没頭する',
    '(C) 新しいビジネスのアイデアを練ったり、人脈作りに時間を費やす',
    '(D) とにかく体を動かす！合宿やトレーニング、アウトドア活動三昧',
    '(E) 何もせず、ひたすら寝たりゲームをしたりしてのんびり過ごす',
    '(F) 特に何も決めず、その時々の気分で面白そうなことをする',
  ],
};

class CharacterQuestionPage extends StatefulWidget {
  // ★ const CharacterQuestionPage({super.key}); から const を削除 (StatefulWidgetなので通常不要)
  CharacterQuestionPage({super.key});

  @override
  _CharacterQuestionPageState createState() => _CharacterQuestionPageState();
}

class _CharacterQuestionPageState extends State<CharacterQuestionPage> {
  final List<String> questions = [
    'Q1: 週に何コマ授業あるの？（0〜25コマ）',
    'Q2: 1限は何コマ埋まってる？（0〜5回）',
    'Q3: 週何コマくらい飛んでる？（友達に代筆頼んだりも含む）（0〜25コマ）',
    'Q4: 週に何日バイトをしてる？（0〜6回）',
    'Q5: 週に何日サークルや部活に参加してる？（0〜7日）', // ★★★ 文言変更 (最大7日) ★★★
    'Q6: 週に空きコマは何コマある？（0〜10コマ）',
    'Q7: 集中力には自信がある？（1:すぐ気が散る 〜 10:超集中型）',
    'Q8: ストレス耐性はどれくらいある？（1:すぐ病む 〜 10:鋼メンタル）',
    'Q9: 学業・活動へのモチベーションは？（1:やる気なし 〜 10:燃えている）',
    'Q10: 自分の生活がどれくらい忙しいと思う？（1:余裕 〜 10:超多忙）',
    'Q11: 未知の体験への態度を選んでね。',
    'Q12: 何か新しいことを始めようとするとき、あなたのスタイルは？',
    'Q13: 新しいことや興味のあることに対して、あなたはどちらに近い？',
    'Q14: 解決が難しい問題や大きな壁に直面した時、あなたはまずどうする？',
    'Q15: あなたが最も活動的になったり、集中できたりする時間帯はいつ？',
    'Q16: ゆるい授業中（楽単など）は何をして過ごすことが多い？',
    'Q17: あなたが最も価値を置くもの（または、行動する上で最も重視する動機）は以下のどれに近いですか？',
    'Q18: グループワークで、誰もやりたがらないが成功すれば大きな評価を得られる役割があります。あなたならどうしますか？',
    'Q19: 疲れたりストレスが溜まったりした時、どうやってエネルギーを回復する？',
    'Q20: もし1ヶ月間、全ての義務から解放されて自由に過ごせるとしたら、主に何をしますか？',
  ];

  final List<int> maxValues = [
    25, 5, 25, 6, 7, 10, // ★★★ Q5 (index 4) の最大値を 7 に変更 ★★★
    10, 10, 10, 10,
    (questionOptions[10]?.length ?? 1) - 1,
    (questionOptions[11]?.length ?? 1) - 1,
    (questionOptions[12]?.length ?? 1) - 1,
    (questionOptions[13]?.length ?? 1) - 1,
    (questionOptions[14]?.length ?? 1) - 1,
    (questionOptions[15]?.length ?? 1) - 1,
    (questionOptions[16]?.length ?? 1) - 1,
    (questionOptions[17]?.length ?? 1) - 1,
    (questionOptions[18]?.length ?? 1) - 1,
    (questionOptions[19]?.length ?? 1) - 1,
  ];

  late List<int?> answers;
  late List<bool> _isQuestionAnswered;
  int _answeredQuestionsCount = 0;
  final int _totalQuestions = 20;
  String? _selectedCharacter;
  final _nameController = TextEditingController();
  String? _selectedGrade;
  String? _selectedDepartment;
  String? _error;

  final List<String> _grades = ['1年', '2年', '3年', '4年', '院1年', '院2年'];
  final List<String> _departments = [
    '工学部',
    '理学部',
    '医学部',
    '歯学部',
    '薬学部',
    '文学部',
    '法学部',
    '経済学部',
    '商学部',
    '基礎工学部',
  ];

  @override
  void initState() {
    super.initState();
    _isQuestionAnswered = List.generate(_totalQuestions, (_) => false);
    answers = List.generate(_totalQuestions, (index) {
      if (index >= 6 && index <= 9) {
        // Q7-Q10 (index 6-9)
        return 1;
      } else if (index >= 0 && index <= 5) {
        // Q1-Q6 (index 0-5)
        return 0;
      } else {
        // Q11-Q20 (index 10-19)
        return null;
      }
    });
    _updateAnsweredCount();
  }

  void _updateAnsweredCount() {
    setState(() {
      _answeredQuestionsCount =
          _isQuestionAnswered.where((answered) => answered).length;
    });
  }

  Future<void> _saveDiagnosisToFirestore(
    List<int> userAnswers,
    String diagnosedCharacter,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('ユーザーがログインしていません。Firestoreへの保存をスキップします。');
        return;
      }

      print('--- Firestoreへの保存処理を開始します (QuestionPageから) ---');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'character': diagnosedCharacter,
        'diagnostics': userAnswers,
        'lastDiagnosed': FieldValue.serverTimestamp(),
        'name': _nameController.text,
        'grade': _selectedGrade,
        'department': _selectedDepartment,
      }, SetOptions(merge: true));

      print('--- Firestoreへの保存が完了しました ---');
    } catch (e) {
      print('Firestoreへの保存中にエラーが発生しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    }
  }

  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  // ★ 正規化ロジック (_normalizeAnswer) - Q5(サークル)の最大値変更を反映 ★
  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  double _normalizeAnswer(int questionIndex, int rawAnswer) {
    double normalizedScore = 3.0;
    switch (questionIndex) {
      case 0:
        normalizedScore =
            (rawAnswer >= 22)
                ? 5.0
                : (rawAnswer >= 18)
                ? 4.0
                : (rawAnswer >= 14)
                ? 3.0
                : (rawAnswer >= 10)
                ? 2.0
                : 1.0;
        break; // Q1 履修コマ
      case 1:
        normalizedScore =
            (rawAnswer >= 5)
                ? 5.0
                : (rawAnswer == 4)
                ? 4.5
                : (rawAnswer == 3)
                ? 3.5
                : (rawAnswer == 2)
                ? 2.5
                : (rawAnswer == 1)
                ? 1.5
                : 1.0;
        break; // Q2 1限コマ
      case 2:
        normalizedScore =
            (rawAnswer == 0)
                ? 5.0
                : (rawAnswer <= 2)
                ? 4.0
                : (rawAnswer <= 5)
                ? 3.0
                : (rawAnswer <= 8)
                ? 2.0
                : 1.0;
        break; // Q3 飛んだ/代筆
      case 3:
        normalizedScore =
            (rawAnswer >= 5)
                ? 5.0
                : (rawAnswer >= 3)
                ? 4.0
                : (rawAnswer >= 1)
                ? 3.0
                : 1.5;
        break; // Q4 バイト
      case 4: // Q5 サークル参加日数 (0-7日) ★★★ ロジック変更 ★★★
        if (rawAnswer >= 6)
          normalizedScore = 5.0; // 6-7日
        else if (rawAnswer >= 4)
          normalizedScore = 4.0; // 4-5日
        else if (rawAnswer >= 2)
          normalizedScore = 3.0; // 2-3日
        else if (rawAnswer == 1)
          normalizedScore = 1.5; // 1日
        else
          normalizedScore = 1.0; // 0日
        break;
      case 5:
        normalizedScore =
            (rawAnswer <= 1)
                ? 5.0
                : (rawAnswer <= 3)
                ? 4.0
                : (rawAnswer <= 6)
                ? 3.0
                : (rawAnswer <= 8)
                ? 2.0
                : 1.0;
        break; // Q6 空きコマ
      case 6:
      case 7:
      case 8:
      case 9:
        normalizedScore = ((rawAnswer - 1) / 9.0) * 4.0 + 1.0;
        break; // Q7-Q10 (1-10スケール)
      case 10:
        const scores = [1.0, 3.5, 5.0, 1.5];
        normalizedScore = scores[rawAnswer];
        break; // Q11 未知
      case 11:
        const scores = [5.0, 3.5, 4.5, 1.0];
        normalizedScore = scores[rawAnswer];
        break; // Q12 計画
      case 12:
        const scores = [5.0, 4.5, 4.0, 1.0];
        normalizedScore = scores[rawAnswer];
        break; // Q13 興味
      case 13:
        const scores = [4.5, 4.0, 3.5, 1.0];
        normalizedScore = scores[rawAnswer];
        break; // Q14 困難
      case 14:
        const scores = [4.5, 3.0, 3.5, 5.0, 3.5];
        normalizedScore = scores[rawAnswer];
        break; // Q15 活動時間
      case 15:
        const scores = [4.0, 1.5, 3.5, 1.0];
        normalizedScore = scores[rawAnswer];
        break; // Q16 ゆる授業
      case 16: // Q17 価値観/動機
        const scores_q17 = [
          3.0,
          4.5,
          3.5,
          4.8,
          4.2,
          1.2,
        ]; // A安定3.0, B知的好奇4.5, C実利3.5, D新規経験4.8, E困難克服4.2, Fストレス回避1.2 (微調整)
        normalizedScore = scores_q17[rawAnswer];
        break;
      case 17: // Q18 グループワークリスク
        const scores_q18 = [4.8, 3.0, 2.0, 1.0]; // A挑戦4.8 (微調整)
        normalizedScore = scores_q18[rawAnswer];
        break;
      case 18: // Q19 エネルギー回復
        const scores_q19 = [3.5, 3.8, 1.5, 5.0]; // B仲間3.8 (微調整)
        normalizedScore = scores_q19[rawAnswer];
        break;
      case 19: // Q20 1ヶ月自由時間
        const scores_q20 = [
          4.0,
          4.5,
          3.5,
          4.2,
          1.0,
          4.8,
        ]; // D体動かす4.2, F気分で4.8 (微調整)
        normalizedScore = scores_q20[rawAnswer];
        break;
    }
    return max(0.5, min(5.0, normalizedScore));
  }

  double _normalizeInverse(int questionIndex, int rawAnswer) {
    double normalizedScore = _normalizeAnswer(questionIndex, rawAnswer);
    return 6.0 - normalizedScore;
  }

  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  // ★ 診断ロジック (_diagnoseCharacter) - 目標分布 (神5, カス5, ゴリラ18, 魔女18, 剣士18, 冒険家18, 商人18) に調整 ★
  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  String _diagnoseCharacter(List<int> currentAnswersNonNull) {
    if (currentAnswersNonNull.length != 20) {
      return "エラー：回答数が不足しています";
    }
    List<double> norm = List.generate(
      currentAnswersNonNull.length,
      (i) => _normalizeAnswer(i, currentAnswersNonNull[i]),
    );

    double totalClasses = currentAnswersNonNull[0].toDouble(); // Q1
    double skippedOrDaipitsuRaw = currentAnswersNonNull[2].toDouble(); // Q3
    double effectiveSkippedPercentage =
        (totalClasses > 0)
            ? (skippedOrDaipitsuRaw / totalClasses)
            : (skippedOrDaipitsuRaw > 0 ? 1.0 : 0.0);
    double nonAttendanceScore;
    if (effectiveSkippedPercentage == 0)
      nonAttendanceScore = 5.0;
    else if (effectiveSkippedPercentage <= 0.05)
      nonAttendanceScore = 4.5; // 5%以内
    else if (effectiveSkippedPercentage <= 0.15)
      nonAttendanceScore = 3.5; // 15%以内
    else if (effectiveSkippedPercentage <= 0.30)
      nonAttendanceScore = 2.0; // 30%以内
    else
      nonAttendanceScore = 1.0;

    // --- 各キャラクタースコア計算 (目標分布: 神5, カス5, 他各18) ---
    // インデックスは新しい質問順序に対応 (0-19)

    double knightScore = 0; // 目標18%
    double baseKnightFactor = 1.0;
    if (norm[8] < 2.8 || norm[6] < 2.8) {
      baseKnightFactor = 0.45;
    } // Q9モチベ, Q7集中力 (基準少し緩和)
    knightScore += norm[1] * 0.5 * baseKnightFactor; // Q2 1限
    knightScore += norm[4] * 0.8 * baseKnightFactor; // Q5サークル (少しアップ)
    knightScore += norm[6] * 0.9 * baseKnightFactor; // Q7集中力
    knightScore += norm[7] * 0.8 * baseKnightFactor; // Q8ストレス
    knightScore += norm[8] * 1.1; // Q9モチベ (少しアップ)
    knightScore += norm[5] * 0.5 * baseKnightFactor; // Q6空きコマ少ない (少しアップ)
    if (currentAnswersNonNull[11] == 0 && norm[8] >= 3.0)
      knightScore += norm[11] * 1.7; // Q12計画(A)
    else if (currentAnswersNonNull[11] == 1 && norm[8] >= 2.5)
      knightScore += norm[11] * 1.2; // Q12計画(B)
    if (currentAnswersNonNull[13] == 1 && norm[8] >= 2.5)
      knightScore += norm[13] * 1.4; // Q14困難(B)
    knightScore += nonAttendanceScore * 1.3; // Q3(統合版)欠席/代筆少ない (重要度少しアップ)
    if (currentAnswersNonNull[15] == 0)
      knightScore += norm[15] * 1.0; // Q16ゆる授業(A)
    if (currentAnswersNonNull[16] == 0)
      knightScore += norm[16] * 1.1; // Q17価値観(A:安定秩序) (少しアップ)
    if (currentAnswersNonNull[17] == 1)
      knightScore += norm[17] * 0.9; // Q18リスク(B:堅実) (少しアップ)
    if (currentAnswersNonNull[19] == 0)
      knightScore += norm[19] * 0.8; // Q20自由時間(A:壮大計画) (少しアップ)

    double witchScore = 0; // 目標18%
    witchScore += norm[6] * 2.4; // Q7集中力 (少しダウン)
    if (currentAnswersNonNull[12] == 0)
      witchScore += norm[12] * 2.0; // Q13興味(A:深く狭く)
    if (currentAnswersNonNull[14] == 3)
      witchScore += norm[14] * 1.8; // Q15活動(D:深夜) (少しダウン)
    if (norm[1] <= 2.2) witchScore += (6.0 - norm[1]) * 0.7;
    witchScore += norm[8] * 0.9; // Q9モチベ
    if (norm[4] <= 2.2) witchScore += (6.0 - norm[4]) * 0.5;
    if (norm[3] <= 2.2) witchScore += (6.0 - norm[3]) * 0.3;
    if (currentAnswersNonNull[15] == 2)
      witchScore += norm[15] * 0.8; // Q16ゆる授業(C)
    if (currentAnswersNonNull[16] == 1)
      witchScore += norm[16] * 1.6; // Q17価値観(B:知的好奇) (少しアップ)
    if (currentAnswersNonNull[18] == 0)
      witchScore += norm[18] * 1.3; // Q19エネルギー(A:一人趣味) (少しアップ)
    if (currentAnswersNonNull[19] == 1)
      witchScore += norm[19] * 1.6; // Q20自由時間(B:研究創作) (少しアップ)

    double merchantScore = 0; // 目標18%
    merchantScore += norm[3] * 1.7; // Q4バイト (少しダウン)
    merchantScore +=
        _normalizeInverse(5, currentAnswersNonNull[5]) * 1.1; // Q6空きコマ多い
    if (currentAnswersNonNull[12] == 2)
      merchantScore += norm[12] * 1.7; // Q13興味(C:実用的)
    merchantScore += norm[9] * 0.9; // Q10忙しさ
    if (currentAnswersNonNull[13] == 2)
      merchantScore += norm[13] * 1.4; // Q14困難(C:相談)
    if (currentAnswersNonNull[11] == 1) merchantScore += norm[11] * 0.9;
    if (currentAnswersNonNull[15] == 2)
      merchantScore += norm[15] * 1.8; // Q16ゆる授業(C)
    if (currentAnswersNonNull[16] == 2)
      merchantScore += norm[16] * 1.7; // Q17価値観(C:実利)
    if (currentAnswersNonNull[17] == 1 || currentAnswersNonNull[17] == 2)
      merchantScore += norm[17] * 0.9;
    if (currentAnswersNonNull[18] == 1)
      merchantScore += norm[18] * 1.1; // Q19エネルギー(B:仲間)
    if (currentAnswersNonNull[19] == 2)
      merchantScore += norm[19] * 1.6; // Q20自由時間(C:ビジネス)

    double gorillaScore = 0; // 目標18% (大幅アップ狙い)
    if (currentAnswersNonNull[14] == 0)
      gorillaScore += norm[14] * 1.8; // Q15活動(A:早朝) (大幅アップ)
    gorillaScore += norm[1] * 1.2; // Q2 1限 (大幅アップ)
    gorillaScore += norm[7] * 1.6; // Q8ストレス (大幅アップ)
    gorillaScore += norm[8] * 1.5; // Q9モチベ (大幅アップ)
    gorillaScore += norm[4] * 1.6; // Q5サークル (大幅アップ)
    if (currentAnswersNonNull[13] == 0)
      gorillaScore += norm[13] * 2.8; // Q14困難(A:根性) (最重要、大幅アップ)
    gorillaScore += nonAttendanceScore * 1.0; // 少しアップ
    if (currentAnswersNonNull[15] == 0)
      gorillaScore += norm[15] * 0.8; // 聞くも評価
    else if (currentAnswersNonNull[15] == 3)
      gorillaScore += norm[15] * 0.3; // 寝るは少しだけマイナスを緩和
    if (currentAnswersNonNull[16] == 4)
      gorillaScore += norm[16] * 2.2; // Q17価値観(E:困難克服) (超重要)
    if (currentAnswersNonNull[18] == 1 || currentAnswersNonNull[18] == 2)
      gorillaScore += norm[18] * 1.0; // Q19エネルギー(仲間/寝る)
    if (currentAnswersNonNull[19] == 3)
      gorillaScore += norm[19] * 2.2; // Q20自由時間(D:体動かす) (超重要)

    double adventurerScore = 0; // 目標18% (大幅抑制狙い)
    if (currentAnswersNonNull[10] == 2)
      adventurerScore += norm[10] * 1.0; // Q11未知(C) (大幅ダウン)
    else if (currentAnswersNonNull[10] == 1)
      adventurerScore += norm[10] * 0.6; // (大幅ダウン)
    if (currentAnswersNonNull[11] == 2)
      adventurerScore += norm[11] * 1.0; // Q12計画(C) (大幅ダウン)
    else if (currentAnswersNonNull[11] == 1)
      adventurerScore += norm[11] * 0.5; // (大幅ダウン)
    if (currentAnswersNonNull[12] == 1)
      adventurerScore += norm[12] * 0.9; // Q13興味(B) (大幅ダウン)
    adventurerScore +=
        _normalizeInverse(5, currentAnswersNonNull[5]) *
        1.0; // Q6空きコマ多い (大幅ダウン)
    if (currentAnswersNonNull[11] == 0) adventurerScore -= 2.0; // 完璧計画ペナルティ維持
    if (currentAnswersNonNull[14] == 4)
      adventurerScore += norm[14] * 1.0; // Q15活動(E) (大幅ダウン)
    if (currentAnswersNonNull[15] == 1)
      adventurerScore += norm[15] * 0.8; // Q16ゆる授業(B)
    if (currentAnswersNonNull[16] == 3)
      adventurerScore += norm[16] * 1.2; // Q17価値観(D) (大幅ダウン)
    if (currentAnswersNonNull[17] == 0)
      adventurerScore += norm[17] * 1.0; // Q18リスク(A) (大幅ダウン)
    if (currentAnswersNonNull[18] == 3)
      adventurerScore += norm[18] * 1.0; // Q19エネルギー(D) (大幅ダウン)
    if (currentAnswersNonNull[19] == 0 || currentAnswersNonNull[19] == 5)
      adventurerScore += norm[19] * 0.7;
    if (nonAttendanceScore <= 2.0) adventurerScore -= 1.5; // サボりすぎペナルティ少し強化

    // --- レアキャラ判定 ---
    double godScoreSum = 0;
    List<int> godCriteriaIndices = [1, 4, 6, 7, 8];
    for (int idx in godCriteriaIndices) {
      godScoreSum += norm[idx];
    }
    if (currentAnswersNonNull[11] == 0)
      godScoreSum += norm[11] * 1.3; // 計画A 重視（1.1→1.3）
    if (currentAnswersNonNull[13] == 1)
      godScoreSum += norm[13] * 1.2; // 困難B 少し重視（1.1→1.2）
    godScoreSum += nonAttendanceScore * 1.5; // 真面目さ重視（1.2→1.5）
    if (currentAnswersNonNull[15] == 0)
      godScoreSum += norm[15] * 1.2; // ゆる授業A 少し重視（1.1→1.2）
    if (currentAnswersNonNull[16] == 0 || currentAnswersNonNull[16] == 4)
      godScoreSum += norm[16] * 1.3; // 価値観AorE 重視（1.2→1.3）
    if (currentAnswersNonNull[17] == 0)
      godScoreSum += norm[17] * 1.2; // リスクA 少し重視（1.1→1.2）
    if (currentAnswersNonNull[19] == 0 || currentAnswersNonNull[19] == 1)
      godScoreSum += norm[19] * 1.2; // 自由時間AorB 少し重視（1.1→1.2）

    // 追加の重み付け
    godScoreSum += norm[6] * 0.3; // 集中力 追加ボーナス
    godScoreSum += norm[8] * 0.2; // モチベーション 追加ボーナス

    // 12項目。目標5%。閾値を調整 (48.0→40.0)
    if (godScoreSum >= 40.0) {
      // ★ 閾値を40に調整
      return "神";
    }

    double reCalclulatedLoserScore = 0;
    reCalclulatedLoserScore += _normalizeInverse(1, currentAnswersNonNull[1]);
    reCalclulatedLoserScore +=
        (6.0 - nonAttendanceScore) * 3.8; // ★ Q3(統合版)欠席/代筆多い(超超超重要)
    reCalclulatedLoserScore +=
        _normalizeInverse(5, currentAnswersNonNull[5]) * 1.5;
    reCalclulatedLoserScore +=
        _normalizeInverse(6, currentAnswersNonNull[6]) * 1.3;
    reCalclulatedLoserScore +=
        _normalizeInverse(7, currentAnswersNonNull[7]) * 1.1;
    reCalclulatedLoserScore +=
        (currentAnswersNonNull[11] == 3
            ? 5.5
            : (norm[11] <= 2.5 ? 3.5 : 1.0)); // 計画D
    reCalclulatedLoserScore +=
        _normalizeInverse(8, currentAnswersNonNull[8]) * 1.6; // モチベ低い
    reCalclulatedLoserScore +=
        (currentAnswersNonNull[13] == 3
            ? 5.5
            : (norm[13] <= 2.5 ? 3.5 : 1.0)); // 困難D
    if (currentAnswersNonNull[15] == 1 || currentAnswersNonNull[15] == 3)
      reCalclulatedLoserScore += 5.5; // ゆる授業 B or D
    if (currentAnswersNonNull[16] == 5)
      reCalclulatedLoserScore += norm[16] * 1.8; // 価値観F
    if (currentAnswersNonNull[17] == 3)
      reCalclulatedLoserScore += norm[17] * 1.8; // リスクD
    if (currentAnswersNonNull[18] == 2)
      reCalclulatedLoserScore += norm[18] * 1.3; // エネルギーC
    if (currentAnswersNonNull[19] == 4 || currentAnswersNonNull[19] == 5)
      reCalclulatedLoserScore += norm[19] * 1.8;
    // 目標5%。閾値を調整 (例: 52点)
    if (reCalclulatedLoserScore >= 52.0 ||
        ((6.0 - nonAttendanceScore) >= 4.5 &&
            reCalclulatedLoserScore >= 48.0)) {
      return "カス大学生";
    }

    Map<String, double> scores = {
      "剣士": knightScore,
      "魔女": witchScore,
      "商人": merchantScore,
      "ゴリラ": gorillaScore,
      "冒険家": adventurerScore,
    };

    // print(scores);

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
    // ... (UI部分はご提示のものを維持)
    if (index <= 9) {
      // スライダーはQ1～Q10 (インデックス0～9)
      int startValue = (index >= 6 && index <= 9) ? 1 : 0;
      int endValue = maxValues[index];
      // Q5(サークル)の場合は最大値が7になっていることを確認
      if (index == 4) endValue = 7; // ★ Q5サークルの

      // 各数値のボタンを作成
      List<Widget> valueButtons = [];
      for (int value = startValue; value <= endValue; value++) {
        bool isSelected = answers[index] == value;
        valueButtons.add(
          Padding(
            // ボタン間のスペースを確保するためにPaddingを追加
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.tealAccent[400]
                            : Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      if (isSelected)
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.tealAccent[400]!.withOpacity(0.8),
                          offset: Offset(0, 0),
                        ),
                    ],
                    fontFamily: 'NotoSansJP',
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  width: 40, // ボタンの幅を固定
                  height: 40, // ボタンの高さを固定して円形にする
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        isSelected
                            ? LinearGradient(
                              colors: [
                                Colors.tealAccent[200]!.withOpacity(0.8),
                                Colors.tealAccent[700]!.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                    color:
                        isSelected ? null : Colors.brown[600]?.withOpacity(0.7),
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.tealAccent[400]!
                              : Colors.white.withOpacity(0.7),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.tealAccent[400]!.withOpacity(0.6),
                          blurRadius: 10.0,
                          spreadRadius: 2.0,
                        ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          answers[index] = value;
                          if (!_isQuestionAnswered[index]) {
                            _isQuestionAnswered[index] = true;
                            _updateAnsweredCount();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // 丸いボタンに合わせたborderRadius
                      child: Center(
                        // ラジオボタン内に何も表示しない
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questions[index],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'NotoSansJP',
            ),
          ),
          SizedBox(height: 12),
          // スクロール可能なSingleChildScrollViewでボタンを一列に配置
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // 左寄せにする
              children: valueButtons,
            ),
          ),
        ],
      );
    } else {
      // ドロップダウンはインデックス10から19 (Q11からQ20)
      final options =
          questionOptions[index] ?? []; // ★ questionOptionsのキーとindexを合わせる
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questions[index],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'NotoSansJP',
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            value: answers[index],
            hint: Text(
              '選択してください',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'NotoSansJP',
              ),
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'NotoSansJP',
            ),
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
            isExpanded: true,
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text(
                  '未選択',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'NotoSansJP',
                  ),
                ),
              ),
              ...options.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontFamily: 'NotoSansJP',
                    ),
                  ),
                );
              }).toList(),
            ],
            onChanged: (int? newValue) {
              setState(() {
                answers[index] = newValue;
                if (newValue != null && !_isQuestionAnswered[index]) {
                  _isQuestionAnswered[index] = true;
                  _updateAnsweredCount();
                } else if (newValue == null && _isQuestionAnswered[index]) {
                  _isQuestionAnswered[index] = false;
                  _updateAnsweredCount();
                }
              });
            },
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress =
        (_totalQuestions > 0) ? _answeredQuestionsCount / _totalQuestions : 0;
    bool allAnswered = _answeredQuestionsCount == _totalQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'キャラ診断 ver5.0',
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansJP',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/question_background_image.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '診断進行度: ${_answeredQuestionsCount} / $_totalQuestions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ],
                        fontFamily: 'NotoSansJP',
                      ),
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[700]?.withOpacity(0.8),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepOrangeAccent[400]!,
                        ),
                        minHeight: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              allAnswered
                                  ? Colors.orange[700]
                                  : Colors.grey[600],
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSansJP',
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        onPressed:
                            allAnswered
                                ? () async {
                                  final List<int> finalAnswers =
                                      answers.map((ans) => ans ?? 0).toList();

                                  final String characterName =
                                      _diagnoseCharacter(finalAnswers);
                                  if (characterName != "エラー：回答数が不足しています") {
                                    await _saveDiagnosisToFirestore(
                                      finalAnswers,
                                      characterName,
                                    );
                                  } else {
                                    print("診断エラーのため、Firestoreへの保存はスキップされました。");
                                  }
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CharacterDecidePage(
                                              answers: finalAnswers,
                                              diagnosedCharacterName:
                                                  characterName,
                                            ),
                                      ),
                                    );
                                  }
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CharacterDecidePage(
                                              diagnosedCharacterName:
                                                  characterName,
                                              answers: finalAnswers,
                                            ),
                                      ),
                                    );
                                  }
                                }
                                : null,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitCharacter() async {
    if (_selectedCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'キャラクターを選択してください',
            style: TextStyle(fontFamily: 'NotoSansJP', color: Colors.white),
          ),
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 2.5),
          ),
        ),
      );
      return;
    }

    if (_nameController.text.isEmpty ||
        _selectedGrade == null ||
        _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'すべての項目を入力してください',
            style: TextStyle(fontFamily: 'NotoSansJP', color: Colors.white),
          ),
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 2.5),
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 選択されたキャラクターの画像を取得
      String? characterImage;
      if (_selectedCharacter != null &&
          characterFullDataGlobal.containsKey(_selectedCharacter)) {
        characterImage = characterFullDataGlobal[_selectedCharacter]!['image'];
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'character': _selectedCharacter,
        'characterImage': characterImage, // 画像パスを保存
        'characterSelected': true,
        'name': _nameController.text.trim(),
        'grade': _selectedGrade,
        'department': _selectedDepartment,
        'profileCompleted': true,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserProfilePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'エラーが発生しました: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansJP',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 2.5),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
