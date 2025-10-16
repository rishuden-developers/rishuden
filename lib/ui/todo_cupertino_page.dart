import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/tokens.dart';

/// シンプルなToDoデータの契約
class TodoItemData {
  final String id;
  final String title;
  final DateTime? due; // 任意の期限
  final bool completed;
  const TodoItemData({
    required this.id,
    required this.title,
    this.due,
    this.completed = false,
  });

  TodoItemData copyWith({String? title, DateTime? due, bool? completed}) =>
      TodoItemData(
        id: id,
        title: title ?? this.title,
        due: due ?? this.due,
        completed: completed ?? this.completed,
      );
}

enum TodoTab { active, done }

/// 既存状態管理に接続しやすいよう、必要なデータ/コールバックだけを受け取る
class TodoCupertinoPage extends StatefulWidget {
  final List<TodoItemData> items; // 全件
  final TodoTab initialTab;
  final ValueChanged<TodoTab>? onTabChanged;
  final void Function(TodoItemData item)? onToggleComplete;
  final void Function(TodoItemData item)? onDelete;
  final VoidCallback? onAdd;

  const TodoCupertinoPage({
    super.key,
    required this.items,
    this.initialTab = TodoTab.active,
    this.onTabChanged,
    this.onToggleComplete,
    this.onDelete,
    this.onAdd,
  });

  @override
  State<TodoCupertinoPage> createState() => _TodoCupertinoPageState();
}

class _TodoCupertinoPageState extends State<TodoCupertinoPage>
    with SingleTickerProviderStateMixin {
  late TodoTab _tab;
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _controller = AnimationController(
      vsync: this,
      duration: AppTokens.durationNormal,
    );
    _fade = CurvedAnimation(parent: _controller, curve: AppTokens.curveNormal);
    _slide = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
        .chain(CurveTween(curve: AppTokens.curveNormal))
        .animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchTab(TodoTab t) async {
    if (_tab == t) return;
    await _controller.reverse();
    setState(() => _tab = t);
    _controller.forward();
    widget.onTabChanged?.call(t);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTokens.colorsOf(context);

    final activeItems = widget.items.where((e) => !e.completed).toList();
    final doneItems = widget.items.where((e) => e.completed).toList();
    final showing = _tab == TodoTab.active ? activeItems : doneItems;

    return CupertinoPageScaffold(
      backgroundColor: c.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: c.bg.withOpacity(0.95),
        border: AppTokens.transparentBottomBorder,
        middle: Text('ToDo', style: AppTokens.title17(context).copyWith(color: c.label)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: Icon(CupertinoIcons.ellipsis_circle, color: c.tint),
        ),
      ),
      child: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTokens.spaceLg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd),
                  child: _buildSegmented(context, c),
                ),
                const SizedBox(height: AppTokens.spaceMd),
                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: showing.isEmpty
                          ? _buildEmptyState(context, c)
                          : _buildList(context, c, showing),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLg + 56), // ボタン分の余白
              ],
            ),

            // 追加ボタン（下部固定）
            Positioned(
              left: AppTokens.spaceMd,
              right: AppTokens.spaceMd,
              bottom: AppTokens.spaceMd,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildAddButton(context, c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmented(BuildContext context, AppColors c) {
    final items = {
      TodoTab.active: Text('未完了', style: AppTokens.body17(context)),
      TodoTab.done: Text('完了', style: AppTokens.body17(context)),
    };
    return CupertinoSegmentedControl<TodoTab>(
      children: items,
      onValueChanged: _switchTab,
      groupValue: _tab,
      padding: const EdgeInsets.all(2),
      selectedColor: c.tint,
      unselectedColor: c.secondaryBg,
      pressedColor: c.secondaryBg,
      borderColor: c.secondaryBg,
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.square_list, size: 56, color: c.secondaryLabel),
            const SizedBox(height: AppTokens.spaceMd),
            Text('未完了のタスクはありません',
                style: AppTokens.body17(context).copyWith(color: c.label)),
            const SizedBox(height: AppTokens.spaceSm),
            Text('追加ボタンからタスクを作成できます',
                textAlign: TextAlign.center,
                style: AppTokens.caption13(context).copyWith(color: c.secondaryLabel)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AppColors c, List<TodoItemData> items) {
    return CupertinoScrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.only(
          top: AppTokens.spaceSm,
          bottom: AppTokens.spaceLg,
        ),
        itemCount: items.length,
        separatorBuilder: (_, __) => AppTokens.insetDivider(context),
        itemBuilder: (context, index) {
          final item = items[index];
          return _TodoCell(
            key: ValueKey(item.id),
            item: item,
            onToggle: widget.onToggleComplete,
            onDelete: widget.onDelete,
          );
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, AppColors c) {
    return CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLg,
        vertical: AppTokens.spaceSm + 2,
      ),
      borderRadius: BorderRadius.circular(AppTokens.radiusL),
      onPressed: widget.onAdd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.add, size: 20),
          const SizedBox(width: AppTokens.spaceSm),
          const Text('追加'),
        ],
      ),
    );
  }
}

