// 例: character_provider.dart
import 'package:flutter/material.dart';

class CharacterProvider with ChangeNotifier {
  String _characterName = 'キャラクター';
  String _characterImage = 'assets/character_unknown.png';

  String get characterName => _characterName;
  String get characterImage => _characterImage;

  void setCharacter(String name, String imagePath) {
    _characterName = name;
    _characterImage = imagePath;
    notifyListeners(); // 変更を通知
  }
}
