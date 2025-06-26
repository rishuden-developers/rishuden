// credit_explore_page.dart
import 'package:flutter/material.dart';
import 'current_semester_reviews_page.dart';
import 'autumn_winter_category_page.dart';
import 'my_reviews_page.dart';
import 'credit_result_page.dart';
import 'autumn_winter_course_card_list_page.dart';
import 'spring_summer_course_card_list_page.dart';

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
        builder:
            (context) => CreditResultPage(
              searchQuery:
                  _searchController.text.isNotEmpty
                      ? _searchController.text
                      : null,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.indigo[800]!, Colors.indigo[600]!],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // タイトル
              const Text(
                '単位探索',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'NotoSansJP',
                ),
              ),
              const SizedBox(height: 30),

              // 検索バー
              _buildSearchBar(),
              const SizedBox(height: 20),

              // 検索フィルターのドロップダウン
              _buildFilterDropdown('学部で絞り込む', _selectedFaculty, _faculties, (
                String? newValue,
              ) {
                setState(() {
                  _selectedFaculty = newValue;
                });
              }),
              const SizedBox(height: 10),
              _buildFilterDropdown('タグで絞り込む', _selectedTag, _tags, (
                String? newValue,
              ) {
                setState(() {
                  _selectedTag = newValue;
                });
              }),
              const SizedBox(height: 20),

              // 検索ボタン
              _buildSearchButton(),
              const SizedBox(height: 30),

              // 横並びの2つのボタン
              SizedBox(
                height: 190, // ボタンの高さを明示的に制限
                child: Row(
                  children: [
                    // 左ボタン：今学期のレビュー確認
                    Expanded(
                      child: _buildMainButton(
                        title: '今の履修を\n確認！',
                        subtitle: '春夏学期',
                        icon: Icons.rate_review,
                        color: Colors.orange[700]!,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const SpringSummerCourseCardListPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),

                    // 右ボタン：後期の履修準備
                    Expanded(
                      child: _buildMainButton(
                        title: '後期の履修の\n準備をする！',
                        subtitle: '秋冬学期',
                        icon: Icons.school,
                        color: Colors.green[700]!,
                        isDisabled: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const AutumnWinterCourseCardListPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 自分のレビューを書くボタン（横長）
              _buildMyReviewButton(),

              const SizedBox(height: 30),

              // 説明文
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Column(
                  children: [
                    Text(
                      '使い方',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansJP',
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '上：講義名や教員名で検索できます\n左：今学期の履修授業のレビューを確認・投稿できます\n右：後期の履修準備として秋冬学期の授業を探せます\n下：自分のレビューを管理できます',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'NotoSansJP',
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            offset: const Offset(0, 3),
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
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                  : null,
        ),
        onChanged: (text) {
          setState(() {});
        },
        onSubmitted: (text) => _performSearch(),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String hintText,
    String? selectedValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
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
          items:
              items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text(
          'この条件で検索',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 21, 204, 255),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _performSearch,
      ),
    );
  }

  Widget _buildMyReviewButton() {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit, color: Colors.white, size: 28),
        label: const Text(
          '自分のレビューを書く',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'NotoSansJP',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          elevation: 8,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CurrentSemesterReviewsPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Container(
      height: 200,
      child: Card(
        elevation: 12.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isDisabled ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDisabled ? Colors.grey[200] : null,
              gradient:
                  isDisabled
                      ? null
                      : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withOpacity(0.8)],
                      ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(icon, size: 48, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'NotoSansJP',
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isDisabled)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 32,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '準備中',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontFamily: 'NotoSansJP',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
