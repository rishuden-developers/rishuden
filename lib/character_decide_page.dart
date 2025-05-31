import 'package:flutter/material.dart';
import 'dart:math'; // Min/Max を使う可能性のため (今回は直接使っていません)
import 'park_page.dart'; // 広場画面へ遷移するために必要

class CharacterDecidePage extends StatelessWidget {
  final List<int> answers; // 15個の質問の回答を格納したリスト

  const CharacterDecidePage({super.key, required this.answers});

  // 15個の質問に対応する正規化関数
  // 各質問のrawAnswer（スライダーの値または選択肢のインデックス）を1.0〜5.0のスコアに変換
  double _normalizeAnswer(int questionIndex, int rawAnswer) {
    double normalizedScore = 3.0; // デフォルトは中間点

    // 新しい質問リストのインデックスに対応
    // 0-8: 元の質問（一部変更あり）
    // 9-14: 新しい選択式の質問
    switch (questionIndex) {
      // --- 元の質問（インデックス調整済み、正規化ルール見直し） ---
      case 0: // Q0: 週に何コマ授業を履修していますか？（0〜25）
        // データ平均16コマ。15-20コマが多い。
        if (rawAnswer >= 20)
          normalizedScore = 5.0; // 非常に多い
        else if (rawAnswer >= 16)
          normalizedScore = 4.0; // やや多い
        else if (rawAnswer >= 12)
          normalizedScore = 3.0; // 平均的
        else if (rawAnswer >= 8)
          normalizedScore = 2.0; // やや少ない
        else
          normalizedScore = 1.0; // 少ない
        break;
      case 1: // Q1: 1限に入っているコマ数は何回ですか？（0〜5）
        // データ平均3コマ。
        if (rawAnswer >= 4)
          normalizedScore = 5.0; // 非常に多い(朝型)
        else if (rawAnswer == 3)
          normalizedScore = 4.0; // 多い
        else if (rawAnswer == 2)
          normalizedScore = 3.0; // 平均的
        else if (rawAnswer == 1)
          normalizedScore = 2.0; // 少ない
        else
          normalizedScore = 1.0; // 全くない(夜型傾向)
        break;
      case 2: // Q2: 週に何回バイトをしていますか？（0〜6）
        // データ平均1.1回。0回の人が半数。
        if (rawAnswer >= 5)
          normalizedScore = 5.0; // かなり多い
        else if (rawAnswer >= 3)
          normalizedScore = 4.0; // 多い
        else if (rawAnswer >= 1)
          normalizedScore = 3.0; // 普通・している
        else
          normalizedScore = 1.5; // していない (以前3.0だったが、活動性低いと評価)
        break;
      case 3: // Q3: 週に何回サークルや部活に参加していますか？（0〜5） (旧Q4)
        // データ平均2.2回
        if (rawAnswer >= 4)
          normalizedScore = 5.0; // 非常に活動的
        else if (rawAnswer >= 2)
          normalizedScore = 3.5; // 活動的
        else if (rawAnswer == 1)
          normalizedScore = 2.0; // 少し参加
        else
          normalizedScore = 1.0; // 不参加
        break;
      case 4: // Q4: 週に空きコマは何コマありますか？（0〜10） (旧Q5)
        // データ平均1.5コマ。少ない人が多い。少ないほど高スコア（忙しい）
        if (rawAnswer <= 1)
          normalizedScore = 5.0; // ほぼ無い(超多忙)
        else if (rawAnswer <= 3)
          normalizedScore = 4.0; // 少ない(多忙)
        else if (rawAnswer <= 6)
          normalizedScore = 3.0; // 普通
        else if (rawAnswer <= 8)
          normalizedScore = 2.0; // やや多い(余裕あり)
        else
          normalizedScore = 1.0; // 多い(かなり余裕)
        break;
      case 5: // Q5: 集中力には自信がありますか？（1〜10） (旧Q6)
        // 線形スケーリング (1点が1.0点、10点が5.0点になるように調整)
        normalizedScore = ((rawAnswer - 1) / 9.0) * 4.0 + 1.0;
        break;
      case 6: // Q6: ストレス耐性はどれくらいありますか？（1〜10） (旧Q7)
        normalizedScore = ((rawAnswer - 1) / 9.0) * 4.0 + 1.0;
        break;
      case 7: // Q7: 学業・活動へのモチベーションは？（1〜10） (旧Q9)
        normalizedScore = ((rawAnswer - 1) / 9.0) * 4.0 + 1.0;
        break;
      case 8: // Q8: 自分の生活がどれくらい忙しいと感じますか？（1〜10） (旧Q10)
        normalizedScore = ((rawAnswer - 1) / 9.0) * 4.0 + 1.0;
        break;

      // --- 新しい選択式の質問 (rawAnswerは選択肢のインデックス 0始まり) ---
      case 9: // Q9: 未知の体験への態度 (A)抵抗/(B)少し不安だが興味/(C)ワクワク/(D)情報ないとダメ
        const unknown_exp_scores = [1.0, 3.0, 5.0, 1.5];
        normalizedScore = unknown_exp_scores[rawAnswer];
        break;
      case 10: // Q10: 計画と実行のスタイル (A)完璧計画/(B)大まか計画/(C)即行動/(D)他者依存
        const plan_style_scores = [5.0, 3.5, 4.5, 1.0]; // Cの即行動も冒険家には高い
        normalizedScore = plan_style_scores[rawAnswer];
        break;
      case 11: // Q11: 興味関心の深さ/広さ (A)深く狭く/(B)広く浅く/(C)実用的/(D)興味薄
        const interest_style_scores = [5.0, 4.5, 4.0, 1.0];
        normalizedScore = interest_style_scores[rawAnswer];
        break;
      case 12: // Q12: 困難への対処法 (A)根性/(B)分析計画/(C)相談協力/(D)回避諦め
        const difficulty_coping_scores = [4.5, 4.0, 3.5, 1.0];
        normalizedScore = difficulty_coping_scores[rawAnswer];
        break;
      case 13: // Q13: 活動時間帯 (A)早朝午前/(B)日中/(C)夕方夜/(D)深夜明け方/(E)不定
        const activity_time_scores = [5.0, 3.0, 3.5, 5.0, 2.0]; // AとDを高く
        normalizedScore = activity_time_scores[rawAnswer];
        break;
      case 14: // Q14: 代筆を頼む回数(1週間) (A)0回/(B)1回/(C)2回/(D)3回以上/(E)頼めない/発想なし
        // このスコアは「真面目さ」を示す。カス大学生はこれの逆転スコアを強く使う。
        const daipitsu_scores = [5.0, 2.5, 1.0, 0.5, 4.0]; // Eはややポジティブ
        normalizedScore = daipitsu_scores[rawAnswer];
        break;
    }
    // スコアが0.5未満にならないように、また5.0を超えないように丸める（念のため）
    return max(0.5, min(5.0, normalizedScore));
  }

