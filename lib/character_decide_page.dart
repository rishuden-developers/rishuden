import 'package:flutter/material.dart';
import 'park_page.dart';
import 'character_data.dart'; // ParkPageのインポート
// import 'dart:math'; // 診断ロジックがないので不要

class CharacterDecidePage extends StatelessWidget {
  final List<int> answers;
  final String diagnosedCharacterName;

  const CharacterDecidePage({
    super.key,
    required this.answers,
    required this.diagnosedCharacterName,
  });

  // キャラクターの全データ定義
  final Map<String, dynamic> _characterFullData = const {
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
      "image": 'assets/character_adventurer.png',
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
      "image": 'assets/character_takuji.png',
      "name": "カス大学生",
      "personality":
          "学業や活動へのモチベーションが著しく低く、計画性もない。日々を惰性で過ごし、楽な方へ流されがち。ギリギリの状況をなぜか生き抜く。",
      "skills": ["奇跡の単位取得", "遅刻ギリギリ回避術", "再履修の誓い"],
      "items": ["謎のシミがついたレジュメ", "エナジードリンクの空き缶", "鳴らない目覚まし時計"],
    },
    "エラー：回答数が不足しています": {
      "image": 'assets/character_unknown.png',
      "name": "診断エラー",
      "personality": "回答データに問題がありました。もう一度診断を試してみてください。",
      "skills": ["再診断"],
      "items": ["？"],
    },
  };

  @override
  Widget build(BuildContext context) {
    final String characterName = diagnosedCharacterName;
    // ★★★ characterFullDataGlobal を使用 ★★★
    final Map<String, dynamic> displayCharacterData =
        characterFullDataGlobal[characterName] ??
        characterFullDataGlobal["剣士"]!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        backgroundColor: Colors.brown,
        automaticallyImplyLeading: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SansJP',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/question_background_image.png', // QuestionPageと共通の背景画像
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      characterName == "エラー：回答数が不足しています"
                          ? "おっと！"
                          : "🎓 あなたの履修タイプは…！",
                      style: TextStyle(
                        fontFamily: 'SansJP',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (displayCharacterData["image"] != null)
                      CircleAvatar(
                        radius: 100,
                        backgroundImage: AssetImage(
                          displayCharacterData["image"],
                        ),
                        backgroundColor: Colors.brown[100],
                      ),
                    const SizedBox(height: 20),
                    Text(
                      displayCharacterData["name"] ?? characterName,
                      style: TextStyle(
                        fontFamily: 'SansJP',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      color: Colors.white.withOpacity(0.85),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCharacteristicRow(
                              Icons.psychology_alt,
                              "性格",
                              displayCharacterData["personality"] ?? "---",
                            ),
                            Divider(color: Colors.brown[200]),
                            _buildCharacteristicRow(
                              Icons.star_outline,
                              "スキル",
                              (displayCharacterData["skills"] as List<dynamic>?)
                                      ?.join(", ") ??
                                  "---",
                            ),
                            Divider(color: Colors.brown[200]),
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
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            "再診断する",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600]?.withOpacity(
                              0.9,
                            ),
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
                            if (context.mounted) {
                              Navigator.push(
                                // pushNamed から push に変更
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ParkPage(), // ParkPage を直接指定
                                  settings: RouteSettings(
                                    // 引数を RouteSettings で渡す
                                    arguments: {
                                      'characterName':
                                          characterName, // characterName は build メソッド内で定義されているもの
                                      'characterImage':
                                          displayCharacterData["image"], // displayCharacterData も同様
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.explore_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "広場へ行く",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600]?.withOpacity(
                              0.9,
                            ),
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

  Widget _buildCharacteristicRow(IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.brown[800], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SansJP', // カード内のテキストにもフォント指定する場合
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'SansJP',
                    fontSize: 15,
                    color: Colors.brown[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
