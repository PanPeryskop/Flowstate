import 'package:flutter/material.dart';
import 'package:flowstate/models/brewing.dart';
import 'package:flowstate/theme/flowstate_theme.dart';

class BrewingStatsChart extends StatelessWidget {
  final List<Brewing> brewings;
  final String title;
  final String xAxisLabel;
  final String yAxisLabel;
  final double Function(Brewing) getValue;
  final String Function(Brewing) getLabel;
  final bool autoScale;

  const BrewingStatsChart({
    super.key,
    required this.brewings,
    required this.title,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.getValue,
    required this.getLabel,
    this.autoScale = true,
  });

  @override
  Widget build(BuildContext context) {
    if (brewings.isEmpty) {
      return const Center(child: Text('Not enough data to display chart'));
    }

    final sortedBrewings = [...brewings]
      ..sort((a, b) => a.brewDate.compareTo(b.brewDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        AspectRatio(
          aspectRatio: 1.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth;
                final chartHeight = constraints.maxHeight * 0.8;
                final footerHeight = constraints.maxHeight * 0.2;

                double minValue = double.infinity;
                double maxValue = double.negativeInfinity;

                for (final brewing in sortedBrewings) {
                  final value = getValue(brewing);
                  if (value < minValue) minValue = value;
                  if (value > maxValue) maxValue = value;
                }

                if (autoScale) {
                  final range = maxValue - minValue;
                  final padding = range * 0.15;
                  minValue = (minValue - padding).clamp(0, double.infinity);
                  maxValue = maxValue + padding;
                } else {
                  minValue = 0;
                  maxValue = maxValue * 1.1;
                }

                final valueRange = maxValue - minValue;

                final points = <Offset>[];
                final labels = <String>[];
                final ratingColors = <Color>[];

                final itemWidth = sortedBrewings.length > 1
                    ? chartWidth / (sortedBrewings.length - 1)
                    : chartWidth / 2;

                for (int i = 0; i < sortedBrewings.length; i++) {
                  final brewing = sortedBrewings[i];
                  final x = sortedBrewings.length > 1
                      ? i * itemWidth
                      : chartWidth / 2;
                  final normalizedValue =
                      (getValue(brewing) - minValue) / valueRange;
                  final y = chartHeight * (1 - normalizedValue);

                  points.add(Offset(x, y));
                  labels.add(getLabel(brewing));

                  final ratingColor = _getRatingColor(brewing.rating);
                  ratingColors.add(ratingColor);
                }

                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: chartHeight / 2,
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: Text(
                          yAxisLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),

                    Positioned(
                      left: 20,
                      right: 0,
                      top: 0,
                      height: chartHeight,
                      child: CustomPaint(
                        painter: _ChartPainter(
                          points: points,
                          ratingColors: ratingColors,
                          minValue: minValue,
                          maxValue: maxValue,
                        ),
                      ),
                    ),

                    Positioned(
                      left: 20,
                      right: 0,
                      top: chartHeight,
                      height: footerHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (
                            int i = 0;
                            i < labels.length;
                            i += (labels.length / 5).ceil().clamp(
                              1,
                              labels.length,
                            )
                          )
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                labels[i],
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return FlowstateTheme.secondaryColor;
      default:
        return Colors.grey;
    }
  }
}

class _ChartPainter extends CustomPainter {
  final List<Offset> points;
  final List<Color> ratingColors;
  final double minValue;
  final double maxValue;

  _ChartPainter({
    required this.points,
    required this.ratingColors,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      final value = maxValue - ((maxValue - minValue) * i / gridLines);
      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width - 4, y - textPainter.height / 2),
      );
    }

    final linePaint = Paint()
      ..color = FlowstateTheme.primaryColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final prevPoint = points[i - 1];
        final currentPoint = points[i];

        final controlPoint1 = Offset(
          prevPoint.dx + (currentPoint.dx - prevPoint.dx) / 2,
          prevPoint.dy,
        );

        final controlPoint2 = Offset(
          prevPoint.dx + (currentPoint.dx - prevPoint.dx) / 2,
          currentPoint.dy,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }

      canvas.drawPath(path, linePaint);
    }

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final dotPaint = Paint()
        ..color = ratingColors[i]
        ..style = PaintingStyle.fill;

      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.ratingColors != ratingColors ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue;
  }
}
