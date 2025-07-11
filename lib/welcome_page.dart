import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    filteredUniversities = UniversityList.allUniversities;
  }

  void _showUniversitySelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C3E50),
              title: const Text(
                '大学を選択してください',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // 検索ボックス
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '大学名を検索...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white70),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredUniversities =
                              UniversityList.searchUniversities(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // 大学リスト
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredUniversities.length,
                        itemBuilder: (context, index) {
                          final university = filteredUniversities[index];
                          return ListTile(
                            title: Text(
                              university,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _onSelectUniversity(context, university);
                            },
                            tileColor:
                                university == selectedUniversity
                                    ? Colors.blue.withOpacity(0.3)
                                    : null,
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
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onSelectUniversity(BuildContext context, String universityName) {
    setState(() {
      selectedUniversity = universityName;
    });

    // 大学タイプを判定
    String universityType =
        UniversityList.isOsakaUniversity(universityName) ? 'main' : 'other';

    if (universityType == 'main') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterPage(universityType: 'main'),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  OtherUnivRegisterPage(selectedUniversity: universityName),
        ),
      );
    }
  }

  void _showLoginSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C3E50),
              title: const Text(
                '大学を選択してください',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // 検索ボックス
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '大学名を検索...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white70),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredUniversities =
                              UniversityList.searchUniversities(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // 大学リスト
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredUniversities.length,
                        itemBuilder: (context, index) {
                          final university = filteredUniversities[index];
                          return ListTile(
                            title: Text(
                              university,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              // 大学タイプを判定
                              String universityType =
                                  UniversityList.isOsakaUniversity(university)
                                      ? 'main'
                                      : 'other';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => LoginPage(
                                        universityType: universityType,
                                      ),
                                ),
                              );
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
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アプリ名
            const Text(
              '履修伝説',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // サブタイトル
            const Text(
              'さあ、冒険を始めよう。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 60),
            // 大学選択ボタン
            ElevatedButton(
              onPressed: () => _showUniversitySelectionDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                selectedUniversity.isEmpty ? '大学を選択してください' : selectedUniversity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 選択された大学で登録ボタン
            if (selectedUniversity.isNotEmpty)
              ElevatedButton(
                onPressed:
                    () => _onSelectUniversity(context, selectedUniversity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'この大学で登録',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 40),
            // ログインリンク
            TextButton(
              onPressed: () {
                _showLoginSelectionDialog(context);
              },
              child: const Text(
                'すでにアカウントをお持ちの方はこちら (ログイン)',
                style: TextStyle(color: Colors.white70),
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
