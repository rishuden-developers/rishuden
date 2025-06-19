// lib/character_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ★ Firebase Auth を利用する場合

class CharacterProvider with ChangeNotifier {
  String _characterName = '勇者';
  String _characterImage = 'assets/character_swordman.png';
  String? _userId; // ★★★ ユーザーIDを保持するフィールドを追加 (null許容) ★★★

  // ★★★ 経験値とレベルのフィールドを追加 ★★★
  int _experience = 0;
  int _level = 1;

  String get characterName => _characterName;
  String get characterImage => _characterImage;
  String? get userId => _userId; // ★★★ userId のゲッターを追加 ★★★
  int get experience => _experience; // ★★★ 経験値のゲッターを追加 ★★★
  int get level => _level; // ★★★ レベルのゲッターを追加 ★★★


  CharacterProvider() {
    // ★★★ プロバイダ初期化時に現在のユーザーIDを取得する試み (例) ★★★
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      // notifyListeners(); // 必要であればリスナーに通知
    }
  }

  void setCharacter(String name, String imagePath) {
    _characterName = name;
    _characterImage = imagePath;
    notifyListeners();
  }

  // ★★★ ユーザーIDを設定/更新するためのメソッド (オプション) ★★★
  // ログイン状態の変化に応じて呼び出すなど
  void setUserId(String? newUserId) {
    _userId = newUserId;
    notifyListeners(); // ユーザーIDの変更も通知する場合
  }

  // ★★★ 経験値を追加するメソッドを追加 ★★★
  void addExperience(int amount) {
    _experience += amount;
    int expForNextLevel = _getExperienceForNextLevel(_level);

    // レベルアップ判定
    while (_experience >= expForNextLevel) {
      _experience -= expForNextLevel; // 次のレベルへの余剰経験値を残す
      _level++;
      _handleLevelUp(); // レベルアップ時の処理
      expForNextLevel = _getExperienceForNextLevel(_level); // 次のレベルの必要経験値を再計算
    }
    notifyListeners(); // 経験値またはレベルが変更されたことを通知
  }

  // ★★★ 次のレベルアップに必要な経験値を計算するヘルパーメソッド (例) ★★★
  int _getExperienceForNextLevel(int currentLevel) {
    // シンプルな計算式：レベルが上がるほど必要な経験値が増える
    return 100 + (currentLevel - 1) * 50;
  }

  // ★★★ レベルアップ時のキャラクター変更ロジック (ダミー) ★★★
  void _handleLevelUp() {
    // レベルに応じてキャラクターの画像や名前を変更する例
    // 実際のアプリケーションでは、ここにデータベースからのデータ取得や、
    // より複雑なロジックを実装します。
    if (_level == 2) {
      _characterName = '見習い剣士';
      _characterImage = 'assets/character_apprentice.png'; // 仮の画像パス
    } else if (_level == 3) {
      _characterName = '熟練剣士';
      _characterImage = 'assets/character_master.png'; // 仮の画像パス
    } else if (_level == 5) {
      _characterName = '勇者 (覚醒)';
      _characterImage = 'assets/character_hero_awakened.png'; // 仮の画像パス
    }
    // 必要に応じて、レベルアップ時のエフェクト表示やメッセージ表示などもここで行えます。
    print('キャラクターがレベル ${_level} にアップしました！');
  }
}