  // 逆転スコア（低いほどキャラに寄る場合、1.0-5.0の範囲に正規化されている前提）
  // 例: 5.0点なら1.0点、1.0点なら5.0点
  double _normalizeInverse(int questionIndex, int rawAnswer) {
    double normalizedScore = _normalizeAnswer(questionIndex, rawAnswer);
    return (5.0 - normalizedScore) + 1.0;
  }

  String _diagnoseCharacter(List<int> rawAnswers) {
    if (rawAnswers.length != 15) {
      // 念のため回答数のチェック
      return "エラー：回答数が不足しています";
    }

    List<double> norm = List.generate(
      rawAnswers.length,
      (i) => _normalizeAnswer(i, rawAnswers[i]),
    );

    // 各キャラクタースコアの計算
    // 重み付けや使用する質問は、キャラクターのイメージに合わせて調整

    // 剣士: バランス型、努力家、計画的
    double knightScore = 0;
    knightScore += norm[0] * 1.5; // 履修コマ数 (多い)
    knightScore += norm[1] * 1.0; // 1限コマ数 (朝型傾向)
    knightScore += norm[3] * 1.0; // サークル参加 (活動的)
    knightScore += norm[5] * 1.2; // 集中力
    knightScore += norm[6] * 1.0; // ストレス耐性
    knightScore +=
        (norm[10] == 5.0 || norm[10] == 3.5
            ? norm[10] * 1.5
            : 0); // 計画と実行(A:完璧計画 or B:大まか計画)
    knightScore += norm[7] * 1.2; // モチベーション
    knightScore +=
        _normalizeInverse(4, rawAnswers[4]) * 1.0; // 空きコマ少ない (多忙で頑張る)
    knightScore += (norm[12] == 4.0 ? 1.5 : 0); // 困難への対処(B:分析計画)

    // 魔女: 探求心、マイペース、夜型、専門集中
    double witchScore = 0;
    witchScore += norm[5] * 2.5; // 集中力 (最重要)
    witchScore += (norm[11] == 5.0 ? 2.0 : 0); // 興味関心(A:深く狭く)
    witchScore += (norm[13] == 5.0 ? 2.0 : 0); // 活動時間帯(D:深夜明け方)
    witchScore += _normalizeInverse(1, rawAnswers[1]) * 1.0; // 1限少ない (夜型)
    witchScore += norm[7] * 1.0; // モチベーション (探求心として)
    witchScore += _normalizeInverse(3, rawAnswers[3]) * 0.8; // サークル不参加/少ない
    witchScore += _normalizeInverse(2, rawAnswers[2]) * 0.5; // バイト少ない/しない

    // 商人: コミュ力、実利主義、要領が良い
    double merchantScore = 0;
    merchantScore += norm[2] * 2.0; // バイト回数 (多い)
    merchantScore += norm[4] * 1.5; // 空きコマ多い (効率・自由時間)
    merchantScore += (norm[11] == 4.0 ? 1.5 : 0); // 興味関心(C:実用的)
    merchantScore += norm[8] * 1.2; // 忙しさをうまくこなす (自己評価の忙しさ)
    merchantScore += (norm[12] == 3.5 ? 1.5 : 0); // 困難への対処(C:相談協力)
    merchantScore += (norm[10] == 3.5 ? 1.0 : 0); // 計画と実行(B:大まか計画) - 要領

    // ゴリラ: 体育会系、努力と根性、朝型
    double gorillaScore = 0;
    gorillaScore += norm[1] * 2.0; // 1限コマ数 (朝型最重要)
    gorillaScore += norm[6] * 1.8; // ストレス耐性 (鋼メンタル)
    gorillaScore += norm[7] * 1.5; // モチベーション (頑張る)
    gorillaScore += norm[3] * 1.2; // サークル参加 (体育会系活動)
    gorillaScore +=
        (norm[13] == 5.0 && rawAnswers[13] == 0 ? 2.0 : 0); // 活動時間帯(A:早朝午前)
    gorillaScore += norm[0] * 1.0; // 履修コマ数 (頑張って詰める)
    gorillaScore += (norm[12] == 4.5 ? 1.5 : 0); // 困難への対処(A:根性)
    gorillaScore += norm[5] * 1.0; // 集中力 (脳筋で集中)

    // 冒険家: 好奇心、行動力、自由、挑戦
    double adventurerScore = 0;
    adventurerScore += (norm[9] == 5.0 ? 2.5 : 0); // 未知への体験(C:ワクワク)
    adventurerScore +=
        (norm[10] == 4.5 && rawAnswers[10] == 2 ? 2.0 : 0); // 計画と実行(C:即行動)
    adventurerScore +=
        (norm[11] == 4.5 && rawAnswers[11] == 1 ? 1.5 : 0); // 興味関心(B:広く浅く)
    adventurerScore += norm[4] * 1.0; // 空きコマ (自由を好む)
    adventurerScore +=
        _normalizeInverse(10, rawAnswers[10]) * 1.0; // 計画に縛られない (A:完璧計画の逆スコア)
    // Q13 活動時間帯(E:不定) も冒険家っぽいかも rawAnswers[13] == 4
    if (rawAnswers[13] == 4) adventurerScore += 1.0; // 活動時間帯が不定なら少しプラス

    // カス大学生 (レアキャラ候補でもあるが、通常スコアも算出)
    // このスコアが高い場合は、レアキャラ判定でさらに強調される
    double loserScore = 0;
    loserScore += _normalizeInverse(0, rawAnswers[0]) * 1.5; // 履修コマ少ない
    loserScore += _normalizeInverse(1, rawAnswers[1]) * 1.0; // 1限少ない
    loserScore += norm[4] * 1.8; // 空きコマ多い (最重要)
    loserScore += _normalizeInverse(5, rawAnswers[5]) * 1.5; // 集中力低い
    loserScore += _normalizeInverse(6, rawAnswers[6]) * 1.2; // ストレス耐性低い
    loserScore += (norm[10] == 1.0 ? 2.0 : 0); // 計画と実行(D:他者依存/ノープラン)
    loserScore += _normalizeInverse(7, rawAnswers[7]) * 1.8; // モチベーション低い (最重要)
    loserScore += _normalizeInverse(14, rawAnswers[14]) * 2.5; // 代筆多い (超重要)
    // Q12 困難への対処(D:回避諦め) rawAnswers[12] == 3
    if (rawAnswers[12] == 3) loserScore += 1.5;

    // --- レアキャラ判定 ---
    // 神: 多数の項目で非常に高いスコア
    double godScore = 0;
    // ポジティブな影響を与える主要な質問で高得点を集計
    godScore += norm[0]; // 履修コマ
    godScore += norm[1]; // 1限
    godScore += norm[3]; // サークル
    godScore += norm[5]; // 集中力
    godScore += norm[6]; // ストレス耐性
    godScore += norm[7]; // モチベーション
    // 計画性(Q10の選択肢A「完璧計画」) norm[10]が5.0点の場合
    if (rawAnswers[10] == 0) godScore += norm[10];
    // 困難への対処(Q12の選択肢B「分析計画」) norm[12]が4.0点の場合
    if (rawAnswers[12] == 1) godScore += norm[12];

    // 神の判定閾値 (8項目で平均4.0点以上 = 32.0点。最大40点)
    // これはかなり厳しい基準。実際のデータ分布を見て調整が必要。
    if (godScore >= 30.0 && norm[14] >= 4.0) {
      // 代筆しない/できないも条件に加える
      return "神";
    }

    // カス大学生（レアキャラとしての判定）
    // loserScore が既に計算されているので、それをベースに閾値判定
    // loserScore は最大で 約 (5*1.5 + 5*1.0 + 5*1.8 + 5*1.5 + 5*1.2 + 5*2.0 + 5*1.8 + 5*2.5 + 1.5*5) = 7.5+5+9+7.5+6+10+9+12.5+7.5 = 74点満点くらい
    // このスコアは他のキャラクタースコアと比較するものではなく、カス大学生としての度合い
    // 代筆のスコアが低い(norm[14]が低い＝代筆多い)ことが重要
    bool isDefinitelyLoserByDaipitsu = norm[14] <= 1.5; // 代筆2回以上はかなり黒い
    // カス大学生のレアキャラ判定基準 (例: loserScoreの合計が一定以上、かつ代筆が多いなど)
    // loserScoreは各項目が最大5点として計算されているので、最大40点くらい。
    // 例: 7項目で平均3.5点以上 = 24.5点
    // loserScore (各項目最大5点換算で計算しなおす)
    double reCalclulatedLoserScore =
        _normalizeInverse(0, rawAnswers[0]) +
        _normalizeInverse(1, rawAnswers[1]) +
        norm[4] + // 空きコマはそのまま高い
        _normalizeInverse(5, rawAnswers[5]) +
        _normalizeInverse(6, rawAnswers[6]) +
        (rawAnswers[10] == 3 ? 5.0 : 1.0) + // 他者依存/ノープランなら5点
        _normalizeInverse(7, rawAnswers[7]) +
        _normalizeInverse(14, rawAnswers[14]) + // 代筆多いほど高スコア(5点満点)
        (rawAnswers[12] == 3 ? 5.0 : 1.0); // 困難回避なら5点
    // 9項目、最大45点。平均3.5点なら31.5点。平均4点なら36点。
    if (reCalclulatedLoserScore >= 32.0 ||
        (isDefinitelyLoserByDaipitsu && reCalclulatedLoserScore >= 28.0)) {
      return "カス大学生";
    }

    // --- 通常キャラの判定 (最もスコアが高いキャラ) ---
    Map<String, double> scores = {
      "剣士": knightScore,
      "魔女": witchScore,
      "商人": merchantScore,
      "ゴリラ": gorillaScore,
      "冒険家": adventurerScore,
      // "カス大学生": loserScore, // カス大学生はレア判定が主。もし通常判定にも入れるならここに追加
    };

    // デバッグ用に各キャラのスコアを出力
    // print(scores);

    String finalCharacter = "剣士"; // デフォルト
    double maxScore = -double.infinity;

    scores.forEach((character, score) {
      if (score > maxScore) {
        maxScore = score;
        finalCharacter = character;
      }
    });

    // 同点だった場合の優先順位処理 (現状はMapの順番依存だが、明示的にできる)
    // 例: もし剣士と冒険家が同点なら剣士を優先したい、など。
    // ここでは最も単純な最大値選択。

    return finalCharacter;
  }

