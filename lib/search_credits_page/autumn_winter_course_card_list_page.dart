import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/timetable_provider.dart';
import '../common_bottom_navigation.dart';
import 'autumn_winter_course_review_page.dart';
import '../credit_input_page.dart' show tagOptions;

class AutumnWinterCourseCardListPage extends ConsumerStatefulWidget {
  const AutumnWinterCourseCardListPage({super.key});

  @override
  ConsumerState<AutumnWinterCourseCardListPage> createState() =>
      _AutumnWinterCourseCardListPageState();
}

class _AutumnWinterCourseCardListPageState
    extends ConsumerState<AutumnWinterCourseCardListPage> {
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = true;

  String? _selectedFaculty;
  String? _selectedTag;

  final List<String> _faculties = const [
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
    _loadAllCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===== numerics helper =====
  double _asDouble(dynamic v) => v is num ? v.toDouble() : 0.0;

  Future<void> _loadAllCourses() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('course_data').get();

      final List<Map<String, dynamic>> all = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('data') &&
            data['data'] is Map &&
            (data['data'] as Map)['courses'] is List) {
          final List<dynamic> courseList = (data['data'] as Map)['courses'];
          for (final c in courseList) {
            if (c is Map<String, dynamic>) {
              final lectureName = c['lectureName'] ?? c['name'] ?? '';
              var teacherName =
                  c['teacherName'] ?? c['instructor'] ?? c['teacher'] ?? '';
              final classroom = c['classroom'] ?? c['room'] ?? '';
              final category = c['category'] ?? '';
              final semester = c['semester'] ?? '';

              if (lectureName.isNotEmpty) {
                final timetableTeacherName =
                    ref.read(timetableProvider)['teacherNames']?[lectureName];
                if (timetableTeacherName != null &&
                    timetableTeacherName.isNotEmpty) {
                  teacherName = timetableTeacherName;
                }
              }

              if (lectureName.isNotEmpty) {
                all.add({
                  'lectureName': lectureName,
                  'teacherName': teacherName,
                  'classroom': classroom,
                  'category': category,
                  'semester': semester,
                  'avgSatisfaction': 0.0,
                  'avgEasiness': 0.0,
                  'reviewCount': 0,
                  'hasMyReview': false,
                });
              }
            }
          }
        }
      }

      await _attachReviewStats(all);

      setState(() {
        _allCourses = all;
        _filteredCourses = all;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading autumn/winter courses: $e');
      setState(() => _isLoading = false);
    }
  }

  // 授業名×教員名でレビュー統計を付与
  Future<void> _attachReviewStats(List<Map<String, dynamic>> courses) async {
    final user = FirebaseAuth.instance.currentUser;

    for (int i = 0; i < courses.length; i++) {
      final lecture = courses[i]['lectureName'] as String? ?? '';
      final teacher = courses[i]['teacherName'] as String? ?? '';
      if (lecture.isEmpty || teacher.isEmpty) continue;

      try {
        final snap =
            await FirebaseFirestore.instance
                .collection('reviews')
                .where('lectureName', isEqualTo: lecture)
                .where('teacherName', isEqualTo: teacher)
                .get();

        if (snap.docs.isEmpty) continue;

        double sat = 0.0, ease = 0.0;
        bool mine = false;

        for (final d in snap.docs) {
          final m = d.data();
          final s = (m['overallSatisfaction'] ?? m['satisfaction'] ?? 0);
          final e = (m['easiness'] ?? m['ease'] ?? 0);
          sat += _asDouble(s);
          ease += _asDouble(e);
          if (user != null && m['userId'] == user.uid) mine = true;
        }

        courses[i] = {
          ...courses[i],
          'avgSatisfaction': sat / snap.docs.length,
          'avgEasiness': ease / snap.docs.length,
          'reviewCount': snap.docs.length,
          'hasMyReview': mine,
        };
      } catch (e) {
        debugPrint('Error fetching stats for $lecture / $teacher: $e');
      }
    }
  }

  // ===== filter/search =====
  Future<void> _applyFilters() async {
    List<Map<String, dynamic>> filtered = _allCourses;

    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered =
          filtered.where((c) {
            final l = (c['lectureName'] ?? '').toString().toLowerCase();
            final t = (c['teacherName'] ?? '').toString().toLowerCase();
            return l.contains(q) || t.contains(q);
          }).toList();
    }

    if (_selectedFaculty != null && _selectedFaculty!.isNotEmpty) {
      filtered = await _filterByFaculty(filtered, _selectedFaculty!);
    }
    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      filtered = await _filterByTag(filtered, _selectedTag!);
    }

    setState(() => _filteredCourses = filtered);
  }

  Future<List<Map<String, dynamic>>> _filterByFaculty(
    List<Map<String, dynamic>> courses,
    String faculty,
  ) async {
    try {
      final usersSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .where('department', isEqualTo: faculty)
              .get();
      final userIds = usersSnap.docs.map((d) => d.id).toList();
      if (userIds.isEmpty) return [];

      final reviewsSnap =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('userId', whereIn: userIds)
              .get();

      final pairs =
          reviewsSnap.docs.map((d) {
            final m = d.data();
            return {
              'lectureName': m['lectureName'] ?? '',
              'teacherName': m['teacherName'] ?? '',
            };
          }).toSet();

      return courses.where((c) {
        final l = c['lectureName'] ?? '';
        final t = c['teacherName'] ?? '';
        return pairs.any((p) => p['lectureName'] == l && p['teacherName'] == t);
      }).toList();
    } catch (e) {
      debugPrint('Error filtering by faculty: $e');
      return courses;
    }
  }

  Future<List<Map<String, dynamic>>> _filterByTag(
    List<Map<String, dynamic>> courses,
    String tag,
  ) async {
    try {
      final reviewsSnap =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('tags', arrayContains: tag)
              .get();

      final pairs =
          reviewsSnap.docs.map((d) {
            final m = d.data();
            return {
              'lectureName': m['lectureName'] ?? '',
              'teacherName': m['teacherName'] ?? '',
            };
          }).toSet();

      return courses.where((c) {
        final l = c['lectureName'] ?? '';
        final t = c['teacherName'] ?? '';
        return pairs.any((p) => p['lectureName'] == l && p['teacherName'] == t);
      }).toList();
    } catch (e) {
      debugPrint('Error filtering by tag: $e');
      return courses;
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainBlue = Color(0xFF2E6DB6);
    final bg = Colors.grey[100];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('秋冬学期の授業一覧'),
        centerTitle: true,
        backgroundColor: mainBlue,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadAllCourses,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _SearchAndFilterBar(
                      controller: _searchController,
                      faculties: _faculties,
                      tags: _tags,
                      selectedFaculty: _selectedFaculty,
                      selectedTag: _selectedTag,
                      onChanged: (q) => _applyFilters(),
                      onFacultyChanged: (v) {
                        setState(() => _selectedFaculty = v);
                        _applyFilters();
                      },
                      onTagChanged: (v) {
                        setState(() => _selectedTag = v);
                        _applyFilters();
                      },
                      onClear: () {
                        setState(() {
                          _searchController.clear();
                          _selectedFaculty = null;
                          _selectedTag = null;
                        });
                        _applyFilters();
                      },
                    ),
                    const SizedBox(height: 12),
                    ..._filteredCourses.map(
                      (c) => _CourseTileSimple(course: c, asDouble: _asDouble),
                    ),
                    if (_filteredCourses.isEmpty)
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

// ===== 検索＋フィルタ（シンプルUI） =====
class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final List<String> faculties;
  final List<String> tags;
  final String? selectedFaculty;
  final String? selectedTag;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String?> onFacultyChanged;
  final ValueChanged<String?> onTagChanged;

  const _SearchAndFilterBar({
    required this.controller,
    required this.faculties,
    required this.tags,
    required this.selectedFaculty,
    required this.selectedTag,
    required this.onChanged,
    required this.onClear,
    required this.onFacultyChanged,
    required this.onTagChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search
        Container(
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
                        onPressed: onClear,
                      )
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Filters
        Row(
          children: [
            Expanded(
              child: _DropdownPill(
                hint: '学部で絞り込む',
                value: selectedFaculty,
                items: faculties,
                onChanged: onFacultyChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DropdownPill(
                hint: 'タグで絞り込む',
                value: selectedTag,
                items: tags,
                onChanged: onTagChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DropdownPill extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownPill({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[700])),
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (val) => onChanged(val?.isEmpty == true ? null : val),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('選択解除')),
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
        ),
      ),
    );
  }
}

// ===== 授業カード（シンプル） =====
class _CourseTileSimple extends StatelessWidget {
  final Map<String, dynamic> course;
  final double Function(dynamic) asDouble;

  const _CourseTileSimple({required this.course, required this.asDouble});

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF2E6DB6);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => AutumnWinterCourseReviewPage(
                  lectureName: course['lectureName'] ?? '',
                  teacherName: course['teacherName'] ?? '',
                ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            // タイトル＋投稿済み
            Row(
              children: [
                Expanded(
                  child: Text(
                    course['lectureName'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (course['hasMyReview'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
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
            const SizedBox(height: 6),
            Text(
              (course['teacherName'] ?? '').toString().isNotEmpty
                  ? course['teacherName']
                  : '担当未設定',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // 指標
            Row(
              children: [
                _metric(
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  value: asDouble(course['avgSatisfaction']).toStringAsFixed(1),
                  label: '満足度',
                ),
                const SizedBox(width: 14),
                _metric(
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  color: Colors.teal,
                  value: asDouble(course['avgEasiness']).toStringAsFixed(1),
                  label: '楽単度',
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.comment_rounded,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${course['reviewCount'] ?? 0}件',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.chevron_right_rounded, color: blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
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
