import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'register_page.dart';
import 'login_page.dart';
import 'other_univ_register_page.dart';
import 'constants/university_list.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String selectedUniversity = '';
  List<String> filteredUniversities = [];
  final TextEditingController _searchController = TextEditingController();

  static const mainBlue = Color(0xFF2E6DB6);

  @override
  void initState() {
    super.initState();
    filteredUniversities = UniversityList.allUniversities;
  }

  void _showUniversitySelectionDialog(bool isLogin) {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                '大学を選択してください',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '大学名を検索...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: mainBlue, width: 2),
                        ),
                      ),
                      onChanged: (v) {
                        setStateDialog(() {
                          filteredUniversities =
                              UniversityList.searchUniversities(v);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredUniversities.length,
                        itemBuilder: (context, index) {
                          final univ = filteredUniversities[index];
                          return ListTile(
                            title: Text(univ),
                            tileColor:
                                univ == selectedUniversity
                                    ? mainBlue.withOpacity(0.1)
                                    : null,
                            onTap: () {
                              Navigator.pop(context);
                              _onSelect(univ, isLogin);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onSelect(String universityName, bool isLogin) {
    setState(() => selectedUniversity = universityName);
    final type =
        UniversityList.isOsakaUniversity(universityName) ? 'main' : 'other';
    if (isLogin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(universityType: type)),
      );
    } else {
      if (type == 'main') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RegisterPage(universityType: 'main'),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    OtherUnivRegisterPage(selectedUniversity: universityName),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mainBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text('履修伝説'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: [
            const SizedBox(height: 20),
            const Text(
              'さあ、冒険を始めよう。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 40),

            // 大学選択ボタン
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => _showUniversitySelectionDialog(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  selectedUniversity.isEmpty
                      ? '大学を選択してください'
                      : selectedUniversity,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (selectedUniversity.isNotEmpty)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _onSelect(selectedUniversity, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'この大学で登録',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // ログインリンク
            Center(
              child: TextButton(
                onPressed: () => _showUniversitySelectionDialog(true),
                child: const Text(
                  'すでにアカウントをお持ちの方はこちら（ログイン）',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 40), // ←ここで空白を減らしてアニメーションを追加
            // ↓ここから追加
            SizedBox(
              height: 180,
              child: Lottie.asset(
                'assets/animation.json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
