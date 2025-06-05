// lib/character_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ★ Firebase Auth を利用する場合

class CharacterProvider with ChangeNotifier {
  String _characterName = 'キャラクター';
  String _characterImage = 'assets/character_unknown.png';
  String? _userId; // ★★★ ユーザーIDを保持するフィールドを追加 (null許容) ★★★

  String get characterName => _characterName;
  String get characterImage => _characterImage;
  String? get userId => _userId; // ★★★ userId のゲッターを追加 ★★★

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
}
