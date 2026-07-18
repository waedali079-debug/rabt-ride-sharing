import 'package:flutter/material.dart';
import '../../../core/constants/design_constants.dart';

class RatingWidget extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double>? onRatingChanged;

  const RatingWidget({
    super.key,
    this.initialRating = 0,
    this.onRatingChanged,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= _rating;
            final isHalf = !isFilled && (starIndex - 0.5) <= _rating;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = starIndex.toDouble();
                });
                widget.onRatingChanged?.call(_rating);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isFilled ? Icons.star : (isHalf ? Icons.star_half : Icons.star_border),
                  size: 40,
                  color: isFilled || isHalf
                      ? const Color(RabtDesignConstants.warningLight)
                      : theme.colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: RabtDesignConstants.spaceSm),
        Text(
          _rating == 0 ? 'اضغط للتقييم' : _getRatingText(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _getRatingText() {
    if (_rating <= 1) return 'سيء جداً';
    if (_rating <= 2) return 'سيء';
    if (_rating <= 3) return 'مقبول';
    if (_rating <= 4) return 'جيد';
    return 'ممتاز';
  }
}
