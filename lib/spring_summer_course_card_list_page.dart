import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'components/course_card.dart';
import 'providers/timetable_provider.dart';
import 'common_bottom_navigation.dart';
import 'credit_input_page.dart' show tagOptions;

class SpringSummerCourseCardListPage extends ConsumerStatefulWidget {
  const SpringSummerCourseCardListPage({super.key});

  @override
  ConsumerState<SpringSummerCourseCardListPage> createState() =>
      _SpringSummerCourseCardListPageState();
}

class _SpringSummerCourseCardListPageState
    extends ConsumerState<SpringSummerCourseCardListPage> {
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  String? _selectedFaculty;
  String? _selectedTag;

  final List<String> _faculties = [
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
  final List<String> _tags = tagOptions;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('global')
              .doc('course_mapping')
              .get();

      final mapping = (doc.data()?['mapping'] as Map<String, dynamic>? ?? {});
      final user = FirebaseAuth.instance.currentUser;
      final List<Map<String, dynamic>> courses = [];

      for (final e in mapping.entries) {
        final courseId = e.key;
        final parts = courseId.split('|');
        final lectureName = parts.isNotEmpty ? parts[0] : courseId;
        final classroom = parts.length > 1 ? parts[1] : '';
        var teacherName = '';
        if (e.value is Map<String, dynamic>) {
          teacherName = e.value['teacherName'] ?? e.value['instructor'] ?? '';
        }
        final timetableTeacherName =
            ref.read(timetableProvider)['teacherNames']?[courseId];
        if (timetableTeacherName != null && timetableTeacherName.isNotEmpty) {
          teacherName = timetableTeacherName;
        }

        // 各授業のレビュー統計
        final reviewsSnap =
            await FirebaseFirestore.instance
                .collection('reviews')
                .where('courseId', isEqualTo: courseId)
                .get();
        double sat = 0, ease = 0;
        bool my = false;
        for (final r in reviewsSnap.docs) {
          final d = r.data();
          sat +=
              (d['overallSatisfaction'] ?? d['satisfaction'] ?? 0).toDouble();
          ease += (d['easiness'] ?? d['ease'] ?? 0).toDouble();
          if (user != null && d['userId'] == user.uid) my = true;
        }

        courses.add({
          'courseId': courseId,
          'lectureName': lectureName,
          'classroom': classroom,
          'teacherName': teacherName,
          'avgSatisfaction':
              reviewsSnap.docs.isEmpty ? 0 : sat / reviewsSnap.docs.length,
          'avgEasiness':
              reviewsSnap.docs.isEmpty ? 0 : ease / reviewsSnap.docs.length,
          'reviewCount': reviewsSnap.docs.length,
          'hasMyReview': my,
        });
      }

      setState(() {
        _allCourses = courses;
        _filtered = courses;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    List<Map<String, dynamic>> f = _allCourses;
    final query = _searchCtrl.text.toLowerCase();
    if (query.isNotEmpty) {
      f =
          f
              .where(
                (c) =>
                    (c['lectureName'] ?? '').toString().toLowerCase().contains(
                      query,
                    ) ||
                    (c['teacherName'] ?? '').toString().toLowerCase().contains(
                      query,
                    ),
              )
              .toList();
    }
    if (_selectedFaculty != null && _selectedFaculty!.isNotEmpty) {
      // ここに学部フィルタを加えたい場合は既存のFirestoreクエリを呼び出してください
    }
    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      // タグフィルタも同様
    }
    setState(() => _filtered = f);
  }

  @override
  Widget build(BuildContext context) {
    const mainBlue = Color(0xFF2E6DB6);
    final bg = Colors.grey[100];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('春夏学期の授業一覧'),
        backgroundColor: mainBlue,
        centerTitle: true,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadCourses,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (_) => _applyFilter(),
                    ),
                    const SizedBox(height: 12),
                    ..._filtered
                        .map((c) => _CourseTileSimple(course: c))
                        .toList(),
                    if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('該当する授業がありません')),
                      ),
                  ],
                ),
              ),
      bottomNavigationBar: const CommonBottomNavigation(),
    );
  }
}

// ------- 検索バー -------
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '講義名や教員名で検索...',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              controller.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                  : null,
        ),
      ),
    );
  }
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return 0.0;
}

// ------- シンプル授業カード -------
class _CourseTileSimple extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseTileSimple({required this.course});

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF2E6DB6);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course['lectureName'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (course['hasMyReview'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '投稿済み',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            course['teacherName'] ?? '担当未設定',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric(
                Icons.star,
                Colors.amber,
                _asDouble(course['avgSatisfaction']).toStringAsFixed(1),
                '満足度',
              ),
              _metric(
                Icons.sentiment_satisfied,
                Colors.teal,
                _asDouble(course['avgEasiness']).toStringAsFixed(1),
                '楽単度',
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.comment, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(
                    '${course['reviewCount']}件',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.chevron_right_rounded, color: blue),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, Color color, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
