import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  late final Ticker _ticker;

  double _loopT = 0.0;
  double _globalTime = 0.0;
  Duration? _lastTick;

  double? _pointerXNorm;
  double _pointerStrength = 0.0;
  final List<_Ripple> _ripples = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;

    final dt = (elapsed - last).inMicroseconds / 1e6;
    _globalTime += dt;

    final speed = widget.speed.clamp(0.3, 6.0);
    final loopDurationSec = (12.0 / speed).clamp(6.0, 18.0);
    _loopT = (_loopT + dt / loopDurationSec) % 1.0;

    final decay = math.pow(0.92, dt * 60.0) as double;
    _pointerStrength *= decay;

    _ripples.removeWhere((r) => (_globalTime - r.startTime) > r.life);

    if (mounted) setState(() {});
  }

  void _addRipple(double xNorm) {
    _ripples.add(
      _Ripple(
        xNorm: xNorm,
        startTime: _globalTime,
        life: 4.0,
        speed: 0.22,
        wavelength: 0.22,
        decay: 0.9,
        amplitude: 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;

        return MouseRegion(
          onHover: (e) {
            _pointerXNorm = (e.localPosition.dx / width).clamp(0.0, 1.0);
            _pointerStrength = (_pointerStrength * 0.7) + 0.3;
          },
          onExit: (_) => _pointerXNorm = null,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (d) {
              final x = (d.localPosition.dx / width).clamp(0.0, 1.0);
              _addRipple(x);
            },
            onPanUpdate: (d) {
              _pointerXNorm = (d.localPosition.dx / width).clamp(0.0, 1.0);
              final boost = (d.delta.distance * 0.03).clamp(0.0, 1.0);
              _pointerStrength = (_pointerStrength * 0.6) + 0.4 * boost;
            },
            onPanEnd: (_) => _pointerStrength *= 0.8,
            child: RepaintBoundary(
              child: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: CustomPaint(
                  painter: _OceanWavePainter(
                    t: _loopT,
                    globalTime: _globalTime,
                    speed: widget.speed,
                    offset: widget.offset,
                    opacity: widget.opacity,
                    gradientColors: widget.gradientColors ??
                        [
                          Colors.white.withOpacity(widget.opacity * 0.9),
                          Colors.white.withOpacity(widget.opacity * 0.6),
                          Colors.white.withOpacity(widget.opacity * 0.3),
                        ],
                    pointerXNorm: _pointerXNorm,
                    pointerStrength: _pointerStrength,
                    ripples: _ripples,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Ripple {
  final double xNorm;
  final double startTime;
  final double life;
  final double speed;
  final double wavelength;
  final double decay;
  final double amplitude;

  _Ripple({
    required this.xNorm,
    required this.startTime,
    required this.life,
    required this.speed,
    required this.wavelength,
    required this.decay,
    required this.amplitude,
  });
}

class _OceanWavePainter extends CustomPainter {
  final double t;
  final double globalTime;
  final double speed;
  final double offset;
  final double opacity;
  final List<Color> gradientColors;

  final double? pointerXNorm;
  final double pointerStrength;
  final List<_Ripple> ripples;

  _OceanWavePainter({
    required this.t,
    required this.globalTime,
    required this.speed,
    required this.offset,
    required this.opacity,
    required this.gradientColors,
    required this.pointerXNorm,
    required this.pointerStrength,
    required this.ripples,
  });

  double _gauss(double x, double sigma) => math.exp(-(x * x) / (2.0 * sigma * sigma));

  @override
  void paint(Canvas canvas, Size size) {
    final int resolution = (size.width / 8).clamp(100, 280).toInt();

    final double baseHeight = size.height * 0.64;
    final double amplitude = size.height * 0.36;

    final double breathe = 1.0 + 0.08 * math.sin(2 * math.pi * t);

    const int cyclesMain = 2;
    final double phase1 = 2 * math.pi * cyclesMain * t + offset;
    final double phase2 = 2 * math.pi * (cyclesMain * 2) * t + offset * 0.7 + math.pi / 3;
    final double phase3 = 2 * math.pi * (cyclesMain * 3) * t + offset * 1.1 + math.pi / 5;

    final double? cursorX = pointerXNorm;
    final double cursorSigma = 0.12;

    final List<Offset> points = <Offset>[];
    final List<Offset> highlightPoints = <Offset>[];

    for (int i = 0; i <= resolution; i++) {
      final double p = i / resolution;
      final double x = p * size.width;

      final double w1 = math.sin((p * 2 * math.pi * 1.2) + phase1);
      final double w2 = math.sin((p * 2 * math.pi * 0.7) + phase2);
      final double w3 = math.cos((p * 2 * math.pi * 0.4) + phase3);

      double localBoost = 1.0;
      if (cursorX != null && pointerStrength > 0.001) {
        final dx = (p - cursorX);
        final influence = _gauss(dx, cursorSigma) * pointerStrength;
        localBoost += 0.28 * influence;
      }

      double rippleDisp = 0.0;
      for (final r in ripples) {
        final dt = (globalTime - r.startTime).clamp(0.0, r.life);
        final cx = r.xNorm + r.speed * dt;
        if (cx < -0.2 || cx > 1.2) continue;

        final u = p - cx;
        final envelope = _gauss(u, 0.12) * math.pow(r.decay, dt);
        final ripplePhase = 2 * math.pi * (u / r.wavelength - dt / r.wavelength);
        rippleDisp += (amplitude * 0.35) * r.amplitude * envelope * math.sin(ripplePhase);
      }

      final double yBase = baseHeight +
          amplitude * breathe * localBoost * (w1 * 0.55 + w2 * 0.30 + w3 * 0.15) +
          rippleDisp;

      points.add(Offset(x, yBase));

      final double yHi = (baseHeight - amplitude * 0.06) +
          amplitude * 0.72 * (w1 * 0.55 + w2 * 0.30 + w3 * 0.15) +
          rippleDisp * 0.7;

      highlightPoints.add(Offset(x, yHi));
    }

    final Path fillPath = _catmullRomToCubicPath(points, closeToBottom: true, size: size);
    final Path crestPath = _catmullRomToCubicPath(highlightPoints, closeToBottom: false, size: size);

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

    final foamPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    canvas.drawPath(fillPath, basePaint);
    canvas.drawPath(_clipToTop(fillPath, crestPath), shimmerPaint);
    canvas.drawPath(crestPath, foamPaint);
  }

  Path _catmullRomToCubicPath(List<Offset> pts, {required bool closeToBottom, required Size size}) {
    final path = Path();
    if (pts.isEmpty) return path;

    if (closeToBottom) {
      path.moveTo(0, size.height);
      path.lineTo(pts.first.dx, pts.first.dy);
    } else {
      path.moveTo(pts.first.dx, pts.first.dy);
    }

    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : pts[i + 1];

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

    if (closeToBottom) {
      path.lineTo(size.width, size.height);
      path.close();
    }
    return path;
  }

  Path _clipToTop(Path base, Path crest) {
    final Path result = Path()..addPath(crest, Offset.zero);
    return Path.combine(PathOperation.intersect, result, base);
  }

  @override
  bool shouldRepaint(covariant _OceanWavePainter old) {
    return old.t != t ||
        old.globalTime != globalTime ||
        old.opacity != opacity ||
        old.speed != speed ||
        old.offset != offset ||
        old.pointerXNorm != pointerXNorm ||
        old.pointerStrength != pointerStrength ||
        old.gradientColors != gradientColors ||
        old.ripples.length != ripples.length;
  }
}
