import 'package:flutter/material.dart';
import '../credit_review_page.dart';

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const CourseCard({required this.course, super.key});

  @override
  Widget build(BuildContext context) {
    // courseIdから講義名と教室を抽出
    String lectureName = course['lectureName'] ?? '';
    String classroom = course['classroom'] ?? '';

    // courseIdが「講義名|教室|曜日|時限」形式の場合、パースして取得
    final courseId = course['courseId'] ?? '';
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
                    teacherName: course['teacherName'] ?? '',
                    courseId: course['courseId'],
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
              // 授業名と教室
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lectureName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          classroom.isNotEmpty
                              ? '教室: $classroom'
                              : course['teacherName'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRatingItem(
                    '満足度',
                    course['avgSatisfaction'].toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildRatingItem(
                    '楽単度',
                    course['avgEasiness'].toStringAsFixed(1),
                    Icons.sentiment_satisfied,
                    Colors.green,
                  ),
                  _buildRatingItem(
                    'レビュー数',
                    '${course['reviewCount']}件',
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
