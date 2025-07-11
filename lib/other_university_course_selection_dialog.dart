import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'timetable_entry.dart';

class OtherUniversityCourseSelectionDialog extends StatefulWidget {
  final String university;
  final String dayOfWeek;
  final int period;
  final VoidCallback onCourseSelected;
  final Function(int dayIndex, int period)? onAddNewCourse;

  const OtherUniversityCourseSelectionDialog({
    Key? key,
    required this.university,
    required this.dayOfWeek,
    required this.period,
    required this.onCourseSelected,
    this.onAddNewCourse,
  }) : super(key: key);

  @override
  State<OtherUniversityCourseSelectionDialog> createState() =>
      _OtherUniversityCourseSelectionDialogState();
}

class _OtherUniversityCourseSelectionDialogState
    extends State<OtherUniversityCourseSelectionDialog> {
  List<Map<String, dynamic>> _availableCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailableCourses();
  }

  Future<void> _loadAvailableCourses() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 分散協力型データベースから該当する授業を検索
      final snap =
          await FirebaseFirestore.instance.collection('globalCourses').get();

      List<Map<String, dynamic>> courses = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        // 該当する曜日・時限の授業のみをフィルタリング
        // 分散協力型データベースには曜日・時限情報がない場合があるため、
        // それらの情報がない授業も含める（ユーザーが選択後に設定可能）
        if (data['dayOfWeek'] == widget.dayOfWeek &&
            data['period'] == widget.period) {
          courses.add(data);
        } else if (data['dayOfWeek'] == null && data['period'] == null) {
          // 曜日・時限が設定されていない授業も含める
          courses.add(data);
        }
      }

      // 使用回数でソート（人気順）
      courses.sort(
        (a, b) => (b['usageCount'] ?? 0).compareTo(a['usageCount'] ?? 0),
      );

      setState(() {
        _availableCourses = courses;
        _filteredCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      print('授業データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCourses(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCourses = _availableCourses;
      } else {
        _filteredCourses =
            _availableCourses
                .where(
                  (course) =>
                      (course['subjectName'] ?? '').toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      (course['teacherName'] ?? '').toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      (course['faculty'] ?? '').toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
      }
    });
  }

  Future<void> _selectCourse(Map<String, dynamic> courseData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ユーザーがログインしていません')));
        return;
      }

      // 新しい授業エントリを作成
      final courseId = DateTime.now().millisecondsSinceEpoch.toString();
      final entry = TimetableEntry(
        id: courseId,
        subjectName: courseData['subjectName'] ?? '',
        classroom: courseData['classroom'] ?? '',
        originalLocation: courseData['teacherName'] ?? '',
        dayOfWeek: _getDayIndex(widget.dayOfWeek),
        period: widget.period,
        date: '',
        color: _getRandomColor(),
      );

      // 他大学の授業データとして保存
      await FirebaseFirestore.instance
          .collection('universities')
          .doc('other')
          .collection('courses')
          .doc(courseId)
          .set({
            'subjectName': entry.subjectName,
            'classroom': entry.classroom,
            'teacher': entry.originalLocation,
            'dayOfWeek': widget.dayOfWeek,
            'period': widget.period,
            'university': widget.university,
            'faculty': courseData['faculty'] ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': user.uid,
          });

      // 分散協力型データベースにも曜日・時限情報を更新
      if (courseData['normalizedName'] != null) {
        await FirebaseFirestore.instance
            .collection('globalCourses')
            .doc(courseData['normalizedName'])
            .update({
              'dayOfWeek': widget.dayOfWeek,
              'period': widget.period,
              'lastUpdated': DateTime.now().toIso8601String(),
            });
      }

      // 時間割に追加
      final cellKey = '${widget.dayOfWeek}_${widget.period}';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('timetable')
          .doc('notes')
          .set({
            cellKey: entry.subjectName,
            'courseIds': {cellKey: courseId},
            'teacherNames': {cellKey: entry.originalLocation},
          }, SetOptions(merge: true));

      // 使用回数を更新
      if (courseData['normalizedName'] != null) {
        await FirebaseFirestore.instance
            .collection('globalCourses')
            .doc(courseData['normalizedName'])
            .update({'usageCount': FieldValue.increment(1)});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${entry.subjectName} を追加しました'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onCourseSelected();
      Navigator.of(context).pop();
    } catch (e) {
      print('授業追加エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('授業の追加に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getDayIndex(String dayOfWeek) {
    const days = ['月', '火', '水', '木', '金', '土', '日'];
    return days.indexOf(dayOfWeek);
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFF00E5FF),
      const Color(0xFF69F0AE),
      const Color(0xFFFFFF00),
      const Color(0xFFE1BEE7),
      const Color(0xFFFFFFFF),
      const Color(0xFF40C4FF),
      const Color(0xFF76FF03),
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[700]!, width: 2),
        ),
        child: Column(
          children: [
            // ヘッダー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[600]!.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${widget.dayOfWeek}曜 ${widget.period}限の授業を選択',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansJP',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '全国のユーザーが登録した授業から選択できます',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontFamily: 'NotoSansJP',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // 検索バー
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCourses,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '授業名、教員名、学部で検索...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue[400]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[800]!.withOpacity(0.5),
                ),
              ),
            ),
            // 授業リスト
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      )
                      : _filteredCourses.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'この時限の授業が見つかりません'
                                  : '検索結果がありません',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontFamily: 'NotoSansJP',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '新しい授業を追加してください',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                                fontFamily: 'NotoSansJP',
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = _filteredCourses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.grey[850],
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                course['subjectName'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'NotoSansJP',
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (course['teacherName']?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          course['teacherName'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                            fontFamily: 'NotoSansJP',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (course['faculty']?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.school,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          course['faculty'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                            fontFamily: 'NotoSansJP',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (course['classroom']?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.room,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          course['classroom'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                            fontFamily: 'NotoSansJP',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Colors.blue[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course['usageCount'] ?? 0}人が使用中',
                                        style: TextStyle(
                                          color: Colors.blue[400],
                                          fontSize: 12,
                                          fontFamily: 'NotoSansJP',
                                        ),
                                      ),
                                      if (course['dayOfWeek'] == null ||
                                          course['period'] == null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[600],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '時限未設定',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontFamily: 'NotoSansJP',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _selectCourse(course),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '選択',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansJP',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            // フッター
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansJP',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 新しい授業を追加するダイアログを表示
                        Navigator.of(context).pop();
                        if (widget.onAddNewCourse != null) {
                          widget.onAddNewCourse!(
                            _getDayIndex(widget.dayOfWeek),
                            widget.period,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '新しい授業を追加',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansJP',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
