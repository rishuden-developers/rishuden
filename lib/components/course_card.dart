import 'package:flutter/material.dart';
import '../credit_review_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timetable_provider.dart';

class CourseCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> course;
  final Function(String)? onTeacherNameChanged;

  const CourseCard({
    required this.course,
    this.onTeacherNameChanged,
    super.key,
  });

  @override
  ConsumerState<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends ConsumerState<CourseCard> {
  late TextEditingController _teacherNameController;
  bool _isEditingTeacherName = false;

  @override
  void initState() {
    super.initState();
    _teacherNameController = TextEditingController(
      text: widget.course['teacherName'] ?? '',
    );
  }

  @override
  void dispose() {
    _teacherNameController.dispose();
    super.dispose();
  }

  // 教員名を更新する（ローカル状態とtimetableProviderの両方に保存）
  void _updateTeacherName(String newTeacherName) {
    final courseId = widget.course['courseId'] ?? '';

    // ローカル状態の更新
    if (widget.onTeacherNameChanged != null) {
      widget.onTeacherNameChanged!(newTeacherName);
    }

    // timetableProviderにも保存（時間割画面と同期）
    if (courseId.isNotEmpty) {
      ref
          .read(timetableProvider.notifier)
          .setTeacherName(courseId, newTeacherName);
    }

    print(
      'Updated teacher name for $courseId to: $newTeacherName (synced with timetable)',
    );
  }

  @override
  Widget build(BuildContext context) {
    // courseIdから講義名と教室を抽出
    String lectureName = widget.course['lectureName'] ?? '';
    String classroom = widget.course['classroom'] ?? '';

    // 教員名をtimetableProviderから取得（時間割画面と同期）
    final courseId = widget.course['courseId'] ?? '';
    String teacherName = widget.course['teacherName'] ?? '';
    if (courseId.isNotEmpty) {
      final timetableTeacherName =
          ref.watch(timetableProvider)['teacherNames']?[courseId];
      if (timetableTeacherName != null && timetableTeacherName.isNotEmpty) {
        teacherName = timetableTeacherName;
      }
    }

    // courseIdが「講義名|教室|曜日|時限」形式の場合、パースして取得
    if (courseId.contains('|')) {
      final parts = courseId.split('|');
      if (parts.length >= 2) {
        lectureName = parts[0];
        classroom = parts[1];
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreditReviewPage(
                    lectureName: lectureName,
                    teacherName: teacherName,
                    courseId: widget.course['courseId'],
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 授業名
              Text(
                lectureName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // 教員名（編集可能）
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '教員: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Expanded(
                    child:
                        _isEditingTeacherName || teacherName.isEmpty
                            ? TextField(
                              controller: _teacherNameController,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: '未設定',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (value) {
                                setState(() {
                                  _isEditingTeacherName = false;
                                });
                                _updateTeacherName(value);
                              },
                              onEditingComplete: () {
                                setState(() {
                                  _isEditingTeacherName = false;
                                });
                                _updateTeacherName(_teacherNameController.text);
                              },
                            )
                            : GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isEditingTeacherName = true;
                                });
                              },
                              child: Text(
                                teacherName.isNotEmpty ? teacherName : '未設定',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      teacherName.isNotEmpty
                                          ? Colors.black
                                          : Colors.grey[500],
                                  fontStyle:
                                      teacherName.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                ),
                              ),
                            ),
                  ),
                  if (_isEditingTeacherName)
                    IconButton(
                      icon: const Icon(Icons.check, size: 16),
                      onPressed: () {
                        setState(() {
                          _isEditingTeacherName = false;
                        });
                        _updateTeacherName(_teacherNameController.text);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 投稿済みバッジ
              if (widget.course['hasMyReview'] == true)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRatingItem(
                    '満足度',
                    widget.course['avgSatisfaction'].toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildRatingItem(
                    '楽単度',
                    widget.course['avgEasiness'].toStringAsFixed(1),
                    Icons.sentiment_satisfied,
                    Colors.green,
                  ),
                  _buildRatingItem(
                    'レビュー数',
                    '${widget.course['reviewCount']}件',
                    Icons.comment,
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
