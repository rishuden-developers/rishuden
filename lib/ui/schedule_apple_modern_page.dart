import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  final String title; // 授業名/予定名
  final String timeLabel; // 例: 08:50 - 10:20
  final String? subtitle; // 教室・教員など
  final Color? color; // 左ライン色

  const ScheduleItem({
    required this.id,
    required this.title,
    required this.timeLabel,
    this.subtitle,
    this.color,
  });
}

class ScheduleAppleModernPage extends StatelessWidget {
  final List<ScheduleItem> items;
  final Widget? profileIcon;
  final VoidCallback? onAdd; // 予定追加など

  const ScheduleAppleModernPage({
    super.key,
    required this.items,
    this.profileIcon,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(profileIcon: profileIcon),
                const SizedBox(height: 12),
                Expanded(
                  child: items.isEmpty
                      ? const _EmptyView()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _ScheduleCard(item: items[i]),
                        ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: _AnimatedFab(onPressed: onAdd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Widget? profileIcon;
  const _Header({this.profileIcon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const Expanded(
            child: Center(
              child: Text(
                '時間割',
                style: TextStyle(
                  fontFamily: 'Noto Sans JP',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          ClipOval(child: profileIcon ?? const _PlaceholderAvatar()),
        ],
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE2E8F0),
      ),
      child: const Icon(CupertinoIcons.person_fill, size: 18, color: Colors.black54),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final lineColor = item.color ?? const Color(0xFF94A3B8);
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.10),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 72,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans JP',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _MiniInfoChip(icon: CupertinoIcons.time, label: item.timeLabel),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty)
                      _MiniInfoChip(icon: CupertinoIcons.location_solid, label: item.subtitle!),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Noto Sans JP',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFab extends StatelessWidget {
  final VoidCallback? onPressed;
  const _AnimatedFab({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color(0xFF007AFF),
        elevation: 0,
        onPressed: onPressed,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(CupertinoIcons.calendar, color: Colors.black26, size: 48),
          SizedBox(height: 8),
          Text(
            '予定はありません',
            style: TextStyle(
              fontFamily: 'Noto Sans JP',
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
