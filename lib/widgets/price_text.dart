import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

class PriceText extends StatelessWidget {
  final double price;
  final double? mrp;
  final double fontSize;
  final bool showDiscount;

  const PriceText({
    super.key,
    required this.price,
    this.mrp,
    this.fontSize = 15,
    this.showDiscount = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = mrp != null && mrp! > price;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Formatters.currency(price),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
            color: AppColors.textPrimary,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 6),
          Text(
            Formatters.currency(mrp!),
            style: TextStyle(
              fontSize: fontSize - 2,
              color: AppColors.textHint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          if (showDiscount) ...[
            const SizedBox(width: 6),
            Text(
              Formatters.discountPercent(mrp!, price),
              style: TextStyle(
                fontSize: fontSize - 3,
                color: AppColors.discount,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