class _TodoCell extends StatefulWidget {
  final TodoItemData item;
  final void Function(TodoItemData item)? onToggle;
  final void Function(TodoItemData item)? onDelete;
  const _TodoCell({super.key, required this.item, this.onToggle, this.onDelete});

  @override
  State<_TodoCell> createState() => _TodoCellState();
}

class _TodoCellState extends State<_TodoCell> with SingleTickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: AppTokens.durationFast,
      value: 1.0,
    );
    _scale = Tween(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: AppTokens.curveFastOut),
    );
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  void _hapticSuccess() {
    HapticFeedback.lightImpact();
  }

  void _toggle() {
    _checkCtrl.forward(from: 0.95);
    widget.onToggle?.call(widget.item);
    _hapticSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTokens.colorsOf(context);
    final item = widget.item;
    final due = item.due;
    final isOverdue = due != null && due.isBefore(DateTime.now()) && !item.completed;
    final dateText = due != null ? DateFormat.Md().format(due) : null;

    return _IOSDismissible(
      key: ValueKey('dismiss-${item.id}'),
      onDelete: widget.onDelete == null ? null : () => widget.onDelete!(item),
      onPrimary: _toggle,
      primaryLabel: item.completed ? '未完了' : '完了',
      primaryIcon: item.completed ? CupertinoIcons.arrow_uturn_left : CupertinoIcons.check_mark,
      child: Container(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMd,
          vertical: AppTokens.spaceSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // チェック
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: ScaleTransition(
                scale: _scale,
                child: Icon(
                  item.completed
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  size: 24,
                  color: item.completed ? c.tint : c.secondaryLabel,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spaceMd),
            // タイトル + 期限
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTokens.body17(context).copyWith(
                      color: item.completed
                          ? c.secondaryLabel
                          : (isOverdue ? CupertinoColors.systemRed : c.label),
                      decoration: item.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (dateText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _DueBadge(
                        text: dateText,
                        color: isOverdue ? CupertinoColors.systemRed : c.secondaryBg,
                        labelColor: isOverdue ? CupertinoColors.white : c.secondaryLabel,
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color labelColor;
  const _DueBadge({required this.text, required this.color, required this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: AppTokens.caption13(context).copyWith(color: labelColor)),
    );
  }
}

/// iOS風スワイプ（Dismissibleベース）。左右で「完了/未完了」「削除」。
class _IOSDismissible extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPrimary; // 右→左（Complete/Undo）
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onDelete; // 左→右（Delete）

  const _IOSDismissible({
    super.key,
    required this.child,
    required this.onPrimary,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTokens.colorsOf(context);
    return Dismissible(
      key: key!,
      background: _actionBg(context, CupertinoColors.systemRed, CupertinoIcons.delete, '削除', Alignment.centerLeft),
      secondaryBackground: _actionBg(context, c.tint, primaryIcon, primaryLabel, Alignment.centerRight),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 左スワイプで削除
          if (onDelete != null) onDelete!();
          return false; // iOS風: 背景アクションだけ実行しセルは保持
        } else {
          if (onPrimary != null) onPrimary!();
          return false;
        }
      },
      child: child,
    );
  }

  Widget _actionBg(BuildContext context, Color color, IconData icon, String label, Alignment align) {
    final isLeft = align == Alignment.centerLeft;
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd),
      alignment: align,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeft) ...[
            Text(label, style: const TextStyle(color: CupertinoColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(icon, color: CupertinoColors.white),
          ] else ...[
            Icon(icon, color: CupertinoColors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: CupertinoColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ]
        ],
      ),
    );
  }
}
