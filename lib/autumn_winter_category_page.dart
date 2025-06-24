import 'package:flutter/material.dart';
import 'autumn_winter_course_list_page.dart';

class AutumnWinterCategoryPage extends StatelessWidget {
  const AutumnWinterCategoryPage({super.key});

  // 秋冬学期のカテゴリーリスト
  final List<String> categories = const [
    '基盤教養教育科目',
    '英語',
    '中国語',
    'ドイツ語',
    'フランス語',
    '数学',
    '物理学',
    '化学',
    '地球科学',
    '統計学',
    '図学',
    '健康・スポーツ',
    '高度教養科目',
    '高度セミナー科目',
    'その他外国語',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('後期履修準備'),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _CategoryCard(
              category: categories[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AutumnWinterCourseListPage(
                          category: categories[index],
                        ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.indigo[200]!, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.indigo[50]!],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 48,
                  color: Colors.indigo[700],
                ),
                const SizedBox(height: 12),
                Text(
                  category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'NotoSansJP',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  '秋冬学期',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'NotoSansJP',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '基盤教養教育科目':
        return Icons.school;
      case '英語':
      case '中国語':
      case 'ドイツ語':
      case 'フランス語':
      case 'その他外国語':
        return Icons.language;
      case '数学':
        return Icons.functions;
      case '物理学':
        return Icons.science;
      case '化学':
        return Icons.science_outlined;
      case '地球科学':
        return Icons.public;
      case '統計学':
        return Icons.analytics;
      case '図学':
        return Icons.draw;
      case '健康・スポーツ':
        return Icons.sports_soccer;
      case '高度教養科目':
        return Icons.psychology;
      case '高度セミナー科目':
        return Icons.groups;
      default:
        return Icons.menu_book;
    }
  }
}