  @override
  Widget build(BuildContext context) {
    String characterName = _diagnoseCharacter(answers);

    Map<String, dynamic> characterData = {
      "剣士": {
        "image": 'assets/character_swordman.png',
        "name": "剣士",
        "personality":
            "文武両道でバランス感覚に優れ、計画的に物事を進める努力家。リーダーシップも兼ね備え、学業もサークルも手を抜かない優等生タイプ。",
        "skills": ["GPAマスタリー", "タイムマネジメント術", "グループリーダーシップ"],
        "items": ["成績優秀者の証", "多機能スケジュール帳", "折れない心"],
      },
      "魔女": {
        "image": 'assets/character_wizard.png',
        "name": "魔女",
        "personality":
            "強い探求心と知的好奇心を持ち、特定の分野を深く掘り下げて研究するタイプ。夜型でマイペース。独自の価値観と世界観を持つ孤高の探求者。",
        "skills": ["ディープリサーチ", "集中詠唱", "叡智の探求"],
        "items": ["古の魔導書", "深夜のコーヒー", "静寂のマント"],
      },
      "商人": {
        "image": 'assets/character_merchant.png',
        "name": "商人",
        "personality":
            "コミュニケーション能力が高く、要領が良い実利主義者。情報収集と人脈形成に長け、常にコスパと効率を重視。バイト経験も豊富で世渡り上手。",
        "skills": ["情報収集ネットワーク", "交渉の極意", "バイト時給アップ術"],
        "items": ["お得情報メモ", "多機能スマートフォン", "黄金の計算機"],
      },
      "ゴリラ": {
        "image": 'assets/character_gorilla.png',
        "name": "ゴリラ",
        "personality":
            "エネルギッシュな体育会系。朝型で、気合と根性と持ち前の体力で困難を乗り越える。考えるより行動が先。仲間思いで頼れる兄貴・姉御肌。",
        "skills": ["フィジカルMAX", "気合注入シャウト", "1限皆勤"],
        "items": ["プロテインシェイカー", "大量のバナナ", "汗と涙のジャージ"],
      },
      "冒険家": {
        "image": 'assets/character_adventurer.png', // 画像パスは適宜用意してください
        "name": "冒険家",
        "personality":
            "好奇心旺盛でフットワークが軽い自由人。未知の体験や新しい出会いを求め、計画に縛られず直感と柔軟性で行動する。リスクを恐れず挑戦し、変化を楽しむ。",
        "skills": ["ワールドウォーク", "即興サバイバル術", "未知との遭遇"],
        "items": ["使い古したバックパック", "方位磁石（たまに狂う）", "冒険日誌"],
      },
      "神": {
        "image": 'assets/character_god.png',
        "name": "神",
        "personality":
            "学業、活動、人間関係、全てにおいて高水準で完璧。欠点が見当たらず、周囲を圧倒するカリスマ性を持つ。まさに生きる伝説。",
        "skills": ["全知全能", "パーフェクトオールラウンド", "オーラ"],
        "items": ["光り輝く学生証", "未来予知ノート", "後光"],
      },
      "カス大学生": {
        "image": 'assets/character_takuji.png', // 画像パスは適宜用意してください
        "name": "カス大学生",
        "personality":
            "学業や活動へのモチベーションが著しく低く、計画性もない。日々を惰性で過ごし、楽な方へ流されがち。ギリギリの状況をなぜか生き抜く。",
        "skills": ["奇跡の単位取得", "遅刻ギリギリ回避術", "再履修の誓い"],
        "items": ["謎のシミがついたレジュメ", "エナジードリンクの空き缶", "鳴らない目覚まし時計"],
      },
      "エラー：回答数が不足しています": {
        // エラー表示用
        "image": 'assets/character_unknown.png', // エラー用画像
        "name": "診断エラー",
        "personality": "回答データに問題がありました。もう一度診断を試してみてください。",
        "skills": ["再診断"],
        "items": ["？"],
      },
    };

    final displayCharacterData =
        characterData[characterName] ?? characterData["剣士"]!; // フォールバック

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('診断結果'),
        backgroundColor: Colors.brown,
        automaticallyImplyLeading: false, // 戻るボタンを非表示にする場合
      ),
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
            padding: const EdgeInsets.all(16),
            child: Center(
              // 全体を中央寄せに
              child: ConstrainedBox(
                // 最大幅を設定
                constraints: BoxConstraints(maxWidth: 600), // スマホ～タブレットで見やすい幅
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      characterName == "エラー：回答数が不足しています"
                          ? "おっと！"
                          : "🎓 あなたの履修タイプは…！",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (displayCharacterData["image"] != null)
                      CircleAvatar(
                        radius: 100, // 少し小さく
                        backgroundImage: AssetImage(
                          displayCharacterData["image"],
                        ),
                        backgroundColor: Colors.brown[100],
                      ),
                    const SizedBox(height: 20),
                    Text(
                      displayCharacterData["name"] ?? characterName,
                      style: TextStyle(
                        fontSize: 28, // キャラ名を大きく
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch, // テキストを左寄せに
                          children: [
                            _buildCharacteristicRow(
                              Icons.psychology_alt,
                              "性格",
                              displayCharacterData["personality"] ?? "---",
                            ),
                            Divider(),
                            _buildCharacteristicRow(
                              Icons.star_outline,
                              "スキル",
                              (displayCharacterData["skills"] as List<dynamic>?)
                                      ?.join(", ") ??
                                  "---",
                            ),
                            Divider(),
                            _buildCharacteristicRow(
                              Icons.backpack_outlined,
                              "持ち物",
                              (displayCharacterData["items"] as List<dynamic>?)
                                      ?.join(", ") ??
                                  "---",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // 質問画面に戻る (スタックの最上部をpop)
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            "再診断する",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ParkPage(), // ParkPageに遷移
                                settings: RouteSettings(
                                  // ParkPageにキャラクター情報を渡す
                                  arguments: {
                                    'characterName': characterName,
                                    'characterImage':
                                        displayCharacterData["image"],
                                  },
                                ),
                              ),
                              (Route<dynamic> route) => false, // スタックを全て削除
                            );
                          },
                          icon: const Icon(
                            Icons.explore_outlined,
                            color: Colors.white,
                          ), // アイコン変更
                          label: const Text(
                            "広場へ行く",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600], // 色変更
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 結果表示用のヘルパーウィジェット
  Widget _buildCharacteristicRow(IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.brown[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(fontSize: 15, color: Colors.brown[900]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
