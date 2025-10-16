import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// 紙吹雪など外部依存は入れず、純UIアニメのみで上品さを演出します。

/// Apple風・モダンなToDoデザイン用データモデル
class AppleTodoItem {
  final String id;
  final String title;
  final DateTime? due;
  final bool completed;
  final String? category; // 例: 勉強/生活/メモ/その他
  final Color? categoryColor; // 左ライン色

  const AppleTodoItem({
    required this.id,
    required this.title,
    this.due,
    this.completed = false,
    this.category,
    this.categoryColor,
  });
}

enum AppleTab { active, done }

/// Apple風ToDoページ（未完了/完了タブ・リスト・追加ボタンを維持）
class TodoAppleModernPage extends StatefulWidget {
  final List<AppleTodoItem> items;
  final AppleTab initialTab;
  final ValueChanged<AppleTab>? onTabChanged;
  final void Function(AppleTodoItem item)? onToggleComplete;
  final void Function(AppleTodoItem item)? onDelete;
  final VoidCallback? onAdd;
  final Widget? profileIcon; // ヘッダー右上の丸いプロフィールアイコン

  const TodoAppleModernPage({
    super.key,
    required this.items,
    this.initialTab = AppleTab.active,
    this.onTabChanged,
    this.onToggleComplete,
    this.onDelete,
    this.onAdd,
    this.profileIcon,
  });

  @override
  State<TodoAppleModernPage> createState() => _TodoAppleModernPageState();
}

