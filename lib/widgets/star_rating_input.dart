import 'package:flutter/material.dart';

class StarRatingInput extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final Color? color;

  const StarRatingInput({
    super.key,
    this.rating = 3,
    required this.onRatingChanged,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Theme.of(context).colorScheme.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () {
            onRatingChanged(index + 1);
          },
          icon: Icon(
            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: starColor,
          ),
          splashRadius: size / 2,
        );
      }),
    );
  }
}