import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedWave extends StatefulWidget {
  final double height;
  final double speed;
  final double offset;
  final double opacity;
  final List<Color>? gradientColors;

  const AnimatedWave({
    super.key,
    required this.height,
    required this.speed,
    this.offset = 0.0,
    this.opacity = 1.0,
    this.gradientColors,
  });

  @override
  State<AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<AnimatedWave> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: _OceanWavePainter(
              progress: _curve.value,
              speed: widget.speed,
              offset: widget.offset,
              opacity: widget.opacity,
              gradientColors: widget.gradientColors ??
                  [
                    Colors.white.withOpacity(widget.opacity * 0.9),
                    Colors.white.withOpacity(widget.opacity * 0.6),
                    Colors.white.withOpacity(widget.opacity * 0.3),
                  ],
            ),
          ),
        );
      },
    );
  }
}

class _OceanWavePainter extends CustomPainter {
  final double progress;
  final double speed;
  final double offset;
  final double opacity;
  final List<Color> gradientColors;

  _OceanWavePainter({
    required this.progress,
    required this.speed,
    required this.offset,
    required this.opacity,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseHeight = size.height * 0.65;
    final amplitude = size.height * 0.35;
    final resolution = 160;
    final path = _buildWavePath(
      size: size,
      baseHeight: baseHeight,
      amplitude: amplitude,
      phase: progress * speed * math.pi * 2 + offset,
      resolution: resolution,
      turbulence: 0.5,
    );
    final highlightPath = _buildWavePath(
      size: size,
      baseHeight: baseHeight - amplitude * 0.06,
      amplitude: amplitude * 0.7,
      phase: progress * speed * math.pi * 2 + offset * 1.1 + math.pi / 3,
      resolution: resolution,
      turbulence: 0.8,
    );

    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: gradientColors,
    );

    final basePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(opacity * 0.45),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..isAntiAlias = true;

    canvas.drawPath(path, basePaint);
    canvas.drawPath(highlightPath, shimmerPaint);
  }

  Path _buildWavePath({
    required Size size,
    required double baseHeight,
    required double amplitude,
    required double phase,
    required int resolution,
    required double turbulence,
  }) {
    final points = <Offset>[];
    for (int i = 0; i <= resolution; i++) {
      final progress = i / resolution;
      final x = progress * size.width;
      final wave1 = math.sin((progress * math.pi * 2 * 1.2) + phase);
      final wave2 = math.sin((progress * math.pi * 2 * 0.7) + phase * 0.6);
      final wave3 = math.cos((progress * math.pi * 2 * 0.4) + phase * 0.3);
      final y = baseHeight +
          wave1 * amplitude * 0.55 +
          wave2 * amplitude * 0.3 +
          wave3 * amplitude * 0.15 * turbulence;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(0, size.height);
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

      final control1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final control2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, p2.dx, p2.dy);
    }

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _OceanWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.speed != speed ||
        oldDelegate.offset != offset ||
        oldDelegate.gradientColors != gradientColors;
  }
}