class _TodoAppleModernPageState extends State<TodoAppleModernPage>
    with TickerProviderStateMixin {
  // ==== 共通アニメ定数（再利用用） ====
  // すべての主要アニメーション時間を 1 秒に統一
  static const kAnimFast = Duration(seconds: 1);
  static const kAnim = Duration(seconds: 1);
  static const kTabSwitchDuration = Duration(seconds: 1);
  static const kInsertDuration = Duration(seconds: 1);
  static const kCurve = Curves.easeOutCubic;
  static const kCurveEmphasis = Curves.easeOutBack;
  static const int kStaggerMax = 8; // 初回表示は先頭8件のみ段階出現
  static bool reduceMotion = false; // 将来の低減モーション切替用

  late AppleTab _tab;
  // タブごとのスクロール位置維持
  final ScrollController _scrollActive = ScrollController();
  final ScrollController _scrollDone = ScrollController();

  // 新規挿入・初回段階表示制御
  final Set<String> _knownIds = <String>{};
  final Set<String> _justInserted = <String>{};
  bool _initialStaggerDone = false;

  // FABのスケール
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;

    _fabCtrl = AnimationController(
      vsync: this,
      duration: kAnim,
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _fabScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _scrollActive.dispose();
    _scrollDone.dispose();
    super.dispose();
  }

  void _switchTab(AppleTab t) async {
    if (_tab == t) return;
    setState(() => _tab = t);
    widget.onTabChanged?.call(t);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初回の段階的出現: 先頭kStaggerMax件に対して短い遅延をつけて疑似挿入アニメ
    if (!_initialStaggerDone) {
      final items = widget.items.where((e) => _tab == AppleTab.active ? !e.completed : e.completed).toList();
      final count = items.length.clamp(0, kStaggerMax);
      for (int i = 0; i < count; i++) {
        final id = items[i].id;
        Future.delayed(Duration(milliseconds: 40 * i), () {
          if (!mounted) return;
          setState(() => _justInserted.add(id));
          Future.delayed(kInsertDuration, () {
            if (mounted) setState(() => _justInserted.remove(id));
          });
        });
      }
      _initialStaggerDone = true;
    }
  }

  @override
  void didUpdateWidget(covariant TodoAppleModernPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 新しく追加されたIDを検出して疑似挿入アニメを適用
    final newIds = widget.items.map((e) => e.id).toSet();
    final added = newIds.difference(_knownIds);
    if (added.isNotEmpty) {
      for (final id in added) {
        _justInserted.add(id);
        Future.delayed(kInsertDuration, () {
          if (mounted) setState(() => _justInserted.remove(id));
        });
      }
    }
    _knownIds
      ..clear()
      ..addAll(newIds);
  }

  @override
  Widget build(BuildContext context) {
    final itemsActive = widget.items.where((e) => !e.completed).toList();
    final itemsDone = widget.items.where((e) => e.completed).toList();
    final showing = _tab == AppleTab.active ? itemsActive : itemsDone;

    return Container(
      color: const Color(0xFFF8FAFC), // 背景: 柔らかいグレー
      child: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            Column(
              children: [
                _Header(profileIcon: widget.profileIcon),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ToggleTabs(
                    value: _tab,
                    onChanged: _switchTab,
                  ),
                ),
                const SizedBox(height: 12),
                // タブ切替: AnimatedSwitcherでフェード+横スライド（スクロール位置はコントローラで維持）
                Expanded(
                  child: AnimatedSwitcher(
                    duration: kTabSwitchDuration,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _TabList(
                      key: ValueKey(_tab),
                      items: showing,
                      controller: _tab == AppleTab.active ? _scrollActive : _scrollDone,
                      itemBuilder: (item) {
                        final isInserted = _justInserted.contains(item.id);
                        return _InsertedWrapper(
                          key: ValueKey('ins_${item.id}'),
                          inserted: isInserted,
                          child: ToDoCard(
                            key: ValueKey('todo_${item.id}'),
                            item: item,
                            onToggle: () => widget.onToggleComplete?.call(item),
                            onDelete: widget.onDelete == null ? null : () => widget.onDelete!(item),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // 中央下の丸い追加ボタン
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: GestureDetector(
                  onTapDown: (_) {
                    setState(() => _fabPressed = true);
                    _fabCtrl.forward();
                  },
                  onTapUp: (_) {
                    setState(() => _fabPressed = false);
                    _fabCtrl.reverse();
                  },
                  onTapCancel: () {
                    setState(() => _fabPressed = false);
                    _fabCtrl.reverse();
                  },
                  child: ScaleTransition(
                    scale: _fabScale,
                    child: _AnimatedFab(onPressed: widget.onAdd, pressed: _fabPressed),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 中央タイトル + 右上丸プロフィール
class _Header extends StatelessWidget {
  final Widget? profileIcon;
  const _Header({this.profileIcon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const SizedBox(width: 40), // 左は空けて中央寄せ
          const Expanded(
            child: Center(
              child: Text(
                'ToDoリスト',
                style: TextStyle(
                  fontFamily: 'Noto Sans JP',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          ClipOval(
            child: profileIcon ?? _PlaceholderAvatar(),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
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

/// トグルスイッチ風のタブ
class _ToggleTabs extends StatelessWidget {
  final AppleTab value;
  final ValueChanged<AppleTab> onChanged;
  const _ToggleTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isActive = value == AppleTab.active;
    final activeColor = Colors.white;
    final inactiveColor = const Color(0xFFEAF2FF);
    return Container(
  padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: inactiveColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _pill(
              label: '未完了',
              selected: isActive,
              onTap: () => onChanged(AppleTab.active),
              bg: activeColor,
            ),
          ),
          Expanded(
            child: _pill(
              label: '完了',
              selected: !isActive,
              onTap: () => onChanged(AppleTab.done),
              bg: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color bg,
  }) {
    return AnimatedContainer(
      duration: _TodoAppleModernPageState.kAnim,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? bg : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Noto Sans JP',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ToDoカード（左にカテゴリカラーライン、影、角丸）
class ToDoCard extends StatefulWidget {
  final AppleTodoItem item;
  final VoidCallback? onToggle; // 丸ボタンでトグル
  final VoidCallback? onDelete; // 任意: 長押しで削除
  const ToDoCard({super.key, required this.item, this.onToggle, this.onDelete});

  @override
  State<ToDoCard> createState() => _ToDoCardState();
}

class _ToDoCardState extends State<ToDoCard> with TickerProviderStateMixin {
  bool _fadingOut = false; // 行が消えるフェード
  bool _flashBg = false; // 背景の一瞬の点灯（完了時のみ）
  bool _localChecked = false; // 見た目だけ先にチェック扱い
  bool _toggleInProgress = false; // 多重タップ防止
  Timer? _preFadeTimer; // フェード開始用（キャンセル可）
  Timer? _commitTimer; // 実トグル用（キャンセル可）
  int _animStamp = 0; // このカードだけのアニメトリガ
  bool _animateNow = false; // このカードだけ即時にアニメ再生するフラグ

  // カードの軽いスライド（右へ8px→戻る）
  late final AnimationController _jiggleCtl;
  late final Animation<Offset> _jiggle;

  Future<void> _handleToggle() async {
    if (_toggleInProgress) return;
    final wasDone = widget.item.completed || _localChecked;
    // 完了ONのときは背景を薄い緑にフラッシュ
    if (!wasDone) {
      setState(() => _flashBg = true);
      Future.delayed(_TodoAppleModernPageState.kAnim, () {
        if (mounted) setState(() => _flashBg = false);
      });
    }

    // カードの軽いスライド（揺れ）
    _jiggleCtl
      ..stop()
      ..reset()
      ..forward();

    // 未完了→完了へ(Active→Done)のときは2秒Active側に残す
    if (!wasDone) {
      _toggleInProgress = true;
      setState(() {
        _localChecked = true; // 見た目は先にチェック
        _animStamp++; // チェック線/バウンスの再生トリガ
        _animateNow = true;
      });

      const totalHold = Duration(seconds: 2);
      final fadeLead = _TodoAppleModernPageState.kAnimFast; // 最後の1秒でフェード
      final preFade = totalHold - fadeLead;

      _preFadeTimer?.cancel();
      _commitTimer?.cancel();

      _preFadeTimer = Timer(preFade, () {
        if (!mounted) return;
        setState(() => _fadingOut = true);
      });

      _commitTimer = Timer(totalHold, () {
        if (!mounted) return;
        widget.onToggle?.call();
        _toggleInProgress = false;
      });
    } else {
      // 完了→未完了（Done→Active）は即時反映
      setState(() {
        _fadingOut = true;
        _animStamp++; // 解除時のアニメ（必要なら逆アニメにも対応）
        _animateNow = true;
      });
      await Future.delayed(_TodoAppleModernPageState.kAnimFast);
      widget.onToggle?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final lineColor = item.categoryColor ?? const Color(0xFF94A3B8);
  final isDone = _localChecked || item.completed;
    final dueText = item.due != null ? DateFormat('MM/dd HH:mm').format(item.due!) : '期限なし';

    return AnimatedOpacity(
      duration: _TodoAppleModernPageState.kAnim,
      curve: _TodoAppleModernPageState.kCurve,
      opacity: _fadingOut ? 0.0 : 1.0,
      child: AnimatedContainer(
        duration: _TodoAppleModernPageState.kAnim,
        curve: _TodoAppleModernPageState.kCurve,
        decoration: BoxDecoration(
          color: _flashBg && !isDone ? Colors.green.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.10),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            SlideTransition(
              position: _jiggle,
              child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左のカテゴリカラーライン
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
            // 丸チェック（チェックリスト形式）
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Builder(builder: (context) {
                final w = _AnimatedCheckmark(
                  checked: isDone,
                  animateStamp: _animStamp,
                  animateNow: _animateNow,
                  onTap: _handleToggle,
                );
                // 一度使ったらフラグを下げて他アイテムに影響しないように
                if (_animateNow) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _animateNow = false);
                  });
                }
                return w;
              }),
            ),
            Expanded(
              child: Opacity(
                opacity: isDone ? 0.6 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Noto Sans JP',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 小さな補助情報（期限・カテゴリ）
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _MiniInfoChip(
                          icon: CupertinoIcons.calendar,
                          label: '期限 $dueText',
                        ),
                        if (item.category != null)
                          _MiniInfoChip(
                            icon: CupertinoIcons.tag,
                            label: item.category!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 右端の小さめ矢印
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.black45),
            ),
          ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // カードの揺れ（右へ8px→戻る）
    _jiggleCtl = AnimationController(vsync: this, duration: _TodoAppleModernPageState.kAnimFast);
    _jiggle = Tween<Offset>(begin: Offset.zero, end: const Offset(8 / 300, 0))
        .chain(CurveTween(curve: _TodoAppleModernPageState.kCurve))
        .animate(_jiggleCtl);
    _jiggleCtl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _jiggleCtl.reverse();
    });
  }

  @override
  void dispose() {
    _jiggleCtl.dispose();
    _preFadeTimer?.cancel();
    _commitTimer?.cancel();
    super.dispose();
  }
}

/// チェックアイコンのアニメ（Scale 0.8→1.1→1.0 + 軽いFade）
class _AnimatedCheckmark extends StatelessWidget {
  final bool checked;
  final int animateStamp; // 親からのアニメ再生トリガ（カード固有）
  final bool animateNow; // このカードのみアニメを有効化
  final VoidCallback onTap;
  const _AnimatedCheckmark({
    required this.checked,
    required this.onTap,
    this.animateStamp = 0,
    this.animateNow = false,
  });

  @override
  Widget build(BuildContext context) {
  final duration = _TodoAppleModernPageState.reduceMotion
    ? Duration.zero
    : (animateNow ? _TodoAppleModernPageState.kAnim : Duration.zero);

    // スケールのバウンス（0.8→1.1→1.0）をトグル毎に再生
    final bounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.1)
            .chain(CurveTween(curve: _TodoAppleModernPageState.kCurveEmphasis)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: _TodoAppleModernPageState.kCurve)),
        weight: 40,
      ),
    ]);

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: duration,
        key: ValueKey('bounce_${checked}_$animateStamp'),
        builder: (context, t, child) {
          final scale = bounce.transform(t.clamp(0.0, 1.0));
          return Transform.scale(scale: scale, child: child);
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: checked ? 0.0 : 1.0, end: checked ? 1.0 : 0.0),
          duration: duration,
          curve: _TodoAppleModernPageState.kCurve,
          key: ValueKey('line_${checked}_$animateStamp'),
          builder: (context, t, __) => SizedBox(
            width: 22,
            height: 22,
            child: CustomPaint(
              painter: _CheckPainter(
                progress: AlwaysStoppedAnimation<double>(t),
                checked: checked,
                circleStrokeColor: const Color(0xFF007AFF), // iOSブルー
                circleFillColor: const Color(0xFFEAF2FF),   // 淡いブルー
                checkColor: const Color(0xFF007AFF),        // 青のチェック
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 黒い丸と白いチェック（斜め線）を描画。progressで線の長さを制御。
class _CheckPainter extends CustomPainter {
  final Animation<double> progress; // 0..1
  final bool checked;
  final Color circleStrokeColor;
  final Color circleFillColor;
  final Color checkColor;

  _CheckPainter({
    required this.progress,
    required this.checked,
    required this.circleStrokeColor,
    required this.circleFillColor,
    required this.checkColor,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = s / 2;

    final Paint circleStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = circleStrokeColor;

    final Paint circleFill = Paint()
      ..style = PaintingStyle.fill
      ..color = circleFillColor;

    // 背景の丸
    if (checked) {
      // チェック時: 淡いブルーで塗り + 青枠
      canvas.drawCircle(c, r, circleFill);
      canvas.drawCircle(c, r - 1, circleStroke);
    } else {
      // 未チェック: 青の輪郭のみ
      canvas.drawCircle(c, r - 1, circleStroke);
    }

    // チェック（白の斜め線）を段階的に描画
    final double t = progress.value; // 0..1
    if (t <= 0) return;

    final Paint checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.4
      ..color = checkColor;

    // ✓ の3点（サイズに対する比率で決める）
    final Offset p0 = Offset(size.width * 0.28, size.height * 0.52);
    final Offset p1 = Offset(size.width * 0.44, size.height * 0.70);
    final Offset p2 = Offset(size.width * 0.76, size.height * 0.36);

    // 2セグメントを進捗で描き分け
    const double split = 0.45; // 前半: p0->p1, 後半: p1->p2
    if (t <= split) {
      final double k = t / split;
      final Offset mid = Offset(
        p0.dx + (p1.dx - p0.dx) * k,
        p0.dy + (p1.dy - p0.dy) * k,
      );
      canvas.drawLine(p0, mid, checkPaint);
    } else {
      // 前半を全部 + 後半の一部
      canvas.drawLine(p0, p1, checkPaint);
      final double k = (t - split) / (1 - split);
      final Offset mid = Offset(
        p1.dx + (p2.dx - p1.dx) * k,
        p1.dy + (p2.dy - p1.dy) * k,
      );
      canvas.drawLine(p1, mid, checkPaint);
    }

    // 終盤の「はじけ」演出（0.85〜1.0）
    if (checked && t > 0.85) {
      final double bt = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
      final int sparks = 8;
      final double baseR = r * (0.55 + 0.35 * bt); // 外へ拡散
      final double dotRadius = (1.6 * (1.0 - bt)).clamp(0.6, 1.6);
      final Paint sparkPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = checkColor.withOpacity(0.9 * (1.0 - bt));
      for (int i = 0; i < sparks; i++) {
        final double ang = (2 * math.pi / sparks) * i;
        final Offset p = Offset(math.cos(ang), math.sin(ang)) * baseR + c;
        canvas.drawCircle(p, dotRadius, sparkPaint);
      }
      // 薄いリングも拡がる
      final Paint ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = checkColor.withOpacity(0.2 * (1.0 - bt));
      canvas.drawCircle(c, r * (1.0 + 0.4 * bt), ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    return oldDelegate.checked != checked ||
        oldDelegate.progress != progress ||
        oldDelegate.circleStrokeColor != circleStrokeColor ||
        oldDelegate.circleFillColor != circleFillColor ||
        oldDelegate.checkColor != checkColor;
  }
}

/// タブの中身（ListView + コントローラ維持）
class _TabList extends StatelessWidget {
  final List<AppleTodoItem> items;
  final ScrollController controller;
  final Widget Function(AppleTodoItem) itemBuilder;
  const _TabList({super.key, required this.items, required this.controller, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyView();
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => itemBuilder(items[i]),
    );
  }
}

/// 新規/初回の疑似挿入アニメ（Size + Fade）
class _InsertedWrapper extends StatefulWidget {
  final bool inserted;
  final Widget child;
  const _InsertedWrapper({super.key, required this.inserted, required this.child});

  @override
  State<_InsertedWrapper> createState() => _InsertedWrapperState();
}

class _InsertedWrapperState extends State<_InsertedWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctl;
  late Animation<double> _size;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: _TodoAppleModernPageState.kInsertDuration);
    _size = CurvedAnimation(parent: _ctl, curve: _TodoAppleModernPageState.kCurve);
    _fade = CurvedAnimation(parent: _ctl, curve: _TodoAppleModernPageState.kCurve);
    if (widget.inserted && !_TodoAppleModernPageState.reduceMotion) {
      _ctl.forward();
    } else {
      _ctl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _InsertedWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inserted && !_TodoAppleModernPageState.reduceMotion) {
      _ctl
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _size,
      axisAlignment: -1.0,
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}

/// FABの影を少し強調（押下時）
class _AnimatedFab extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool pressed;
  const _AnimatedFab({required this.onPressed, required this.pressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _TodoAppleModernPageState.kAnimFast,
      curve: _TodoAppleModernPageState.kCurve,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(pressed ? 0.24 : 0.16),
            blurRadius: pressed ? 18 : 12,
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(CupertinoIcons.square_list, color: Colors.black26, size: 48),
          SizedBox(height: 8),
          Text(
            'タスクはありません',
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
