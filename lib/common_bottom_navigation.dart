import 'package:flutter/material.dart';

// 各ページを識別するためのenum

enum AppPage { park, timetable, creditReview, ranking, item }

class CommonBottomNavigation extends StatelessWidget {
  final AppPage currentPage;

  final VoidCallback? onParkTap;

  final VoidCallback? onTimetableTap;

  final VoidCallback? onCreditReviewTap;

  final VoidCallback? onRankingTap;

  final VoidCallback? onItemTap;

  // 各ボタンには「通常状態」の画像パスを指定

  final String parkIconAsset;

  final String timetableIconAsset;

  final String creditReviewIconAsset;

  final String rankingIconAsset;

  final String itemIconAsset;

  const CommonBottomNavigation({
    super.key,

    required this.currentPage,

    this.onParkTap,

    this.onTimetableTap,

    this.onCreditReviewTap,

    this.onRankingTap,

    this.onItemTap,

    required this.parkIconAsset,

    required this.timetableIconAsset,

    required this.creditReviewIconAsset,

    required this.rankingIconAsset,

    required this.itemIconAsset,
  });

  // lib/common_bottom_navigation.dart 内の CommonBottomNavigation クラス

  Widget _buildNavItem({
    required String iconAssetPath,

    required AppPage page,

    required VoidCallback? onPressed,

    required double buttonWidth, // ボタン全体の幅

    required double buttonHeight, // ボタン全体の高さ

    required bool isActive,
  }) {
    // ★★★ アイコン自体の表示サイズを調整 ★★★

    // ボタンの高さに対して、より大きな割合をアイコン表示に使う

    final double iconDisplayProportion = 1.20; // 例: ボタンの高さの80%をアイコン基本サイズに

    final double iconDisplaySize = buttonHeight * iconDisplayProportion;

    Widget iconImage = Image.asset(
      iconAssetPath,
      width: iconDisplaySize,
      height: iconDisplaySize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print(
          "Error loading image $iconAssetPath (isActive: $isActive): $error",
        );
        return Icon(
          Icons.broken_image,
          size: iconDisplaySize * 0.8,
          color: Colors.grey[400],
        );
      },
    );

    // finalIconContent は常に iconImage (拡大なし)
    Widget finalIconContent = iconImage;

    return Expanded(
      child: InkWell(
        onTap: isActive ? null : onPressed,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
          // ★★★ decoration プロパティを完全に削除、または常にnullに ★★★
          // decoration: null, // もし明示的に何もしないことを示すなら
          // あるいは、タップエフェクトの形状のためにborderRadiusだけ残すなら以下のように
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0), // InkWellの形状と合わせる
            color: Colors.transparent, // 明示的に背景を透明に
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: isActive ? 1.0 : 0.6, // アクティブ時は不透明、非アクティブ時は半透明
            child: finalIconContent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final double navButtonWidth = screenWidth * 0.19;

    final double navButtonHeight = 80.0;

    return BottomAppBar(
      color: Colors.transparent, // 背景を透明に (ページ背景が見えるように)

      elevation: 0, // 影もなし

      padding: EdgeInsets.zero,

      child: Container(
        height: navButtonHeight + 15, // バー全体の高さ (アイコンの拡大やエフェクトを考慮)
        // decoration: BoxDecoration( // ボタンバー自体に背景をつけたい場合はここを有効化

        // color: Colors.black.withOpacity(0.2),

        // ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          crossAxisAlignment: CrossAxisAlignment.center,

          children: <Widget>[
            _buildNavItem(
              iconAssetPath: creditReviewIconAsset,

              page: AppPage.creditReview,

              onPressed: onCreditReviewTap,

              buttonWidth: navButtonWidth,

              buttonHeight: navButtonHeight,

              isActive: currentPage == AppPage.creditReview,
            ),

            _buildNavItem(
              iconAssetPath: rankingIconAsset,

              page: AppPage.ranking,

              onPressed: onRankingTap,

              buttonWidth: navButtonWidth,

              buttonHeight: navButtonHeight,

              isActive: currentPage == AppPage.ranking,
            ),

            _buildNavItem(
              iconAssetPath: parkIconAsset,

              page: AppPage.park,

              onPressed: onParkTap,

              buttonWidth: navButtonWidth,

              buttonHeight: navButtonHeight,

              isActive: currentPage == AppPage.park,
            ),

            _buildNavItem(
              iconAssetPath: itemIconAsset,

              page: AppPage.item,

              onPressed: onItemTap,

              buttonWidth: navButtonWidth,

              buttonHeight: navButtonHeight,

              isActive: currentPage == AppPage.item,
            ),

            _buildNavItem(
              iconAssetPath: timetableIconAsset,

              page: AppPage.timetable,

              onPressed: onTimetableTap,

              buttonWidth: navButtonWidth,

              buttonHeight: navButtonHeight,

              isActive: currentPage == AppPage.timetable,
            ),
          ],
        ),
      ),
    );
  } // build メソッドの閉じ括弧
}
