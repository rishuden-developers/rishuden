// credit_explore_page.dart
import 'package:flutter/material.dart';
import 'credit_result_page.dart'; // 検索結果を表示するページ
import 'credit_review_page.dart'; // レビュー投稿ページへの遷移用 (選択後)
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット (パスを確認してください)
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
  final List<String> _tagSuggestions = [
    '楽単',
    'テストなし',
    '出席ゆるい',
    'レポートのみ',
    'オンライン完結',
    'グループワーク',
  ];
  String? _selectedTag;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CreditResultPage(
              searchQuery:
                  _searchController.text.isEmpty
                      ? null
                      : _searchController.text,
              filterFaculty: _selectedFaculty,
              filterTag: _selectedTag, // タグフィルターも渡す
              // 曜日や必修/選択も必要であればここに含めます
            ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orangeAccent[100]!, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.brown),
              hint: Text(
                '全ての$label',
                style: const TextStyle(color: Colors.grey),
              ),
              onChanged: onChanged,
              items:
                  items.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxContentWidth = 600.0;
    final double bottomNavBarHeight = 75.0; // CommonBottomNavigationの高さに合わせて調整

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text('講義を探索する'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          fontFamily: 'NotoSansJP',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBar: CommonBottomNavigation(context: context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ranking_guild_background.png'), // 背景画像
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: bottomNavBarHeight + 20,
                  top: AppBar().preferredSize.height + 20,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '講義を検索',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansJP',
                        shadows: [
                          Shadow(
                            blurRadius: 6.0,
                            color: Colors.black54,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // 検索バー
                    TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '講義名や教員名で検索',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.brown,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orangeAccent[100]!,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orangeAccent[100]!,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.brown,
                            width: 2.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      style: const TextStyle(color: Colors.black87),
                      onFieldSubmitted: (_) => _performSearch(), // エンターキーで検索実行
                    ),
                    const SizedBox(height: 30),

                    // フィルターオプション
                    _buildDropdownFilter(
                      label: '学部・学科',
                      items: _faculties,
                      selectedValue: _selectedFaculty,
                      onChanged: (value) {
                        setState(() {
                          _selectedFaculty = value;
                        });
                      },
                    ),
                    _buildDropdownFilter(
                      label: '必修／選択',
                      items: _categories,
                      selectedValue: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    _buildDropdownFilter(
                      label: '曜日',
                      items: _daysOfWeek,
                      selectedValue: _selectedDayOfWeek,
                      onChanged: (value) {
                        setState(() {
                          _selectedDayOfWeek = value;
                        });
                      },
                    ),
                    // タグフィルター (Chip形式)
                    const Text(
                      'タグで絞り込み',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children:
                          _tagSuggestions.map((tag) {
                            final isSelected = _selectedTag == tag;
                            return FilterChip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.brown[700],
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTag = selected ? tag : null;
                                });
                              },
                              backgroundColor: Colors.white.withOpacity(0.9),
                              selectedColor: Colors.brown[700]?.withOpacity(
                                0.9,
                              ),
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Colors.orangeAccent[100]!,
                                  width: 1.0,
                                ),
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 30),

                    // 検索実行ボタン
                    ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.amberAccent[100]!,
                            width: 2,
                          ),
                        ),
                        elevation: 6,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansJP',
                        ),
                      ),
                      child: const Text('講義を検索'),
                    ),
                    const SizedBox(height: 40),

                    // ランキングへの導線
                    const Text(
                      'ランキングを見る',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansJP',
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black45,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildRankingButton(context, '楽単ランキング', 'easiness'),
                    _buildRankingButton(context, '人気講義TOP10', 'satisfaction'),
                    _buildRankingButton(context, '沼単ランキング', 'nume'),
                    _buildRankingButton(context, '学部別注目授業', 'faculty_specific'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingButton(
    BuildContext context,
    String label,
    String rankingType,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreditResultPage(
                    rankingType: rankingType,
                    filterFaculty:
                        rankingType == 'faculty_specific'
                            ? _selectedFaculty
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
