import 'package:flutter/cupertino.dart';

import '../theme/tokens.dart';

/// 任意の子ウィジェットにiOS風のスワイプアクション背景を与えるDismissibleラッパー
class IOSDismissible extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPrimary; // 右→左（主要）
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onDelete; // 左→右（削除）
  final Key dismissKey;

  const IOSDismissible({
    super.key,
    required this.dismissKey,
    required this.child,
    this.onPrimary,
    this.primaryLabel = '完了',
    this.primaryIcon = CupertinoIcons.check_mark,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTokens.colorsOf(context);
    return Dismissible(
      key: dismissKey,
      background: _actionBg(context, CupertinoColors.systemRed, CupertinoIcons.delete, '削除', Alignment.centerLeft),
      secondaryBackground: _actionBg(context, c.tint, primaryIcon, primaryLabel, Alignment.centerRight),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onDelete?.call();
          return false; // 見た目だけ/セル自体は保持
        } else {
          onPrimary?.call();
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
