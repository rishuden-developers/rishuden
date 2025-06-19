import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'park_page.dart';
import 'character_data.dart'; // グローバルキャラクターデータをインポート
// import 'dart:math'; // 診断ロジックがないので不要

class CharacterDecidePage extends StatefulWidget {
  final List<int> answers;
  final String diagnosedCharacterName;

  const CharacterDecidePage({
    super.key,
    required this.answers,
    required this.diagnosedCharacterName,
  });

  @override
  State<CharacterDecidePage> createState() => _CharacterDecidePageState();
}

class _CharacterDecidePageState extends State<CharacterDecidePage> {
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCharacterToFirebase(
    BuildContext context,
    String characterName,
  ) async {
    print('=== _saveCharacterToFirebase started ===');
    print('Character Name: $characterName');
    print('User Name: ${_nameController.text}');
    print('Grade: $_selectedGrade');
    print('Department: $_selectedDepartment');

    // 入力チェック
    if (_nameController.text.isEmpty) {
      print('Error: Name is empty');
      setState(() {
        _error = '名前を入力してください';
      });
      return;
    }
    if (_selectedGrade == null) {
      print('Error: Grade is not selected');
      setState(() {
        _error = '学年を選択してください';
      });
      return;
    }
    if (_selectedDepartment == null) {
      print('Error: Department is not selected');
      setState(() {
        _error = '学部を選択してください';
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Current User: ${user?.uid}');

      if (user != null) {
        print('Saving data to Firebase...');
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'character': characterName,
          'characterSelected': true,
          'characterImage': characterFullDataGlobal[characterName]?['image'],
          'characterPersonality':
              characterFullDataGlobal[characterName]?['personality'],
          'characterSkills': characterFullDataGlobal[characterName]?['skills'],
          'characterItems': characterFullDataGlobal[characterName]?['items'],
          'name': _nameController.text,
          'grade': _selectedGrade,
          'department': _selectedDepartment,
        }, SetOptions(merge: true));
        print('Data saved successfully');

        if (context.mounted) {
          print('Navigating to ParkPage...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ParkPage(
                    diagnosedCharacterName: characterName,
                    answers: widget.answers,
                    userName: _nameController.text,
                    grade: _selectedGrade,
                    department: _selectedDepartment,
                  ),
            ),
          );
          print('Navigation completed');
        }
      } else {
        print('Error: User is not logged in');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
        }
      }
    } catch (e) {
      print('Error saving character: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    }
    print('=== _saveCharacterToFirebase completed ===');
  }

  @override
  Widget build(BuildContext context) {
    final String characterName = widget.diagnosedCharacterName;
    final Map<String, dynamic> displayCharacterData =
        characterFullDataGlobal[characterName] ??
        characterFullDataGlobal["剣士"]!;

    print('=== Character Data ===');
    print('Character Name: $characterName');
    print('Image Path: ${displayCharacterData["image"]}');
    print('Personality: ${displayCharacterData["personality"]}');
    print('Skills: ${displayCharacterData["skills"]}');
    print('Items: ${displayCharacterData["items"]}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        backgroundColor: Colors.brown,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'SansJP',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Stack(
        children: <Widget>[
          // 背景画像
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/question_background_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // メインコンテンツ
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // キャラクター画像
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.brown, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      displayCharacterData["image"],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // キャラクター名
                Text(
                  characterName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 10),
                // 性格
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    displayCharacterData["personality"],
                    style: const TextStyle(fontSize: 16, color: Colors.brown),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                // スキル
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    displayCharacterData["skills"],
                    style: const TextStyle(fontSize: 16, color: Colors.brown),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                // 持ち物
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    displayCharacterData["items"],
                    style: const TextStyle(fontSize: 16, color: Colors.brown),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                // ユーザー情報入力フォーム
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // 名前入力
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '名前',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 学年選択
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedGrade,
                          decoration: const InputDecoration(
                            labelText: '学年',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items:
                              _grades.map((String grade) {
                                return DropdownMenuItem<String>(
                                  value: grade,
                                  child: Text(grade),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGrade = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 学部選択
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedDepartment,
                          decoration: const InputDecoration(
                            labelText: '学部',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items:
                              _departments.map((String department) {
                                return DropdownMenuItem<String>(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDepartment = newValue;
                            });
                          },
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 決定ボタン
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('Button pressed');
                      _saveCharacterToFirebase(context, characterName);
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      "このキャラクターで決定",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
