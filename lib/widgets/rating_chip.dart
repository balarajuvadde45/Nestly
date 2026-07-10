import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

class RatingChip extends StatelessWidget {
  final double rating;
  final int? count;
  final bool compact;

  const RatingChip({
    super.key,
    required this.rating,
    this.count,
    this.compact = false,
  });

  Color get _bg {
    if (rating >= 4.0) return AppColors.success;
    if (rating >= 3.0) return const Color(0xFF558B2F);
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 5 : 6,
            vertical: compact ? 2 : 3,
          ),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Formatters.rating(rating),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.star_rounded,
                  color: Colors.white, size: compact ? 11 : 13),
            ],
          ),
        ),
        if (count != null && !compact) ...[
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
