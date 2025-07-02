import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'park_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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
    '人間科学部',
    '外国語学部',
    '基礎工学部',
  ];

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty ||
        _selectedGrade == null ||
        _selectedDepartment == null) {
      setState(() {
        _error = 'すべての項目を入力してください';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'grade': _selectedGrade,
        'department': _selectedDepartment,
        'profileCompleted': true,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => const ParkPage(
                  diagnosedCharacterName: '剣士',
                  answers: [],
                  userName: '',
                ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'エラーが発生しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール設定'),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ユーザー名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGrade,
              decoration: const InputDecoration(
                labelText: '学年',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: const InputDecoration(
                labelText: '学部',
                border: OutlineInputBorder(),
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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('保存', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
