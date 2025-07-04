// credit_explore_page.dart
import 'package:flutter/material.dart';
import 'current_semester_reviews_page.dart';
import 'autumn_winter_category_page.dart';
import 'my_reviews_page.dart';
import 'credit_result_page.dart';
import 'autumn_winter_course_card_list_page.dart';
import 'spring_summer_course_card_list_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/background_image_provider.dart';

class CreditExplorePage extends ConsumerWidget {
  const CreditExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            ref.watch(backgroundImagePathProvider),
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
        SafeArea(
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
                _buildMyReviewButton(context),

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
      ],
    );
  }

  Widget _buildMyReviewButton(BuildContext context) {
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
