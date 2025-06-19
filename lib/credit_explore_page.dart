// credit_explore_page.dart
import 'package:flutter/material.dart';
import 'credit_result_page.dart'; // 検索結果を表示するページ
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';

class CreditExplorePage extends StatefulWidget {
  const CreditExplorePage({super.key});

  @override
  State<CreditExplorePage> createState() => _CreditExplorePageState();
}

class _CreditExplorePageState extends State<CreditExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFaculty;
  String? _selectedCategory; // 必修/選択
  String? _selectedDayOfWeek;
  String? _selectedTag; // タグ検索用

  final List<String> _faculties = [
    '情報科学部',
    '経済学部',
    '理学部',
    '文学部',
    '工学部',
    '総合科学部',
    '法学部',
  ];
  final List<String> _categories = ['必修', '選択', 'その他'];
  final List<String> _daysOfWeek = ['月', '火', '水', '木', '金', '土', '日'];
  // ★タグ検索候補 (ダミー)
  final List<String> _tags = [
    'レポート多め',
    'グループワークあり',
    'テストなし',
    '出席必須',
    'オンライン完結',
    'ディスカッション多め',
    '課題なし',
    '板書メイン',
  ];

  void _performSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditResultPage(
          searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
          filterFaculty: _selectedFaculty,
          filterTag: _selectedTag,
          filterCategory: _selectedCategory,
          filterDayOfWeek: _selectedDayOfWeek,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '講義を探す',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansJP',
          ),
        ),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo[800]!,
              Colors.indigo[600]!,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32, // Adjust for padding
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Googleのような検索バー
                      _buildSearchBar(),
                      const SizedBox(height: 20),

                      // 検索フィルターのドロップダウン
                      _buildFilterDropdown(
                        '学部で絞り込む',
                        _selectedFaculty,
                        _faculties,
                        (String? newValue) {
                          setState(() {
                            _selectedFaculty = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildFilterDropdown(
                        '種類で絞り込む (必修/選択)',
                        _selectedCategory,
                        _categories,
                        (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildFilterDropdown(
                        '曜日で絞り込む',
                        _selectedDayOfWeek,
                        _daysOfWeek,
                        (String? newValue) {
                          setState(() {
                            _selectedDayOfWeek = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildFilterDropdown(
                        'タグで絞り込む',
                        _selectedTag,
                        _tags,
                        (String? newValue) {
                          setState(() {
                            _selectedTag = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 30),

                      // 検索ボタン
                      ElevatedButton.icon(
                        onPressed: _performSearch,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: const Text(
                          '検索',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.blueAccent[100]!, width: 1.5),
                          ),
                          elevation: 4,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ランキング表示へのボタン (既存のものを維持)
                      _buildSectionTitle('人気ランキング', Icons.bar_chart),
                      const SizedBox(height: 10),
                      _buildRankingButton(context, '楽単ランキング', 'easiness'),
                      _buildRankingButton(context, '総合満足度ランキング', 'satisfaction'),
                      _buildRankingButton(context, '学部別注目授業', 'faculty_specific'),

                      const Spacer(), // 下部のナビゲーションバーのためのスペース
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigation(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '講義名や教員名で検索...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {}); // 更新してクリアボタンを非表示にする
                  },
                )
              : null,
        ),
        onChanged: (text) {
          setState(() {}); // 入力内容に応じてクリアボタンの表示/非表示を更新
        },
        onSubmitted: (text) => _performSearch(),
      ),
    );
  }

  Widget _buildFilterDropdown(
      String hintText, String? selectedValue, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedValue,
          hint: Text(hintText, style: TextStyle(color: Colors.grey[700])),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'NotoSansJP',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingButton(
      BuildContext context, String label, String rankingType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreditResultPage(
                rankingType: rankingType,
                filterFaculty: rankingType == 'faculty_specific'
                    ? _selectedFaculty // 学部別ランキングの場合は選択中の学部を渡す
                    : null,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blueAccent[100]!, width: 1.5),
          ),
          elevation: 4,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansJP',
          ),
        ),
        child: Text(label),
      ),
    );
  }
}