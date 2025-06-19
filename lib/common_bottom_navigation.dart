import 'package:flutter/material.dart';
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'credit_review_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/current_page_provider.dart';

class CommonBottomNavigation extends ConsumerWidget {
  final String iconsParentPath = 'assets/buttons/common_navigation/';
  final String inactiveParkIcon = 'park_inactive.png';
  final String activeParkIcon = 'park_active.png';
  final String inactiveTimetableIcon = 'timetable_inactive.png';
  final String activeTimetableIcon = 'timetable_active.png';
  final String inactiveCreditIcon = 'credit_inactive.png';
  final String activeCreditIcon = 'credit_active.png';
  final String inactiveRankingIcon = 'ranking_inactive.png';
  final String activeRankingIcon = 'ranking_active.png';
  final String inactiveDressIcon = 'dress_inactive.png';
  final String activeDressIcon = 'dress_active.png';

  const CommonBottomNavigation({super.key});

  void _onNavigationButtonPressed({
    required BuildContext context,
    required WidgetRef ref,
    required AppPage page,
    required Widget pageWidget,
  }) {
    ref.read(currentPageProvider.notifier).state = page;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => pageWidget,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _buildNavdress({
    required BuildContext context,
    required WidgetRef ref,
    required AppPage page,
    required AppPage currentPage,
  }) {
    const double activeSize = 70.0;
    const double inactiveSize = 50.0;
    const double activeYOffset = -8.0;
    const double inactiveYOffset = 8.0;

    final bool isActive = currentPage == page;

    final String inactiveIcon;
    final String activeIcon;
    final Widget pageWidget;

    switch (page) {
      case AppPage.park:
        pageWidget = const ParkPage(
          diagnosedCharacterName: '剣士',
          answers: [],
          userName: '',
        );
        inactiveIcon = inactiveParkIcon;
        activeIcon = activeParkIcon;
        break;
      case AppPage.timetable:
        pageWidget = const TimeSchedulePage();
        inactiveIcon = inactiveTimetableIcon;
        activeIcon = activeTimetableIcon;
        break;
      case AppPage.credit:
        pageWidget = const CreditReviewPage(
          lectureName: '講義一覧',
          teacherName: '全講義',
        );
        inactiveIcon = inactiveCreditIcon;
        activeIcon = activeCreditIcon;
        break;
      case AppPage.ranking:
        pageWidget = const RankingPage();
        inactiveIcon = inactiveRankingIcon;
        activeIcon = activeRankingIcon;
        break;
      case AppPage.dress:
        pageWidget = const ItemPage();
        inactiveIcon = inactiveDressIcon;
        activeIcon = activeDressIcon;
        break;
    }

    final double currentSize = isActive ? activeSize : inactiveSize;
    final double currentYOffset = isActive ? activeYOffset : inactiveYOffset;
    final String icon = isActive ? activeIcon : inactiveIcon;

    return Expanded(
      child: InkWell(
        onTap:
            isActive
                ? null
                : () => _onNavigationButtonPressed(
                  context: context,
                  ref: ref,
                  page: page,
                  pageWidget: pageWidget,
                ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, currentYOffset, 0),
          transformAlignment: Alignment.center,
          child: Image.asset(
            '$iconsParentPath$icon',
            width: currentSize,
            height: currentSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.broken_image,
                size: currentSize * 0.8,
                color: Colors.grey[400],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double barHeight = 95.0;
    final currentPage = ref.watch(currentPageProvider);

    return SizedBox(
      height: barHeight,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bottom_bar_bg.png', fit: BoxFit.cover),
          ),
          // ボタン群
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildNavdress(
                context: context,
                ref: ref,
                page: AppPage.ranking,
                currentPage: currentPage,
              ),
              _buildNavdress(
                context: context,
                ref: ref,
                page: AppPage.credit,
                currentPage: currentPage,
              ),
              _buildNavdress(
                context: context,
                ref: ref,
                page: AppPage.park,
                currentPage: currentPage,
              ),
              _buildNavdress(
                context: context,
                ref: ref,
                page: AppPage.timetable,
                currentPage: currentPage,
              ),
              _buildNavdress(
                context: context,
                ref: ref,
                page: AppPage.dress,
                currentPage: currentPage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
