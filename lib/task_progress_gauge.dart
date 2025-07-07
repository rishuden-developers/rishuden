// lib/task_progress_gauge.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class TaskProgressGauge extends StatefulWidget {
  final int defeatedCount;
  final int totalParticipants;

  const TaskProgressGauge({
    super.key,
    required this.defeatedCount,
    required this.totalParticipants,
  });

  @override
  State<TaskProgressGauge> createState() => _TaskProgressGaugeState();
}

class _TaskProgressGaugeState extends State<TaskProgressGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    double initialProgress =
        widget.totalParticipants > 0
            ? widget.defeatedCount / widget.totalParticipants
            : 0.0;

    _animation = Tween<double>(
      begin: initialProgress,
      end: initialProgress,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // 最初の描画のために一度だけ実行
    if (widget.totalParticipants > 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(TaskProgressGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defeatedCount != widget.defeatedCount ||
        oldWidget.totalParticipants != widget.totalParticipants) {
      double oldProgress =
          oldWidget.totalParticipants > 0
              ? oldWidget.defeatedCount / oldWidget.totalParticipants
              : 0.0;
      double newProgress =
          widget.totalParticipants > 0
              ? widget.defeatedCount / widget.totalParticipants
              : 0.0;

      _animation = Tween<double>(begin: oldProgress, end: newProgress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );

      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _TaskProgressPainter(
            progress: _animation.value,
            defeatedCount: widget.defeatedCount,
            totalParticipants: widget.totalParticipants,
          ),
        );
      },
    );
  }
}

class _TaskProgressPainter extends CustomPainter {
  final double progress;
  final int defeatedCount;
  final int totalParticipants;

  _TaskProgressPainter({
    required this.progress,
    required this.defeatedCount,
    required this.totalParticipants,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint =
        Paint()..color = Colors.black.withOpacity(0.4);
    final Paint borderPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    final Paint progressPaint =
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [
            Colors.cyanAccent.withOpacity(0.8),
            Colors.limeAccent.withOpacity(0.8),
          ]);

    final Paint glowPaint =
        Paint()
          ..color = Colors.cyan.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final RRect backgroundRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );

    canvas.drawRRect(backgroundRRect, backgroundPaint);

    if (progress > 0) {
      final RRect progressRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * progress.clamp(0.0, 1.0), size.height),
        Radius.circular(size.height / 2),
      );
      canvas.drawRRect(progressRRect, glowPaint);
      canvas.drawRRect(progressRRect, progressPaint);
    }

    canvas.drawRRect(backgroundRRect, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$defeatedCount / $totalParticipants',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size.height * 0.6,
          fontFamily: 'NotoSansJP',
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _TaskProgressPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
