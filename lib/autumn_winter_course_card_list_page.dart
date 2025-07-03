import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'credit_review_page.dart';
import 'autumn_winter_review_input_page.dart';
import 'autumn_winter_course_review_page.dart';
import 'providers/timetable_provider.dart';
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用
import 'main_page.dart';
import 'providers/current_page_provider.dart';

class AutumnWinterCourseCardListPage extends ConsumerStatefulWidget {
  const AutumnWinterCourseCardListPage({super.key});

  @override
  ConsumerState<AutumnWinterCourseCardListPage> createState() =>
      _AutumnWinterCourseCardListPageState();
}

class _AutumnWinterCourseCardListPageState
    extends ConsumerState<AutumnWinterCourseCardListPage> {
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _pagedCourses = [];
  bool _isLoading = true;
  static const int pageSize = 20;
  int _currentPage = 1;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadAllCourses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCourses() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('course_data').get();
      final List<Map<String, dynamic>> allCourses = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null &&
            data.containsKey('data') &&
            data['data'] is Map &&
            (data['data'] as Map)['courses'] is List) {
          final List<dynamic> courseList = (data['data'] as Map)['courses'];
          for (final course in courseList) {
            if (course is Map<String, dynamic>) {
              final lectureName = course['lectureName'] ?? course['name'] ?? '';
              final teacherName =
                  course['teacherName'] ??
                  course['instructor'] ??
                  course['teacher'] ??
                  '';
              final classroom = course['classroom'] ?? course['room'] ?? '';
              final category = course['category'] ?? '';
              final semester = course['semester'] ?? '';
              String finalTeacherName = teacherName;
              if (lectureName.isNotEmpty) {
                final timetableTeacherName =
                    ref.read(timetableProvider)['teacherNames']?[lectureName];
                if (timetableTeacherName != null &&
                    timetableTeacherName.isNotEmpty) {
                  finalTeacherName = timetableTeacherName;
                }
              }
              allCourses.add({
                'lectureName': lectureName,
                'teacherName': finalTeacherName,
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

      // 秋冬学期用: 授業名・教員名でレビュー情報を取得
      await _loadReviewStatsForAutumnWinter(allCourses);

      setState(() {
        _allCourses = allCourses;
        _currentPage = 1;
        _pagedCourses = _getPagedCourses(1);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading autumn/winter courses: $e');
      setState(() => _isLoading = false);
    }
  }

  // 秋冬学期用: 授業名・教員名でレビュー統計を取得
  Future<void> _loadReviewStatsForAutumnWinter(
    List<Map<String, dynamic>> courses,
  ) async {
    for (int i = 0; i < courses.length; i++) {
      final lectureName = courses[i]['lectureName'];
      final teacherName = courses[i]['teacherName'];

      if (lectureName.isNotEmpty && teacherName.isNotEmpty) {
        try {
          // 授業名と教員名でレビューを検索
          final reviewsSnapshot =
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .where('lectureName', isEqualTo: lectureName)
                  .where('teacherName', isEqualTo: teacherName)
                  .get();

          final reviews = reviewsSnapshot.docs;
          if (reviews.isNotEmpty) {
            double totalSatisfaction = 0.0;
            double totalEasiness = 0.0;
            bool hasMyReview = false;
            final user = FirebaseAuth.instance.currentUser;

            for (final doc in reviews) {
              final data = doc.data();
              final satisfaction = (data['overallSatisfaction'] ?? 0.0) * 1.0;
              final easiness = (data['easiness'] ?? 0.0) * 1.0;

              totalSatisfaction += satisfaction;
              totalEasiness += easiness;

              // 自分のレビューがあるかチェック
              if (user != null && data['userId'] == user.uid) {
                hasMyReview = true;
              }
            }

            courses[i] = {
              ...courses[i],
              'avgSatisfaction': totalSatisfaction / reviews.length,
              'avgEasiness': totalEasiness / reviews.length,
              'reviewCount': reviews.length,
              'hasMyReview': hasMyReview,
            };
          }
        } catch (e) {
          print('Error fetching reviews for $lectureName - $teacherName: $e');
        }
      }
    }
  }

  List<Map<String, dynamic>> _getPagedCourses(int page) {
    final start = (page - 1) * pageSize;
    final end =
        (start + pageSize) > _allCourses.length
            ? _allCourses.length
            : (start + pageSize);
    return _allCourses.sublist(start, end);
  }

  void _nextPage() {
    if (_currentPage * pageSize < _allCourses.length) {
      setState(() {
        _currentPage++;
        _pagedCourses = _getPagedCourses(_currentPage);
      });
      _pageController.animateToPage(
        _currentPage - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _pagedCourses = _getPagedCourses(_currentPage);
      });
      _pageController.animateToPage(
        _currentPage - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topOffset =
        kToolbarHeight + MediaQuery.of(context).padding.top;
    final int totalPages = (_allCourses.length / pageSize).ceil();
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/night_view.png', fit: BoxFit.cover),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
        Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  title: const Text('秋冬学期の授業一覧'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.white,
                ),
              ),
              // 横スクロールページビュー
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                bottom: 0,
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : Column(
                          children: [
                            // ページネーションUI
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      minimumSize: Size(32, 32),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed:
                                        _currentPage > 1 ? _prevPage : null,
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${((_currentPage - 1) * pageSize + 1)}-${((_currentPage - 1) * pageSize + _pagedCourses.length)}件 / 全${_allCourses.length}件',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      minimumSize: Size(32, 32),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed:
                                        _currentPage * pageSize <
                                                _allCourses.length
                                            ? _nextPage
                                            : null,
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 横スクロールPageView
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: totalPages,
                                onPageChanged: (pageIdx) {
                                  setState(() {
                                    _currentPage = pageIdx + 1;
                                    _pagedCourses = _getPagedCourses(
                                      _currentPage,
                                    );
                                  });
                                },
                                itemBuilder: (context, pageIdx) {
                                  final paged = _getPagedCourses(pageIdx + 1);
                                  return ListView.builder(
                                    physics: ClampingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      80,
                                    ),
                                    itemCount: paged.length,
                                    itemBuilder: (context, index) {
                                      return Align(
                                        alignment: Alignment.center,
                                        child: FractionallySizedBox(
                                          widthFactor: 0.80,
                                          child: Card(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            elevation: 5,
                                            color: Colors.white,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AutumnWinterCourseReviewPage(
                                                          lectureName:
                                                              paged[index]['lectureName'],
                                                          teacherName:
                                                              paged[index]['teacherName'],
                                                        ),
                                                  ),
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      paged[index]['lectureName'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if ((paged[index]['classroom'] ??
                                                            '')
                                                        .isNotEmpty)
                                                      Text(
                                                        '教室: ${paged[index]['classroom']}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '教員: ',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            (paged[index]['teacherName'] ??
                                                                        '')
                                                                    .isNotEmpty
                                                                ? paged[index]['teacherName']
                                                                : '未設定',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  (paged[index]['teacherName'] ??
                                                                              '')
                                                                          .isNotEmpty
                                                                      ? Colors
                                                                          .black
                                                                      : Colors
                                                                          .grey[500],
                                                              fontStyle:
                                                                  (paged[index]['teacherName'] ??
                                                                              '')
                                                                          .isEmpty
                                                                      ? FontStyle
                                                                          .italic
                                                                      : FontStyle
                                                                          .normal,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.amber,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${(paged[index]['avgSatisfaction'] ?? 0.0).toStringAsFixed(1)}',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .amber,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .sentiment_satisfied,
                                                              color:
                                                                  Colors.green,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${(paged[index]['avgEasiness'] ?? 0.0).toStringAsFixed(1)}',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.rate_review,
                                                              color:
                                                                  Colors.blue,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${paged[index]['reviewCount'] ?? 0}件',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        Colors
                                                                            .blue,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
              ),
              // ボトムナビ
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CommonBottomNavigation(
                  onNavigate: (page) {
                    ref.read(currentPageProvider.notifier).state = page;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
