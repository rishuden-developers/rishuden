import 'package:flutter/material.dart';
import 'dart:ui';

// 各ページを識別するためのenum
enum AppPage { park, timetable, creditReview, ranking, item }

class CommonBottomNavigation extends StatelessWidget {
  final AppPage currentPage;
  final VoidCallback? onParkTap;
  final VoidCallback? onTimetableTap;
  final VoidCallback? onCreditReviewTap;
  final VoidCallback? onRankingTap;
  final VoidCallback? onItemTap;

  final String parkIconAsset;
  final String parkIconActiveAsset;
  final String timetableIconAsset;
  final String timetableIconActiveAsset;
  final String creditReviewIconAsset;
  final String creditReviewActiveAsset;
  final String rankingIconAsset;
  final String rankingIconActiveAsset;
  final String itemIconAsset;
  final String itemIconActiveAsset;

  const CommonBottomNavigation({
    super.key,
    required this.currentPage,
    this.onParkTap,
    this.onTimetableTap,
    this.onCreditReviewTap,
    this.onRankingTap,
    this.onItemTap,
    required this.parkIconAsset,
    required this.parkIconActiveAsset,
    required this.timetableIconAsset,
    required this.timetableIconActiveAsset,
    required this.creditReviewIconAsset,
    required this.creditReviewActiveAsset,
    required this.rankingIconAsset,
    required this.rankingIconActiveAsset,
    required this.itemIconAsset,
    required this.itemIconActiveAsset,
  });

  Widget _buildNavItem({
    required String inactiveIconAsset,
    required String activeIconAsset,
    required VoidCallback? onPressed,
    required bool isActive,
  }) {
    const double activeSize = 80.0;
    const double inactiveSize = 60.0;

    // ★★★ 4. ボタンが上に動く移動量を小さくする ★★★
    const double activeYOffset = -8.0; // 例: -15.0から-8.0に変更
    const double inactiveYOffset = 0.0;

    final double currentSize = isActive ? activeSize : inactiveSize;
    final double currentYOffset = isActive ? activeYOffset : inactiveYOffset;
    final String photoToShow = isActive ? activeIconAsset : inactiveIconAsset;

    return Expanded(
      child: InkWell(
        onTap: isActive ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, currentYOffset, 0),
          transformAlignment: Alignment.center,
          child: Image.asset(
            photoToShow,
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
  Widget build(BuildContext context) {
    const double barHeight = 95.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(50.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            // ★★★ 1. 虹色のグラデーションに変更 ★★★
            gradient: LinearGradient(
              colors: [
                Color(0xFF00FFFF).withOpacity(0.6),
                Color.fromARGB(255, 153, 36, 221).withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            // ★★★ 2. フチを明るい白に変更して、よりモダンな印象に ★★★
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(50.0),
          ),
          // ★★★ 3. ボタン全体を少し下に配置して、見切れないようにする ★★★
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavItem(
                  inactiveIconAsset: creditReviewIconAsset,
                  activeIconAsset: creditReviewActiveAsset,
                  onPressed: onCreditReviewTap,
                  isActive: currentPage == AppPage.creditReview,
                ),
                _buildNavItem(
                  inactiveIconAsset: rankingIconAsset,
                  activeIconAsset: rankingIconActiveAsset,
                  onPressed: onRankingTap,
                  isActive: currentPage == AppPage.ranking,
                ),
                _buildNavItem(
                  inactiveIconAsset: parkIconAsset,
                  activeIconAsset: parkIconActiveAsset,
                  onPressed: onParkTap,
                  isActive: currentPage == AppPage.park,
                ),
                _buildNavItem(
                  inactiveIconAsset: timetableIconAsset,
                  activeIconAsset: timetableIconActiveAsset,
                  onPressed: onTimetableTap,
                  isActive: currentPage == AppPage.timetable,
                ),
                _buildNavItem(
                  inactiveIconAsset: itemIconAsset,
                  activeIconAsset: itemIconActiveAsset,
                  onPressed: onItemTap,
                  isActive: currentPage == AppPage.item,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
