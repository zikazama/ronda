import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Radar sebagai tanda RONDA sedang berjaga. Menyapu hanya saat [active];
/// bila tidak aktif (atau pengguna meminta animasi dikurangi) tampil diam.
class RadarView extends StatefulWidget {
  const RadarView({
    super.key,
    this.size = 200,
    this.color = AppColors.safeOnNight,
    this.active = true,
  });

  final double size;
  final Color color;
  final bool active;

  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  bool _shouldAnimate(BuildContext context) =>
      widget.active && !MediaQuery.disableAnimationsOf(context);

  void _sync(BuildContext context) {
    if (_shouldAnimate(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(context);
  }

  @override
  void didUpdateWidget(RadarView old) {
    super.didUpdateWidget(old);
    _sync(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => CustomPaint(
              painter: _RadarPainter(
                // Posisi diam yang enak dilihat saat tidak menyapu.
                widget.active ? _controller.value : 0.12,
                widget.color,
                widget.active,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.progress, this.color, this.active);

  final double progress;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: active ? 0.32 : 0.2);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, ring);
    }
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      ring,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      ring,
    );

    if (!active) {
      canvas.drawCircle(
        center,
        4,
        Paint()..color = color.withValues(alpha: 0.5),
      );
      return;
    }

    // Sapuan radar.
    final angle = progress * 2 * math.pi;
    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: math.pi / 2,
      colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.4)],
      transform: GradientRotation(angle - math.pi / 2),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = sweep.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * radius,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress || old.color != color || old.active != active;
}
