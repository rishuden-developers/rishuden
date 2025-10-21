import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ↓あなたの既存のページ遷移先を適宜差し替えてください
import 'spring_summer_course_card_list_page.dart';
import 'search_credits_page/autumn_winter_course_card_list_page.dart';
import 'current_semester_reviews_page.dart';

class CreditExplorePage extends ConsumerWidget {
  const CreditExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainBlue = const Color(0xFF2E6DB6);
    final lightBlue = const Color(0xFF62B5E5);
    final greenBlue = const Color(0xFF58C3A9);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('単位探索'),
        centerTitle: true,
        backgroundColor: mainBlue,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MainButton(
                text: '今の履修を確認',
                color: mainBlue,
                icon: Icons.check_box,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpringSummerCourseCardListPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _MainButton(
                text: '後期の履修準備',
                color: greenBlue,
                icon: Icons.school,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AutumnWinterCourseCardListPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _MainButton(
                text: 'レビューを書く',
                color: lightBlue,
                icon: Icons.edit,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CurrentSemesterReviewsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // --- 使い方 折りたたみ ---
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                title: const Text(
                  '使い方',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      '・講義名や教員名で検索できます\n'
                      '・「今の履修を確認」で春夏学期のレビュー確認・投稿\n'
                      '・「後期の履修準備」で秋冬学期の授業を探せます\n'
                      '・「レビューを書く」で自分のレビュー管理',
                      style: TextStyle(height: 1.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//-------------------------------------------------------------

class _MainButton extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _MainButton({
    required this.text,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 26),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
